// PokerSpot Cloud Functions (Plan 7-A). Gen-1 API (firebase-functions v4).
//  (a) expireWaitlist  — scheduled: cancel 'called' entries not seated in time.
//  (b) notifyCalled    — trigger: FCM push when a waitlist entry becomes 'called'.
//  (c) auditSessionEnd — trigger: log session end to admin_audit_log.
const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

// Minutes a called player has to be seated before the entry auto-cancels.
const CALL_EXPIRY_MIN = 10;

// (a) Scheduled cleanup — runs every 5 minutes.
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

// (b) Push when a waitlist entry flips to 'called'.
exports.notifyCalled = functions.firestore
  .document('waitlist/{id}')
  .onUpdate(async (change) => {
    const before = change.before.data();
    const after = change.after.data();
    if (before.status === 'called' || after.status !== 'called') return null;

    const userSnap = await db.collection('users').doc(after.playerUid).get();
    const tokens = (userSnap.exists && userSnap.data().fcmTokens) || [];
    if (!Array.isArray(tokens) || tokens.length === 0) return null;

    const variant = (after.variant || '').toString().toUpperCase();
    await admin.messaging().sendEachForMulticast({
      tokens,
      notification: {
        title: "You're called!",
        body: `Your ${variant} ${after.smallBlind}/${after.bigBlind} seat is ready.`,
      },
      data: { clubId: after.clubId || '', type: 'waitlist.called' },
    });
    return null;
  });

// (c) Audit a session when it ends.
exports.auditSessionEnd = functions.firestore
  .document('sessions/{id}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    if (before.status === 'ended' || after.status !== 'ended') return null;

    await db.collection('admin_audit_log').add({
      actorUid: 'system',
      action: 'session.end',
      target: context.params.id,
      meta: { clubId: after.clubId || '', playerUid: after.playerUid || '' },
      at: admin.firestore.FieldValue.serverTimestamp(),
    });
    return null;
  });
