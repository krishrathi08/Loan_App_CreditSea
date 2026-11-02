const router = require('express').Router();
const auth = require('../middleware/auth');
const Loan = require('../models/Loan');
const { STATUSES } = require('../models/Loan');
const { checkEligibility } = require('../utils/eligibility');

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
    res.json({ loan });
  } catch (e) { next(e); }
});

module.exports = router;
