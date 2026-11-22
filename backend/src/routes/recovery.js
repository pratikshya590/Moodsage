const express = require('express');
const crypto = require('crypto');
const bcrypt = require('bcryptjs');
const pool = require('../config/db');
const { auth } = require('../config/firebase');
const mailer = require('../config/mailer');

const router = express.Router();
// No login token here: the user has forgotten their password or PIN.

const CODE_MINUTES = 10;   // the 6-digit code expires after 10 minutes
const TOKEN_MINUTES = 15;  // the reset token expires after 15 minutes
const MAX_ATTEMPTS = 5;    // wrong code attempts allowed
const RESEND_SECONDS = 60; // wait between code requests

const minutesFromNow = (m) => new Date(Date.now() + m * 60000);
const sha256 = (text) => crypto.createHash('sha256').update(text).digest('hex');
const isEmail = (e) => typeof e === 'string' && /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(e);

// Finds a valid, unused reset token (issued after a correct code)
async function findResetByToken(resetToken) {
  if (typeof resetToken !== 'string' || resetToken.length !== 64) return null;
  const [rows] = await pool.query(
    `SELECT * FROM password_resets
     WHERE reset_token_hash = ? AND used = FALSE AND token_expires_at > ?
     LIMIT 1`,
    [sha256(resetToken), new Date()]
  );
  return rows[0] || null;
}

// POST /api/recovery/send-code  { email }
// Emails a 6-digit code. Always gives the same reply, so nobody can
// find out which emails have accounts.
router.post('/send-code', async (req, res) => {
  const email = (req.body.email || '').trim().toLowerCase();
  if (!isEmail(email)) {
    return res.status(400).json({ error: 'Please enter a valid email address' });
  }

  const reply = { success: true, message: 'If an account exists, a code has been sent.' };

  try {
    // Is there a Firebase account with this email?
    let user;
    try {
      user = await auth.getUserByEmail(email);
    } catch {
      return res.json(reply); // no account: same reply, no email sent
    }

    // Rate limit: one code per minute
    const [recent] = await pool.query(
      'SELECT id FROM password_resets WHERE email = ? AND created_at > ? LIMIT 1',
      [email, new Date(Date.now() - RESEND_SECONDS * 1000)]
    );
    if (recent.length > 0) {
      return res.status(429).json({ error: 'Please wait a minute before requesting another code' });
    }

    // Cancel older codes, then create a new one
    await pool.query('UPDATE password_resets SET used = TRUE WHERE email = ? AND used = FALSE', [email]);

    const code = crypto.randomInt(0, 1000000).toString().padStart(6, '0');
    const codeHash = await bcrypt.hash(code, 10);

    await pool.query(
      `INSERT INTO password_resets (email, uid, code_hash, expires_at, created_at)
       VALUES (?, ?, ?, ?, ?)`,
      [email, user.uid, codeHash, minutesFromNow(CODE_MINUTES), new Date()]
    );

    await mailer.sendMail({
      from: `"Moodsage" <${process.env.EMAIL_USER}>`,
      to: email,
      subject: 'Your Moodsage verification code',
      text: `Your Moodsage code is ${code}. It expires in ${CODE_MINUTES} minutes. If you didn't request this, you can ignore this email.`,
      html: `
        <div style="font-family:Arial,sans-serif;max-width:420px;margin:auto;padding:24px;border:1px solid #A8D069;border-radius:16px">
          <h2 style="color:#3C4F19;margin-top:0">Moodsage</h2>
          <p>Use this code to reset your password or PIN:</p>
          <p style="font-size:32px;font-weight:bold;letter-spacing:8px;color:#647C3D;margin:16px 0">${code}</p>
          <p style="color:#555">This code expires in ${CODE_MINUTES} minutes.</p>
          <p style="color:#888;font-size:12px">If you didn't request this, you can safely ignore this email.</p>
        </div>`,
    });

    res.json(reply);
  } catch (err) {
    console.error('Send code error:', err);
    res.status(500).json({ error: 'Could not send the code. Please try again.' });
  }
});

