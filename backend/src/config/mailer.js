const nodemailer = require('nodemailer');
const MailComposer = require('nodemailer/lib/mail-composer');

// On Render: free plan blocks SMTP ports, so send through the Gmail API over HTTPS.
// On the laptop (no GMAIL_REFRESH_TOKEN): send through Gmail SMTP as before.

async function getGmailAccessToken() {
  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      client_id: process.env.GMAIL_CLIENT_ID,
      client_secret: process.env.GMAIL_CLIENT_SECRET,
      refresh_token: process.env.GMAIL_REFRESH_TOKEN,
      grant_type: 'refresh_token',
    }),
  });
  if (!res.ok) {
    throw new Error(`Gmail token request failed (${res.status}): ${await res.text()}`);
  }
  const data = await res.json();
  return data.access_token;
}

async function sendWithGmailApi(options) {
  // Build a standard email (MIME) message, then send it with the Gmail API.
  const message = new MailComposer({
    ...options,
    from: options.from || `Moodsage <${process.env.EMAIL_USER}>`,
  });
  const mime = await message.compile().build();
  const raw = mime.toString('base64url');

  const accessToken = await getGmailAccessToken();
  const res = await fetch('https://gmail.googleapis.com/gmail/v1/users/me/messages/send', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'content-type': 'application/json',
    },
    body: JSON.stringify({ raw }),
  });
  if (!res.ok) {
    throw new Error(`Gmail API send failed (${res.status}): ${await res.text()}`);
  }
  return res.json();
}

const gmailSmtp = nodemailer.createTransport({
  service: 'gmail',
  auth: { user: process.env.EMAIL_USER, pass: process.env.EMAIL_PASS },
});

// Same shape as a nodemailer transporter: mailer.sendMail({ from, to, subject, text, html })
const mailer = {
  sendMail(options) {
    if (process.env.GMAIL_REFRESH_TOKEN) return sendWithGmailApi(options);
    return gmailSmtp.sendMail(options);
  },
};
mailer.transporter = mailer;

module.exports = mailer;