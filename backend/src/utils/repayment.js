function calculateDemoRepayment(loan) {
  if (loan.status !== 'Disbursed') {
    throw new Error('Repayments are available after the loan is disbursed');
  }

  const totalPayable = Number(loan.totalPayable);
  const emi = Number(loan.emi);
  const amountPaid = Number(loan.amountPaid || 0);
  if (!Number.isFinite(totalPayable) || !Number.isFinite(emi) || emi <= 0 || amountPaid < 0) {
    throw new Error('Loan repayment details are invalid');
  }

  const remaining = Math.max(0, Math.round((totalPayable - amountPaid) * 100) / 100);
  if (remaining === 0) throw new Error('This loan is already fully repaid');

  const amount = Math.min(Math.round(emi * 100) / 100, remaining);
  return {
    amount,
    balanceAfter: Math.round((remaining - amount) * 100) / 100,
  };
}

function scoreAfterOnTimeDemoRepayment(currentScore) {
  const score = Number(currentScore);
  if (!Number.isInteger(score) || score < 300 || score > 900) {
    throw new Error('Credit score is invalid');
  }
  return Math.min(900, score + 5);
}

module.exports = { calculateDemoRepayment, scoreAfterOnTimeDemoRepayment };
