const mongoose = require('mongoose');
const STATUSES = ['Submitted', 'Under Review', 'Approved', 'Rejected', 'Disbursed'];
const loanSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  amount: { type: Number, required: true },
  tenureMonths: { type: Number, required: true },
  interestRate: { type: Number, default: 12 },
  emi: Number,
  totalPayable: Number,
  purpose: String,
  status: { type: String, enum: STATUSES, default: 'Submitted' },
  decision: { type: String, enum: ['Approved', 'Rejected'] },
  rejectionReason: String,
  history: [{ status: String, at: { type: Date, default: Date.now } }],
  manual: { type: Boolean, default: false },
  amountPaid: { type: Number, default: 0 },
  repayments: [{
    receiptId: { type: String, required: true },
    amount: { type: Number, required: true },
    paymentMode: { type: String, enum: ['MOCK'], default: 'MOCK' },
    paidAt: { type: Date, default: Date.now },
    balanceAfter: { type: Number, required: true },
  }],
}, { timestamps: true });
module.exports = mongoose.model('Loan', loanSchema);
module.exports.STATUSES = STATUSES;
