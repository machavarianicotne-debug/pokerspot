// PokerSpot Cloud Functions (Plan 7-A).
//  (a) expireWaitlist  — 1st-gen scheduled: cancel 'called' entries not seated.
//  (b) notifyCalled    — 2nd-gen Firestore trigger: FCM push on status->called.
//  (c) auditSessionEnd — 2nd-gen Firestore trigger: log session end to audit log.
// Firestore is the eur3 multi-region DB, which 1st-gen Firestore triggers do NOT
// support — (b)/(c) therefore use the 2nd-gen (Eventarc) API in europe-west1.
const functions = require('firebase-functions');
const { onDocumentUpdated, onDocumentWritten } = require('firebase-functions/v2/firestore');
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
    const cutoff = admin.firestore.Timestamp.fromMillis(
      Date.now() - CALL_EXPIRY_MIN * 60 * 1000,
    );
    const snap = await db
      .collection('waitlist')
      .where('status', '==', 'called')
      .where('calledAt', '<', cutoff)
      .get();
    if (snap.empty) return null;
    const batch = db.batch();
    snap.forEach((d) => batch.update(d.ref, { status: 'cancelled' }));
    await batch.commit();
    console.log(`expireWaitlist: cancelled ${snap.size} stale called entries`);
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
      stakes: gamesArr.length,
      waiting: gamesArr.reduce((a, g) => a + g.waiting, 0),
      games: gamesArr,
    },
    { merge: true },
  );
}

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
