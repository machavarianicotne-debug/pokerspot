// PokerSpot Cloud Functions (Plan 7-A).
//  (a) expireWaitlist  — 1st-gen scheduled: cancel 'called' entries not seated.
//  (b) notifyCalled    — 2nd-gen Firestore trigger: FCM push on status->called.
//  (c) auditSessionEnd — 2nd-gen Firestore trigger: log session end to audit log.
// Firestore is the eur3 multi-region DB, which 1st-gen Firestore triggers do NOT
// support — (b)/(c) therefore use the 2nd-gen (Eventarc) API in europe-west1.
const functions = require('firebase-functions');
const {
  onDocumentCreated,
  onDocumentUpdated,
  onDocumentWritten,
} = require('firebase-functions/v2/firestore');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

// Minutes a called player has to be seated before the entry auto-cancels.
const CALL_EXPIRY_MIN = 10;
// eur3 multi-region → run the Firestore triggers in europe-west1.
const DB_REGION = 'europe-west1';

// (a) Scheduled cleanup — runs every 5 minutes (1st-gen).
exports.expireWaitlist = functions.pubsub
  .schedule('every 5 minutes')
  .onRun(async () => {
    const cutoff = Date.now() - CALL_EXPIRY_MIN * 60 * 1000;
    // Single-field equality query (no composite index); filter the time in code.
    const snap = await db.collection('waitlist').where('status', '==', 'called').get();
    const stale = snap.docs.filter((d) => {
      const t = d.data().calledAt;
      const ms = t && t.toMillis ? t.toMillis() : 0;
      return ms > 0 && ms < cutoff;
    });
    if (stale.length === 0) return null;
    const batch = db.batch();
    stale.forEach((d) => batch.update(d.ref, { status: 'cancelled' }));
    await batch.commit();
    console.log(`expireWaitlist: cancelled ${stale.length} stale called entries`);
    return null;
  });

// (a2) Scheduled cleanup — expire held reservations past their 30-min hold (1st-gen).
exports.expireReservations = functions.pubsub
  .schedule('every 5 minutes')
  .onRun(async () => {
    const now = Date.now();
    const snap = await db.collection('reservations').where('status', '==', 'held').get();
    const stale = snap.docs.filter((d) => {
      const t = d.data().heldUntil;
      const ms = t && t.toMillis ? t.toMillis() : 0;
      return ms > 0 && ms < now;
    });
    if (stale.length === 0) return null;
    const batch = db.batch();
    stale.forEach((d) => batch.update(d.ref, { status: 'expired' }));
    await batch.commit();
    console.log(`expireReservations: expired ${stale.length} stale holds`);
    return null;
  });

// (b) Push when a waitlist entry flips to 'called' (2nd-gen).
exports.notifyCalled = onDocumentUpdated(
  { document: 'waitlist/{id}', region: DB_REGION },
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    if (before.status === 'called' || after.status !== 'called') return;

    const userSnap = await db.collection('users').doc(after.playerUid).get();
    const tokens = (userSnap.exists && userSnap.data().fcmTokens) || [];
    if (!Array.isArray(tokens) || tokens.length === 0) return;

    const variant = (after.variant || '').toString().toUpperCase();
    await admin.messaging().sendEachForMulticast({
      tokens,
      notification: {
        title: "You're called!",
        body: `Your ${variant} ${after.smallBlind}/${after.bigBlind} seat is ready.`,
      },
      data: { clubId: after.clubId || '', type: 'waitlist.called' },
    });
  },
);

// (d) Denormalize live club stats onto the club doc so PLAYERS (who can't read
// other clubs' sessions/waitlist) still see open seats / stakes / waitlist.
// Recompute on any session / waitlist / table write (2nd-gen).
const stakeKey = (x) => `${x.variant}-${x.smallBlind}-${x.bigBlind}-${x.currency}`;
const stakeLabel = (t) =>
  `${(t.variant || '').toUpperCase()} ${t.smallBlind}/${t.bigBlind} ${t.currency || ''}`.trim();

async function recomputeClub(clubId) {
  if (!clubId) return;
  const [tablesSnap, sessionsSnap, waitlistSnap] = await Promise.all([
    db.collection('clubs').doc(clubId).collection('tables').get(),
    db.collection('sessions').where('clubId', '==', clubId).where('status', '==', 'active').get(),
    db.collection('waitlist').where('clubId', '==', clubId).get(),
  ]);

  // Group open tables by stake → per-stake game scoreboard.
  const games = {};
  tablesSnap.forEach((d) => {
    const t = d.data();
    if (t.open === false) return;
    const k = stakeKey(t);
    if (!games[k]) {
      games[k] = {
        label: stakeLabel(t), type: (t.variant || '').toUpperCase(),
        minBuyIn: t.minBuyIn != null ? t.minBuyIn : null,
        avgStack: t.avgStack != null ? t.avgStack : null,
        tables: 0, seats: 0, occupied: 0, waiting: 0,
      };
    }
    const g = games[k];
    g.tables += 1;
    g.seats += t.seatCount || 0;
    if (t.minBuyIn != null) g.minBuyIn = g.minBuyIn == null ? t.minBuyIn : Math.min(g.minBuyIn, t.minBuyIn);
    if (t.avgStack != null) g.avgStack = t.avgStack;
  });
  sessionsSnap.forEach((d) => {
    const g = games[stakeKey(d.data())];
    if (g) g.occupied += 1;
  });
  waitlistSnap.forEach((d) => {
    const w = d.data();
    if (w.status !== 'waiting' && w.status !== 'called') return;
    const g = games[stakeKey(w)];
    if (g) g.waiting += 1;
  });

  const gamesArr = Object.values(games).map((g) => ({
    label: g.label, type: g.type, minBuyIn: g.minBuyIn, avgStack: g.avgStack,
    tables: g.tables, openSeats: Math.max(0, g.seats - g.occupied), waiting: g.waiting,
  }));
  const totalOccupied = Object.values(games).reduce((a, g) => a + g.occupied, 0);

  await db.collection('clubs').doc(clubId).set(
    {
      live: totalOccupied > 0,
      openSeats: gamesArr.reduce((a, g) => a + g.openSeats, 0),
      players: totalOccupied,
      stakes: gamesArr.length,
      waiting: gamesArr.reduce((a, g) => a + g.waiting, 0),
      games: gamesArr,
    },
    { merge: true },
  );
}

