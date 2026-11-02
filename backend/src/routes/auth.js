const router = require('express').Router();
const jwt = require('jsonwebtoken');
const User = require('../models/User');

const validPhone = (p) => /^[6-9]\d{9}$/.test(p || '');

router.post('/send-otp', async (req, res, next) => {
  try {
    const { phone } = req.body;
    if (!validPhone(phone)) return res.status(400).json({ message: 'Enter a valid 10-digit mobile number' });
    const otp = String(Math.floor(100000 + Math.random() * 900000));
    await User.findOneAndUpdate(
      { phone },
      { otp, otpExpiry: new Date(Date.now() + 5 * 60 * 1000) },
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );
    // Integrate an SMS provider (Twilio/MSG91) here for production
    console.log(`OTP for ${phone}: ${otp}`);
    res.json({ message: 'OTP sent', ...(process.env.EXPOSE_OTP === 'true' && { devOtp: otp }) });
  } catch (e) { next(e); }
});

router.post('/verify-otp', async (req, res, next) => {
  try {
    const { phone, otp } = req.body;
    const user = await User.findOne({ phone });
    if (!user || !user.otp || user.otp !== String(otp) || user.otpExpiry < new Date())
      return res.status(400).json({ message: 'Invalid or expired OTP' });
    user.otp = undefined; user.otpExpiry = undefined;
    await user.save();
    const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET, { expiresIn: '90d' });
    res.json({ token, user });
  } catch (e) { next(e); }
});

module.exports = router;
