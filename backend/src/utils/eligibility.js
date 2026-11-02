function calcEmi(amount, months, annualRate = 12) {
  const r = annualRate / 12 / 100;
  const emi = (amount * r * Math.pow(1 + r, months)) / (Math.pow(1 + r, months) - 1);
  return Math.round(emi);
}

function ageOf(dob) {
  return Math.floor((Date.now() - new Date(dob)) / (365.25 * 24 * 3600 * 1000));
}

// Basic eligibility rules
function checkEligibility(user, amount, months) {
  const reasons = [];
  if (!user.profileComplete) reasons.push('Complete your profile first');
  const age = user.dob ? ageOf(user.dob) : 0;
  if (age < 21 || age > 60) reasons.push('Age must be between 21 and 60');
  if (user.employmentType === 'Unemployed' || user.employmentType === 'Student')
    reasons.push('Employment type not eligible');
  if (user.monthlyIncome < 15000) reasons.push('Minimum monthly income is Rs 15,000');
  if (user.creditScore < 600) reasons.push('Credit score below 600');
  const emi = calcEmi(amount, months);
  if (user.monthlyIncome && emi > 0.5 * user.monthlyIncome)
    reasons.push('EMI exceeds 50% of monthly income');
  if (amount > user.monthlyIncome * 10) reasons.push('Amount exceeds 10x monthly income');
  return { eligible: reasons.length === 0, reasons, emi };
}
module.exports = { calcEmi, checkEligibility };
