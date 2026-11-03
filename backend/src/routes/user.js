const router = require('express').Router();
const auth = require('../middleware/auth');

router.get('/profile', auth, (req, res) => res.json({ user: req.user }));

router.put('/push-token', auth, async (req, res, next) => {
  try {
    const { token } = req.body;
    if (typeof token !== 'string' || token.length < 20 || token.length > 4096) {
      return res.status(400).json({ message: 'Invalid push notification token' });
    }
    await req.user.updateOne({ $addToSet: { pushTokens: token } });
    res.json({ message: 'Push token registered' });
  } catch (e) { next(e); }
});

router.delete('/push-token', auth, async (req, res, next) => {
  try {
    const { token } = req.body;
    if (typeof token !== 'string' || token.length < 20 || token.length > 4096) {
      return res.status(400).json({ message: 'Invalid push notification token' });
    }
    await req.user.updateOne({ $pull: { pushTokens: token } });
    res.json({ message: 'Push token removed' });
  } catch (e) { next(e); }
});

router.put('/profile', auth, async (req, res, next) => {
  try {
    const { name, dob, gender, pan, email, monthlyIncome, employmentType } = req.body;
    if (!name || !dob || !gender || !pan || !email)
      return res.status(400).json({ message: 'Name, DOB, gender, PAN and email are required' });
    if (!/^[A-Z]{5}[0-9]{4}[A-Z]$/.test(pan.toUpperCase()))
      return res.status(400).json({ message: 'Invalid PAN format' });
    if (!/^\S+@\S+\.\S+$/.test(email)) return res.status(400).json({ message: 'Invalid email' });
    Object.assign(req.user, {
      name, dob, gender, pan: pan.toUpperCase(), email,
      monthlyIncome: Number(monthlyIncome) || 0,
      employmentType: employmentType || 'Salaried',
      profileComplete: true,
    });
    await req.user.save();
    res.json({ user: req.user });
  } catch (e) { next(e); }
});

module.exports = router;
