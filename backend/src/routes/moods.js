const express = require('express');
const { Timestamp } = require('firebase-admin/firestore');
const { db } = require('../config/firebase');
const verifyToken = require('../middleware/auth');

const router = express.Router();
router.use(verifyToken);

// ---------- Allowed values ----------
// Each mood has a score used for the chart (5 = best, 1 = lowest)
const MOOD_SCORES = { happy: 5, neutral: 4, angry: 3, sad: 2, cry: 1 };
const TRIGGERS = ['sleep', 'work', 'relationship', 'money', 'health', 'other'];
const HELPED = ['breathing', 'music', 'movement', 'break', 'talked', 'other'];
const DAY_MS = 24 * 60 * 60 * 1000;

// ---------- Helpers ----------
function moodsRef(uid) {
  return db.collection('users').doc(uid).collection('moods');
}

// Shape of one entry sent to the app
function toEntry(doc) {
  const d = doc.data();
  return {
    id: doc.id,
    mood: d.mood,
    score: d.score,
    trigger: d.trigger,
    note: d.note ?? '',
    whatHelped: d.whatHelped ?? [],
    helpedNote: d.helpedNote ?? '',
    createdAt: d.createdAt ? d.createdAt.toDate().toISOString() : null,
  };
}

// The app sends its time zone (e.g. Nepal = +345 minutes),
// so "today" and "this week" match the user's clock, not the server's.
function getTzOffset(req) {
  const n = parseInt(req.query.tzOffset, 10);
  return Number.isFinite(n) && Math.abs(n) <= 840 ? n : 0;
}

// "2026-11-20" for a date, in the user's time zone
function localDayKey(date, tz) {
  return new Date(date.getTime() + tz * 60000).toISOString().slice(0, 10);
}

// The moment the user's day started, (days - 1) days ago
function startOfRange(days, tz) {
  const nowLocal = Date.now() + tz * 60000;
  const localMidnight = Math.floor(nowLocal / DAY_MS) * DAY_MS;
  return new Date(localMidnight - (days - 1) * DAY_MS - tz * 60000);
}

async function entriesSince(uid, start) {
  const snap = await moodsRef(uid)
    .where('createdAt', '>=', Timestamp.fromDate(start))
    .orderBy('createdAt', 'asc')
    .get();
  return snap.docs.map(toEntry);
}

// ---------- Routes ----------

// POST /api/moods → save a new mood (Home screen)
router.post('/', async (req, res) => {
  const { mood, trigger, note } = req.body;

  if (!Object.prototype.hasOwnProperty.call(MOOD_SCORES, mood)) {
    return res.status(400).json({ error: 'Please choose a mood' });
  }
  if (!TRIGGERS.includes(trigger)) {
    return res.status(400).json({ error: "Please choose what's behind it" });
  }
  if (note !== undefined && (typeof note !== 'string' || note.length > 500)) {
    return res.status(400).json({ error: 'Note must be under 500 characters' });
  }

  try {
    const ref = await moodsRef(req.user.uid).add({
      mood,
      score: MOOD_SCORES[mood],
      trigger,
      note: (note || '').trim(),
      whatHelped: [],
      helpedNote: '',
      createdAt: Timestamp.now(),
    });
    const doc = await ref.get();
    res.status(201).json(toEntry(doc));
  } catch (err) {
    console.error('Save mood error:', err);
    res.status(500).json({ error: 'Could not save your mood' });
  }
});

// GET /api/moods?search=work → all entries, newest first (History screen)
router.get('/', async (req, res) => {
  const search = (req.query.search || '').toString().trim().toLowerCase();

  try {
    const snap = await moodsRef(req.user.uid)
      .orderBy('createdAt', 'desc')
      .limit(200)
      .get();
    let entries = snap.docs.map(toEntry);

    if (search) {
      entries = entries.filter(
        (e) =>
          e.note.toLowerCase().includes(search) ||
          e.helpedNote.toLowerCase().includes(search) ||
          e.trigger.includes(search) ||
          e.mood.includes(search)
      );
    }
    res.json(entries);
  } catch (err) {
    console.error('List moods error:', err);
    res.status(500).json({ error: 'Could not load your history' });
  }
});

