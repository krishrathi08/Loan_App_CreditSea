require('dotenv').config();
const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');

const app = express();
app.use(cors());
app.use(express.json());

app.get('/', (_, res) => res.json({ status: 'ok', service: 'CreditSea API' }));
app.use('/api/auth', require('./src/routes/auth'));
app.use('/api/user', require('./src/routes/user'));
app.use('/api/loans', require('./src/routes/loan'));

app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ message: err.message || 'Server error' });
});

const PORT = process.env.PORT || 5000;
mongoose
  .connect(process.env.MONGO_URI)
  .then(() => {
    console.log('MongoDB connected');
    app.listen(PORT, () => console.log(`Server on ${PORT}`));
  })
  .catch((e) => { console.error('DB error', e.message); process.exit(1); });
