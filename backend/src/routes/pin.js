const express = require('express');
const bcrypt = require('bcryptjs');
const { FieldValue } = require('firebase-admin/firestore');
const { db } = require('../config/firebase');
const verifyToken = require('../middleware/auth');

const router = express.Router();
router.use(verifyToken);

// A PIN must be exactly 4 digits
function isValidPin(pin) {
  return typeof pin === 'string' && /^\d{4}$/.test(pin);
}

// POST /api/pin → set or change the PIN (stored as a bcrypt hash)
router.post('/', async (req, res) => {
  const { pin } = req.body;
  if (!isValidPin(pin)) {
    return res.status(400).json({ error: 'PIN must be exactly 4 digits' });
  }

  try {
    const pinHash = await bcrypt.hash(pin, 10);
    await db.collection('users').doc(req.user.uid).set(
      {
        pinHash,
        hasPin: true,
        pinUpdatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
    res.json({ success: true });
  } catch (err) {
    console.error('Set PIN error:', err);
    res.status(500).json({ error: 'Could not save PIN' });
  }
});

// POST /api/pin/verify → check a PIN (used by App Lock)
router.post('/verify', async (req, res) => {
  const { pin } = req.body;
  if (!isValidPin(pin)) {
    return res.status(400).json({ error: 'PIN must be exactly 4 digits' });
  }

  try {
    const snap = await db.collection('users').doc(req.user.uid).get();
    const pinHash = snap.exists ? snap.data().pinHash : null;

    if (!pinHash) {
      return res.status(404).json({ error: 'No PIN set' });
    }

    const valid = await bcrypt.compare(pin, pinHash);
    res.json({ valid });
  } catch (err) {
    console.error('Verify PIN error:', err);
    res.status(500).json({ error: 'Could not check PIN' });
  }
});

module.exports = router;