// GET /api/moods/summary → this week's review (Weekly Summary screen)
router.get('/summary', async (req, res) => {
  const tz = getTzOffset(req);
  const start = startOfRange(7, tz);

  try {
    const entries = await entriesSince(req.user.uid, start);
    const dayOf = (e) => localDayKey(new Date(e.createdAt), tz);

    // Most common value, counted in DAYS (e.g. "Happy, 3 days")
    function mostCommon(field) {
      const days = {};
      entries.forEach((e) => {
        days[e[field]] = days[e[field]] || new Set();
        days[e[field]].add(dayOf(e));
      });
      let best = null;
      for (const [value, set] of Object.entries(days)) {
        if (!best || set.size > best.count) best = { value, count: set.size };
      }
      return best;
    }

    const topMood = mostCommon('mood');
    const topTrigger = mostCommon('trigger');

    res.json({
      startDate: localDayKey(start, tz),
      endDate: localDayKey(new Date(), tz),
      daysLogged: new Set(entries.map(dayOf)).size,
      totalEntries: entries.length,
      topMood: topMood ? { mood: topMood.value, days: topMood.count } : null,
      topTrigger: topTrigger
        ? { trigger: topTrigger.value, days: topTrigger.count }
        : null,
    });
  } catch (err) {
    console.error('Summary error:', err);
    res.status(500).json({ error: 'Could not load your weekly summary' });
  }
});

// GET /api/moods/chart?days=7 (or 30) → average mood per day (Mood Chart)
router.get('/chart', async (req, res) => {
  const tz = getTzOffset(req);
  const days = req.query.days === '30' ? 30 : 7;
  const start = startOfRange(days, tz);

  try {
    const entries = await entriesSince(req.user.uid, start);

    // Group scores by day
    const byDay = {};
    entries.forEach((e) => {
      const key = localDayKey(new Date(e.createdAt), tz);
      (byDay[key] = byDay[key] || []).push(e.score);
    });

    // One point per day (average is null on days with no entry)
    const points = [];
    for (let i = 0; i < days; i++) {
      const key = localDayKey(new Date(start.getTime() + i * DAY_MS), tz);
      const scores = byDay[key] || [];
      const average = scores.length
        ? Math.round((scores.reduce((a, b) => a + b, 0) / scores.length) * 10) / 10
        : null;
      points.push({ date: key, average, count: scores.length });
    }

    res.json({ days, points });
  } catch (err) {
    console.error('Chart error:', err);
    res.status(500).json({ error: 'Could not load your mood chart' });
  }
});

// GET /api/moods/:id → one entry (Entry Detail screen)
router.get('/:id', async (req, res) => {
  try {
    const doc = await moodsRef(req.user.uid).doc(req.params.id).get();
    if (!doc.exists) return res.status(404).json({ error: 'Entry not found' });
    res.json(toEntry(doc));
  } catch (err) {
    console.error('Get mood error:', err);
    res.status(500).json({ error: 'Could not load this entry' });
  }
});

// PUT /api/moods/:id/helped → save "What helped" (What Helped screen)
router.put('/:id/helped', async (req, res) => {
  const { whatHelped, helpedNote } = req.body;

  const validList =
    Array.isArray(whatHelped) && whatHelped.every((h) => HELPED.includes(h));
  if (!validList) {
    return res.status(400).json({ error: 'Invalid "what helped" options' });
  }
  if (helpedNote !== undefined && (typeof helpedNote !== 'string' || helpedNote.length > 500)) {
    return res.status(400).json({ error: 'Note must be under 500 characters' });
  }

  try {
    const ref = moodsRef(req.user.uid).doc(req.params.id);
    const doc = await ref.get();
    if (!doc.exists) return res.status(404).json({ error: 'Entry not found' });

    await ref.update({
      whatHelped: [...new Set(whatHelped)],
      helpedNote: (helpedNote || '').trim(),
    });
    res.json(toEntry(await ref.get()));
  } catch (err) {
    console.error('Save what helped error:', err);
    res.status(500).json({ error: 'Could not save what helped' });
  }
});

// DELETE /api/moods/:id → delete an entry (Entry Detail screen)
router.delete('/:id', async (req, res) => {
  try {
    const ref = moodsRef(req.user.uid).doc(req.params.id);
    const doc = await ref.get();
    if (!doc.exists) return res.status(404).json({ error: 'Entry not found' });

    await ref.delete();
    res.json({ success: true });
  } catch (err) {
    console.error('Delete mood error:', err);
    res.status(500).json({ error: 'Could not delete this entry' });
  }
});

module.exports = router;