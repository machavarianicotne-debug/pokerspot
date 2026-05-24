// PokerSpot Cloud Functions (Plan 7-A).
//  (a) expireWaitlist  — 1st-gen scheduled: cancel 'called' entries not seated.
//  (b) notifyCalled    — 2nd-gen Firestore trigger: FCM push on status->called.
//  (c) auditSessionEnd — 2nd-gen Firestore trigger: log session end to audit log.
// Firestore is the eur3 multi-region DB, which 1st-gen Firestore triggers do NOT
// support — (b)/(c) therefore use the 2nd-gen (Eventarc) API in europe-west1.
const functions = require('firebase-functions');
const { onDocumentUpdated } = require('firebase-functions/v2/firestore');
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
