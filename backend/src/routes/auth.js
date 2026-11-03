const router = require('express').Router();
const jwt = require('jsonwebtoken');
const { randomInt } = require('node:crypto');
const { rateLimit } = require('express-rate-limit');
const User = require('../models/User');
const msg91 = require('../services/msg91');
const { hashPassword, isValidPassword, verifyPassword } = require('../utils/password');

const validPhone = (p) => /^[6-9]\d{9}$/.test(p || '');
const validOtp = (otp) => /^\d{6}$/.test(String(otp || ''));
const otpProvider = () => process.env.OTP_PROVIDER || 'mock';
const authRateLimit = (limit) => rateLimit({
  windowMs: 15 * 60 * 1000,
  limit,
  standardHeaders: 'draft-8',
  legacyHeaders: false,
  message: { message: 'Too many attempts. Try again in 15 minutes.' },
});
const sendOtpLimit = authRateLimit(5);
const verifyOtpLimit = authRateLimit(10);
const passwordLoginLimit = authRateLimit(10);
const passwordSetupLimit = authRateLimit(5);

function publicUser(user) {
  const result = user.toObject();
  delete result.passwordHash;
  delete result.otp;
  delete result.otpExpiry;
  return result;
}

function issueSession(user) {
  const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET, { expiresIn: '90d' });
  return { token, user: publicUser(user) };
}

router.post('/send-otp', sendOtpLimit, async (req, res, next) => {
  try {
    const { phone } = req.body;
    if (!validPhone(phone)) return res.status(400).json({ message: 'Enter a valid 10-digit mobile number' });
    const provider = otpProvider();
    if (!['mock', 'msg91'].includes(provider)) {
      return res.status(500).json({ message: 'OTP provider is not configured correctly' });
    }

    const user = await User.findOneAndUpdate(
      { phone },
      { $setOnInsert: { phone } },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );

    if (provider === 'msg91') {
      await msg91.sendOtp(phone);
      user.otp = undefined;
      user.otpExpiry = undefined;
      await user.save();
      return res.json({ message: 'OTP sent' });
    }

    const otp = String(randomInt(100000, 1000000));
    user.otp = otp;
    user.otpExpiry = new Date(Date.now() + 5 * 60 * 1000);
    await user.save();
    res.json({ message: 'OTP sent', ...(process.env.EXPOSE_OTP === 'true' && { devOtp: otp }) });
  } catch (e) { next(e); }
});

router.post('/verify-otp', verifyOtpLimit, async (req, res, next) => {
  try {
    const { phone, otp } = req.body;
    if (!validPhone(phone) || !validOtp(otp)) {
      return res.status(400).json({ message: 'Enter a valid mobile number and 6-digit OTP' });
    }
    const provider = otpProvider();
    const user = await User.findOne({ phone }).select('+passwordHash');
    if (!user) return res.status(400).json({ message: 'Invalid or expired OTP' });

    if (provider === 'msg91') {
      if (!await msg91.verifyOtp(phone, String(otp))) {
        return res.status(400).json({ message: 'Invalid or expired OTP' });
      }
    } else if (provider === 'mock') {
      if (!user.otp || user.otp !== String(otp) || !user.otpExpiry || user.otpExpiry < new Date()) {
        return res.status(400).json({ message: 'Invalid or expired OTP' });
      }
      user.otp = undefined;
      user.otpExpiry = undefined;
    } else {
      return res.status(500).json({ message: 'OTP provider is not configured correctly' });
    }

    await user.save();
    if (!user.passwordHash) {
      const setupToken = jwt.sign(
        { id: user._id, purpose: 'password_setup' },
        process.env.JWT_SECRET,
        { expiresIn: '10m' }
      );
      return res.json({ needsPasswordSetup: true, setupToken });
    }
    res.json(issueSession(user));
  } catch (e) { next(e); }
});

router.post('/login', passwordLoginLimit, async (req, res, next) => {
  try {
    const { phone, password } = req.body;
    if (!validPhone(phone) || typeof password !== 'string' || password.length > 128) {
      return res.status(400).json({ message: 'Enter a valid mobile number and password' });
    }

    const user = await User.findOne({ phone }).select('+passwordHash');
    if (!user || !await verifyPassword(password, user.passwordHash)) {
      return res.status(401).json({ message: 'Invalid mobile number or password' });
    }
    res.json(issueSession(user));
  } catch (e) { next(e); }
});

router.post('/set-password', passwordSetupLimit, async (req, res, next) => {
  try {
    const { setupToken, password } = req.body;
    if (typeof setupToken !== 'string' || !isValidPassword(password)) {
      return res.status(400).json({
        message: 'Password must be 8–128 characters and include at least one special character',
      });
    }

    let claims;
    try {
      claims = jwt.verify(setupToken, process.env.JWT_SECRET);
    } catch {
      return res.status(401).json({ message: 'Password setup session expired. Verify your phone again.' });
    }
    if (claims.purpose !== 'password_setup' || !claims.id) {
      return res.status(401).json({ message: 'Invalid password setup session' });
    }

    const user = await User.findById(claims.id).select('+passwordHash');
    if (!user) return res.status(401).json({ message: 'User not found' });
    if (user.passwordHash) {
      return res.status(409).json({ message: 'Password is already set. Sign in instead.' });
    }

    user.passwordHash = await hashPassword(password);
    await user.save();
    res.status(201).json(issueSession(user));
  } catch (e) { next(e); }
});

module.exports = router;