// ---- Push helpers + notifications -----------------------------------------
async function sendToTokens(tokens, title, body, data) {
  const list = (Array.isArray(tokens) ? tokens : []).filter(Boolean);
  if (list.length === 0) return;
  await admin.messaging().sendEachForMulticast({
    tokens: list,
    notification: { title, body },
    data: data || {},
  });
}

async function pitBossTokens(clubId) {
  if (!clubId) return [];
  const snap = await db.collection('users').where('clubId', '==', clubId).get();
  const tokens = [];
  snap.forEach((d) => {
    const u = d.data();
    if ((u.role === 'pit_boss' || u.role === 'pitboss') && Array.isArray(u.fcmTokens)) {
      tokens.push(...u.fcmTokens);
    }
  });
  return tokens;
}

async function playerTokens(uid) {
  if (!uid) return [];
  const s = await db.collection('users').doc(uid).get();
  return s.exists && Array.isArray(s.data().fcmTokens) ? s.data().fcmTokens : [];
}

const stakeText = (x) => `${(x.variant || '').toString().toUpperCase()} ${x.smallBlind}/${x.bigBlind}`;

// Pit Boss: a player joined the waitlist.
exports.notifyPitWaitlist = onDocumentCreated(
  { document: 'waitlist/{id}', region: DB_REGION },
  async (event) => {
    const w = event.data && event.data.data();
    if (!w) return;
    await sendToTokens(await pitBossTokens(w.clubId), 'New waitlist join',
      `${w.playerName || 'A player'} · ${stakeText(w)}`, { clubId: w.clubId || '', type: 'waitlist.join' });
  },
);

// Pit Boss: a player made a reservation.
exports.notifyPitReservation = onDocumentCreated(
  { document: 'reservations/{id}', region: DB_REGION },
  async (event) => {
    const r = event.data && event.data.data();
    if (!r) return;
    await sendToTokens(await pitBossTokens(r.clubId), 'New reservation',
      `${r.playerName || 'A player'} · ${stakeText(r)}`, { clubId: r.clubId || '', type: 'reservation.new' });
  },
);

// Chat: notify the other party on a new message.
exports.notifyMessage = onDocumentCreated(
  { document: 'messages/{id}', region: DB_REGION },
  async (event) => {
    const m = event.data && event.data.data();
    if (!m) return;
    if (m.senderRole === 'player') {
      await sendToTokens(await pitBossTokens(m.clubId), 'New chat message',
        `${m.playerName || 'Player'}: ${m.text || ''}`, { clubId: m.clubId || '', type: 'chat' });
    } else {
      await sendToTokens(await playerTokens(m.playerUid), 'Pit Boss replied',
        m.text || '', { clubId: m.clubId || '', type: 'chat' });
    }
  },
);

// Players waiting for a stake: a seat opened when a session ended.
exports.notifySeatOpen = onDocumentUpdated(
  { document: 'sessions/{id}', region: DB_REGION },
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    if (before.status === 'ended' || after.status !== 'ended') return;
    const key = stakeKey(after);
    const snap = await db.collection('waitlist').where('clubId', '==', after.clubId).get();
    const tokens = [];
    for (const d of snap.docs) {
      const w = d.data();
      if (w.status === 'waiting' && stakeKey(w) === key) {
        tokens.push(...(await playerTokens(w.playerUid)));
      }
    }
    await sendToTokens(tokens, 'A seat opened up', `${stakeText(after)} — head over`,
      { clubId: after.clubId || '', type: 'seat.open' });
  },
);

function clubIdOf(event) {
  if (event.params && event.params.clubId) return event.params.clubId; // tables subcollection
  const after = event.data && event.data.after && event.data.after.data();
  const before = event.data && event.data.before && event.data.before.data();
  return (after && after.clubId) || (before && before.clubId) || null;
}

exports.syncOnSession = onDocumentWritten(
  { document: 'sessions/{id}', region: DB_REGION },
  (event) => recomputeClub(clubIdOf(event)),
);
exports.syncOnWaitlist = onDocumentWritten(
  { document: 'waitlist/{id}', region: DB_REGION },
  (event) => recomputeClub(clubIdOf(event)),
);
exports.syncOnTable = onDocumentWritten(
  { document: 'clubs/{clubId}/tables/{tableId}', region: DB_REGION },
  (event) => recomputeClub(clubIdOf(event)),
);

// (c) Audit a session when it ends (2nd-gen).
exports.auditSessionEnd = onDocumentUpdated(
  { document: 'sessions/{id}', region: DB_REGION },
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    if (before.status === 'ended' || after.status !== 'ended') return;

    await db.collection('admin_audit_log').add({
      actorUid: 'system',
      action: 'session.end',
      target: event.params.id,
      meta: { clubId: after.clubId || '', playerUid: after.playerUid || '' },
      at: admin.firestore.FieldValue.serverTimestamp(),
    });
  },
);
