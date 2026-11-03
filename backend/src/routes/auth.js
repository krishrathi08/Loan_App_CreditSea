const router = require('express').Router();
const jwt = require('jsonwebtoken');
const { randomInt } = require('node:crypto');
const { rateLimit } = require('express-rate-limit');
const User = require('../models/User');
const msg91 = require('../services/msg91');

const validPhone = (p) => /^[6-9]\d{9}$/.test(p || '');
const validOtp = (otp) => /^\d{6}$/.test(String(otp || ''));
const otpProvider = () => process.env.OTP_PROVIDER || 'mock';
const sendOtpLimit = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 5,
  standardHeaders: 'draft-8',
  legacyHeaders: false,
  message: { message: 'Too many OTP requests. Try again in 15 minutes.' },
});

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

router.post('/verify-otp', async (req, res, next) => {
  try {
    const { phone, otp } = req.body;
    if (!validPhone(phone) || !validOtp(otp)) {
      return res.status(400).json({ message: 'Enter a valid mobile number and 6-digit OTP' });
    }
    const provider = otpProvider();
    const user = await User.findOne({ phone });
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
    const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET, { expiresIn: '90d' });
    res.json({ token, user });
  } catch (e) { next(e); }
});

module.exports = router;
