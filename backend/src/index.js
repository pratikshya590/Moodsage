require('dotenv').config();
const express = require('express');
const cors = require('cors');
const pool = require('./config/db');
const verifyToken = require('./middleware/auth');
const profileRoutes = require('./routes/profile');
const pinRoutes = require('./routes/pin');
const moodRoutes = require('./routes/moods');
const recoveryRoutes = require('./routes/recovery');
const pageRoutes = require('./routes/pages');

const app = express();
app.use(cors());
app.use(express.json({ limit: '2mb' }));

// Log every request so we can see what reaches the server
app.use((req, res, next) => {
  console.log(new Date().toLocaleTimeString(), req.method, req.url);
  next();
});

// Health check: is the server running and connected to MySQL?
app.get('/api/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ status: 'ok', database: 'mysql connected' });
  } catch (err) {
    res.status(500).json({ status: 'error', message: err.message });
  }
});

// Test protected route: only works with a valid login token
app.get('/api/me', verifyToken, (req, res) => {
  res.json({ uid: req.user.uid, email: req.user.email });
});

// Routes
app.use('/api/profile', profileRoutes);
app.use('/api/pin', pinRoutes);
app.use('/api/moods', moodRoutes);
app.use('/api/recovery', recoveryRoutes); // no login needed (forgot password / PIN)
app.use('/', pageRoutes);

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Moodsage backend running on http://localhost:${PORT}`);
});