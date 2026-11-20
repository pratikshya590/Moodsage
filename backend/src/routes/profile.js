const express = require('express');
const { FieldValue } = require('firebase-admin/firestore');
const { db } = require('../config/firebase');
const verifyToken = require('../middleware/auth');

const router = express.Router();

// Every route in this file needs a logged-in user
router.use(verifyToken);

// Shape of the profile sent back to the app (never send secrets like the PIN)
function toProfile(uid, data) {
  return {
    uid,
    email: data.email,
    name: data.name ?? null,
    photoUrl: data.photoUrl ?? null,
    hasPin: data.hasPin === true,
  };
}

// POST /api/profile → create the profile after sign up
// (safe to call twice: it won't overwrite an existing profile)
router.post('/', async (req, res) => {
  try {
    const ref = db.collection('users').doc(req.user.uid);
    const snap = await ref.get();

    if (!snap.exists) {
      await ref.set({
        email: req.user.email,
        name: null,
        photoUrl: null,
        hasPin: false,
        createdAt: FieldValue.serverTimestamp(),
      });
    }

    const saved = await ref.get();
    res.status(201).json(toProfile(req.user.uid, saved.data()));
  } catch (err) {
    console.error('Create profile error:', err);
    res.status(500).json({ error: 'Could not create profile' });
  }
});

// GET /api/profile → get the logged-in user's profile
router.get('/', async (req, res) => {
  try {
    const snap = await db.collection('users').doc(req.user.uid).get();

    if (!snap.exists) {
      return res.status(404).json({ error: 'Profile not found' });
    }

    res.json(toProfile(req.user.uid, snap.data()));
  } catch (err) {
    console.error('Get profile error:', err);
    res.status(500).json({ error: 'Could not load profile' });
  }
});

module.exports = router;