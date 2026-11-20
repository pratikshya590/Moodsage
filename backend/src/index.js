require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { db } = require('./config/firebase');
const verifyToken = require('./middleware/auth');

const app = express();
app.use(cors());
app.use(express.json());

// Health check: is the server running and connected to Firestore?
app.get('/api/health', async (req, res) => {
  try {
    await db.collection('users').limit(1).get();
    res.json({ status: 'ok', firestore: 'connected' });
  } catch (err) {
    res.status(500).json({ status: 'error', message: err.message });
  }
});

// Test protected route: only works with a valid login token
app.get('/api/me', verifyToken, (req, res) => {
  res.json({ uid: req.user.uid, email: req.user.email });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Moodsage backend running on http://localhost:${PORT}`);
});