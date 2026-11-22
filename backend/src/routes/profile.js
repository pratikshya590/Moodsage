const express = require('express');
const pool = require('../config/db');
const verifyToken = require('../middleware/auth');

const router = express.Router();

// Every route in this file needs a logged-in user
router.use(verifyToken);

// Shape of the profile sent back to the app (never send secrets like the PIN)
function toProfile(row) {
  return {
    uid: row.uid,
    email: row.email,
    name: row.name ?? null,
    photoUrl: row.photo_url ?? null,
    hasPin: row.has_pin === 1 || row.has_pin === true,
  };
}

// Make sure the logged-in user has a row in the users table
async function ensureUser(uid, email) {
  await pool.query(
    'INSERT IGNORE INTO users (uid, email, created_at) VALUES (?, ?, ?)',
    [uid, email, new Date()]
  );
}

async function findUser(uid) {
  const [rows] = await pool.query('SELECT * FROM users WHERE uid = ?', [uid]);
  return rows[0];
}

// POST /api/profile → create the profile after sign up (safe to call twice)
router.post('/', async (req, res) => {
  try {
    await ensureUser(req.user.uid, req.user.email);
    const user = await findUser(req.user.uid);
    res.status(201).json(toProfile(user));
  } catch (err) {
    console.error('Create profile error:', err);
    res.status(500).json({ error: 'Could not create profile' });
  }
});

// GET /api/profile → get the logged-in user's profile
// (creates it if missing, e.g. an account made before the MySQL switch)
router.get('/', async (req, res) => {
  try {
    await ensureUser(req.user.uid, req.user.email);
    const user = await findUser(req.user.uid);
    res.json(toProfile(user));
  } catch (err) {
    console.error('Get profile error:', err);
    res.status(500).json({ error: 'Could not load profile' });
  }
});

// PUT /api/profile → update name and/or photo
router.put('/', async (req, res) => {
  const { name, photoUrl } = req.body;
  const fields = [];
  const values = [];

  // Name: 1 to 40 characters
  if (name !== undefined) {
    if (typeof name !== 'string' || name.trim().length === 0 || name.trim().length > 40) {
      return res.status(400).json({ error: 'Name must be 1 to 40 characters' });
    }
    fields.push('name = ?');
    values.push(name.trim());
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
    fields.push('photo_url = ?');
    values.push(photoUrl);
  }

  if (fields.length === 0) {
    return res.status(400).json({ error: 'Nothing to update' });
  }

  try {
    await ensureUser(req.user.uid, req.user.email);
    fields.push('updated_at = ?');
    values.push(new Date(), req.user.uid);

    await pool.query(`UPDATE users SET ${fields.join(', ')} WHERE uid = ?`, values);
    const user = await findUser(req.user.uid);
    res.json(toProfile(user));
  } catch (err) {
    console.error('Update profile error:', err);
    res.status(500).json({ error: 'Could not save profile' });
  }
});

module.exports = router;