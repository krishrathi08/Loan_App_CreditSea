const mongoose = require('mongoose');
const userSchema = new mongoose.Schema({
  phone: { type: String, required: true, unique: true },
  name: String,
  dob: Date,
  gender: { type: String, enum: ['Male', 'Female', 'Other'] },
  pan: String,
  email: String,
  monthlyIncome: { type: Number, default: 0 },
  employmentType: { type: String, enum: ['Salaried', 'Self-Employed', 'Student', 'Unemployed'], default: 'Salaried' },
  creditScore: { type: Number, default: 650 },
  creditScoreHistory: [{
    score: { type: Number, required: true },
    change: { type: Number, required: true },
    reason: { type: String, required: true },
    at: { type: Date, default: Date.now },
  }],
  profileComplete: { type: Boolean, default: false },
  passwordHash: { type: String, select: false },
  pushTokens: { type: [String], default: [] },
  otp: String,
  otpExpiry: Date,
}, { timestamps: true });
module.exports = mongoose.model('User', userSchema);
