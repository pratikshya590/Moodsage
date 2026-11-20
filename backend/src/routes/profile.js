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

// PUT /api/profile → update name and/or photo
router.put('/', async (req, res) => {
  const { name, photoUrl } = req.body;
  const update = {};

  // Name: 1 to 40 characters
  if (name !== undefined) {
    if (typeof name !== 'string' || name.trim().length === 0 || name.trim().length > 40) {
      return res.status(400).json({ error: 'Name must be 1 to 40 characters' });
    }
    update.name = name.trim();
  }

  // Photo: a small image sent as text (base64), or null to remove it
  if (photoUrl !== undefined) {
    const validImage =
      photoUrl === null ||
      (typeof photoUrl === 'string' &&
        /^data:image\/(png|jpe?g|webp|gif);base64,/.test(photoUrl) &&
        photoUrl.length <= 1000000);
    if (!validImage) {
      return res.status(400).json({ error: 'Photo is invalid or too large' });
    }
    update.photoUrl = photoUrl;
  }

  if (Object.keys(update).length === 0) {
    return res.status(400).json({ error: 'Nothing to update' });
  }

  try {
    update.updatedAt = FieldValue.serverTimestamp();
    const ref = db.collection('users').doc(req.user.uid);
    await ref.set(update, { merge: true });

    const saved = await ref.get();
    res.json(toProfile(req.user.uid, saved.data()));
  } catch (err) {
    console.error('Update profile error:', err);
    res.status(500).json({ error: 'Could not save profile' });
  }
});

module.exports = router;