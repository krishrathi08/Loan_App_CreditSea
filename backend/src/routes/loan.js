const router = require('express').Router();
const auth = require('../middleware/auth');
const Loan = require('../models/Loan');
const { STATUSES } = require('../models/Loan');
const User = require('../models/User');
const { checkEligibility } = require('../utils/eligibility');
const mongoose = require('mongoose');
const { randomUUID } = require('node:crypto');
const { calculateDemoRepayment, scoreAfterOnTimeDemoRepayment } = require('../utils/repayment');
const notifications = require('../services/notifications');

const RATE = 12;

// Status simulation: Submitted -> Under Review (30s) -> Approved/Rejected (90s) -> Disbursed (150s)
async function advance(loan) {
  if (loan.manual || ['Rejected', 'Disbursed'].includes(loan.status)) return loan;
  const s = (Date.now() - loan.createdAt) / 1000;
  let next = 'Submitted';
  if (s > 30) next = 'Under Review';
  if (s > 90) next = loan.decision;
  if (s > 150 && loan.decision === 'Approved') next = 'Disbursed';
  if (next !== loan.status) {
    const order = ['Submitted', 'Under Review', loan.decision, 'Disbursed'];
    for (const st of order.slice(order.indexOf(loan.status) + 1, order.indexOf(next) + 1))
      loan.history.push({ status: st });
    loan.status = next;
    await loan.save();
    void notifications.sendToUser(loan.user, {
      title: 'Loan application update',
      body: `Your application status is now ${next}.`,
      loanId: String(loan._id),
    }).catch((error) => console.error('Push notification failed:', error.message));
  }
  return loan;
}

router.post('/eligibility', auth, (req, res) => {
  const { amount, tenureMonths } = req.body;
  res.json(checkEligibility(req.user, Number(amount), Number(tenureMonths)));
});

router.post('/apply', auth, async (req, res, next) => {
  try {
    const amount = Number(req.body.amount), tenureMonths = Number(req.body.tenureMonths);
    if (!(amount >= 5000 && amount <= 500000)) return res.status(400).json({ message: 'Amount must be 5,000 - 5,00,000' });
    if (!(tenureMonths >= 3 && tenureMonths <= 36)) return res.status(400).json({ message: 'Tenure must be 3 - 36 months' });
    const { eligible, reasons, emi } = checkEligibility(req.user, amount, tenureMonths);
    const loan = await Loan.create({
      user: req.user._id, amount, tenureMonths, interestRate: RATE, emi,
      totalPayable: emi * tenureMonths, purpose: req.body.purpose,
      decision: eligible ? 'Approved' : 'Rejected',
      rejectionReason: eligible ? undefined : reasons.join('; '),
      history: [{ status: 'Submitted' }],
    });
    res.status(201).json({ loan });
  } catch (e) { next(e); }
});

router.get('/', auth, async (req, res, next) => {
  try {
    const loans = await Loan.find({ user: req.user._id }).sort({ createdAt: -1 });
    for (const l of loans) await advance(l);
    res.json({ loans });
  } catch (e) { next(e); }
});

router.get('/:id', auth, async (req, res, next) => {
  try {
    const loan = await Loan.findOne({ _id: req.params.id, user: req.user._id });
    if (!loan) return res.status(404).json({ message: 'Not found' });
    res.json({ loan: await advance(loan) });
  } catch (e) { next(e); }
});

router.post('/:id/repay', auth, async (req, res, next) => {
  let session;
  try {
    session = await mongoose.startSession();
    let result;
    await session.withTransaction(async () => {
      const loan = await Loan.findOne({ _id: req.params.id, user: req.user._id }).session(session);
      if (!loan) {
        const error = new Error('Loan not found');
        error.status = 404;
        throw error;
      }

      const repayment = calculateDemoRepayment(loan);
      const user = await User.findById(req.user._id).session(session);
      if (!user) {
        const error = new Error('User not found');
        error.status = 404;
        throw error;
      }

      const previousScore = Number(user.creditScore);
      const score = scoreAfterOnTimeDemoRepayment(previousScore);
      const paidAt = new Date();
      const receiptId = randomUUID();
      loan.amountPaid = Math.round(((loan.amountPaid || 0) + repayment.amount) * 100) / 100;
      loan.repayments.push({
        receiptId,
        amount: repayment.amount,
        paymentMode: 'MOCK',
        paidAt,
        balanceAfter: repayment.balanceAfter,
      });
      user.creditScore = score;
      user.creditScoreHistory.push({
        score,
        change: score - previousScore,
        reason: 'Successful demo loan repayment',
        at: paidAt,
      });

      await loan.save({ session });
      await user.save({ session });
      result = {
        loan,
        repayment: { receiptId, amount: repayment.amount, balanceAfter: repayment.balanceAfter },
        creditScore: user.creditScore,
      };
    });
    res.json({
      ...result,
      demo: true,
      message: 'Demo repayment recorded. No real money was charged.',
    });
  } catch (e) {
    if (e.message === 'Repayments are available after the loan is disbursed'
        || e.message === 'This loan is already fully repaid'
        || e.message === 'Loan repayment details are invalid') {
      return res.status(400).json({ message: e.message });
    }
    if (e.status) return res.status(e.status).json({ message: e.message });
    next(e);
  } finally {
    if (session) await session.endSession();
  }
});

// Admin: manually set status (header x-admin-key)
router.patch('/:id/status', async (req, res, next) => {
  try {
    if (req.headers['x-admin-key'] !== process.env.ADMIN_KEY) return res.status(403).json({ message: 'Forbidden' });
    if (!STATUSES.includes(req.body.status)) return res.status(400).json({ message: 'Bad status' });
    const loan = await Loan.findById(req.params.id);
    if (!loan) return res.status(404).json({ message: 'Not found' });
    loan.status = req.body.status; loan.manual = true;
    loan.history.push({ status: req.body.status });
    await loan.save();
    void notifications.sendToUser(loan.user, {
      title: 'Loan application update',
      body: `Your application status is now ${loan.status}.`,
      loanId: String(loan._id),
    }).catch((error) => console.error('Push notification failed:', error.message));
    res.json({ loan });
  } catch (e) { next(e); }
});

module.exports = router;
