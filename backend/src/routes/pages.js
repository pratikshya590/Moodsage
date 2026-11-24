const express = require('express');

const router = express.Router();

const page = (title, body) => `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${title} – Moodsage</title>
<style>
  body { font-family: system-ui, sans-serif; max-width: 720px; margin: 40px auto; padding: 0 20px; line-height: 1.6; color: #1E1E1E; background: #FAF6EB; }
  h1 { color: #3C4F19; }
  h2 { color: #587626; margin-top: 28px; }
  a { color: #465F19; }
</style>
</head>
<body>
${body}
<p style="margin-top:40px;font-size:14px;color:#867F7F">
  <a href="/">Home</a> · <a href="/privacy">Privacy policy</a> · <a href="/terms">Terms of service</a>
</p>
</body>
</html>`;

router.get('/', (req, res) => {
  res.send(page('Home', `
    <h1>Moodsage</h1>
    <p>Moodsage is a mood tracker with instant stress relief, built as a university project
    (University of Bedfordshire, CIS099-2).</p>
    <p>Users log their mood, see what triggered it, review their history and charts,
    and try short calming and sleep exercises.</p>
    <p>Contact: moodsage6@gmail.com</p>
  `));
});

router.get('/privacy', (req, res) => {
  res.send(page('Privacy policy', `
    <h1>Privacy policy</h1>
    <p>Last updated: November 2026</p>

    <h2>What we collect</h2>
    <p>Your email address and password (handled by Firebase Authentication), your display name,
    an optional profile photo, a hashed app PIN, and the mood entries you save
    (mood, trigger, notes and what helped).</p>

    <h2>How we use it</h2>
    <p>Only to run the app: to log you in, show your mood history and charts, and send you
    a one-time code by email if you forget your password or PIN.</p>

    <h2>Emails</h2>
        <p>Moodsage sends account recovery codes from moodsage6@gmail.com. We use Gmail only to
    send these codes. We do not read your mailbox.</p>

    <h2>Storage and security</h2>
    <p>Data is stored in a MySQL-compatible cloud database over encrypted connections.
    PINs and recovery codes are stored as hashes, never in plain text.
    Each user can only access their own data.</p>

    <h2>Sharing</h2>
    <p>We do not sell or share your data with anyone.</p>

    <h2>Deleting your data</h2>
    <p>You can clear your mood data in the app's Settings, or email moodsage6@gmail.com
    to have your account deleted.</p>

    <h2>Contact</h2>
    <p>moodsage6@gmail.com</p>
  `));
});

router.get('/terms', (req, res) => {
  res.send(page('Terms of service', `
    <h1>Terms of service</h1>
    <p>Last updated: November 2026</p>
    <p>Moodsage is a student project provided for learning and demonstration purposes, as is,
    without any guarantee.</p>
    <p>Moodsage is not a medical service and does not replace professional help.
    If you are struggling, please contact a health professional or a local support service.</p>
    <p>Please use the app responsibly and do not misuse it or try to access other users' data.</p>
    <p>Contact: moodsage6@gmail.com</p>
  `));
});

module.exports = router;