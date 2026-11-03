const test = require('node:test');
const assert = require('node:assert/strict');
const {
  calculateDemoRepayment,
  scoreAfterOnTimeDemoRepayment,
} = require('../src/utils/repayment');

test('records one EMI against a disbursed loan and rounds the remaining balance', () => {
  assert.deepEqual(
    calculateDemoRepayment({
      status: 'Disbursed',
      totalPayable: 1000,
      emi: 333.335,
      amountPaid: 333.33,
    }),
    { amount: 333.34, balanceAfter: 333.33 },
  );
});

test('caps the final demo payment at the remaining amount', () => {
  assert.deepEqual(
    calculateDemoRepayment({
      status: 'Disbursed',
      totalPayable: 1000,
      emi: 400,
      amountPaid: 900,
    }),
    { amount: 100, balanceAfter: 0 },
  );
});

test('rejects repayment before disbursement and after full repayment', () => {
  assert.throws(
    () => calculateDemoRepayment({ status: 'Approved', totalPayable: 1000, emi: 100 }),
    /after the loan is disbursed/,
  );
  assert.throws(
    () => calculateDemoRepayment({ status: 'Disbursed', totalPayable: 1000, emi: 100, amountPaid: 1000 }),
    /already fully repaid/,
  );
});

test('increases the simulated score by five, capped at 900', () => {
  assert.equal(scoreAfterOnTimeDemoRepayment(650), 655);
  assert.equal(scoreAfterOnTimeDemoRepayment(899), 900);
});