// POST /api/recovery/verify-code  { email, code }
// Checks the code and returns a short-lived reset token.
router.post('/verify-code', async (req, res) => {
  const email = (req.body.email || '').trim().toLowerCase();
  const code = (req.body.code || '').toString().trim();

  if (!isEmail(email) || !/^\d{6}$/.test(code)) {
    return res.status(400).json({ error: 'Please enter the 6-digit code' });
  }

  try {
    const [rows] = await pool.query(
      `SELECT * FROM password_resets
       WHERE email = ? AND used = FALSE AND expires_at > ? AND reset_token_hash IS NULL
       ORDER BY created_at DESC LIMIT 1`,
      [email, new Date()]
    );
    const reset = rows[0];
    if (!reset) {
      return res.status(400).json({ error: 'This code has expired. Please request a new one.' });
    }

    if (reset.attempts >= MAX_ATTEMPTS) {
      await pool.query('UPDATE password_resets SET used = TRUE WHERE id = ?', [reset.id]);
      return res.status(400).json({ error: 'Too many attempts. Please request a new code.' });
    }

    const correct = await bcrypt.compare(code, reset.code_hash);
    if (!correct) {
      await pool.query('UPDATE password_resets SET attempts = attempts + 1 WHERE id = ?', [reset.id]);
      const left = MAX_ATTEMPTS - reset.attempts - 1;
      return res.status(400).json({
        error: left > 0 ? `Incorrect code. ${left} attempt(s) left.` : 'Too many attempts. Please request a new code.',
      });
    }

    // Correct: issue a reset token (only its hash is stored)
    const resetToken = crypto.randomBytes(32).toString('hex');
    await pool.query(
      'UPDATE password_resets SET reset_token_hash = ?, token_expires_at = ? WHERE id = ?',
      [sha256(resetToken), minutesFromNow(TOKEN_MINUTES), reset.id]
    );

    res.json({ success: true, resetToken });
  } catch (err) {
    console.error('Verify code error:', err);
    res.status(500).json({ error: 'Could not check the code. Please try again.' });
  }
});

// POST /api/recovery/reset-password  { resetToken, newPassword }
router.post('/reset-password', async (req, res) => {
  const { resetToken, newPassword } = req.body;
  if (typeof newPassword !== 'string' || newPassword.length < 6) {
    return res.status(400).json({ error: 'Password must be at least 6 characters' });
  }

  try {
    const reset = await findResetByToken(resetToken);
    if (!reset) {
      return res.status(400).json({ error: 'Your reset session has expired. Please start again.' });
    }

    await auth.updateUser(reset.uid, { password: newPassword });
    await pool.query('UPDATE password_resets SET used = TRUE WHERE id = ?', [reset.id]);

    res.json({ success: true });
  } catch (err) {
    console.error('Reset password error:', err);
    res.status(500).json({ error: 'Could not reset your password. Please try again.' });
  }
});

// POST /api/recovery/reset-pin  { resetToken, newPin }
router.post('/reset-pin', async (req, res) => {
  const { resetToken, newPin } = req.body;
  if (typeof newPin !== 'string' || !/^\d{4}$/.test(newPin)) {
    return res.status(400).json({ error: 'PIN must be exactly 4 digits' });
  }

  try {
    const reset = await findResetByToken(resetToken);
    if (!reset) {
      return res.status(400).json({ error: 'Your reset session has expired. Please start again.' });
    }

    const pinHash = await bcrypt.hash(newPin, 10);
    const now = new Date();
    await pool.query(
      `INSERT INTO users (uid, email, pin_hash, has_pin, pin_updated_at, created_at)
       VALUES (?, ?, ?, TRUE, ?, ?)
       ON DUPLICATE KEY UPDATE pin_hash = VALUES(pin_hash), has_pin = TRUE, pin_updated_at = VALUES(pin_updated_at)`,
      [reset.uid, reset.email, pinHash, now, now]
    );
    await pool.query('UPDATE password_resets SET used = TRUE WHERE id = ?', [reset.id]);

    res.json({ success: true });
  } catch (err) {
    console.error('Reset PIN error:', err);
    res.status(500).json({ error: 'Could not reset your PIN. Please try again.' });
  }
});

module.exports = router;