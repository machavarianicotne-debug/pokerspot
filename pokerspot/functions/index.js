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
    const stale = [];
    const warn = []; // ≤5 min left and not yet warned
    snap.docs.forEach((d) => {
      const data = d.data();
      const ms = data.heldUntil && data.heldUntil.toMillis ? data.heldUntil.toMillis() : 0;
      if (ms <= 0) return;
      if (ms < now) {
        stale.push(d);
      } else if (ms - now <= 5 * 60 * 1000 && data.warned5 !== true) {
        warn.push(d);
      }
    });

    // "5 minutes left" push to the holder (once, flagged so it never repeats).
    for (const d of warn) {
      const r = d.data();
      await sendToTokens(await playerTokens(r.playerUid), 'Reservation ending soon',
        '5 minutes left on your reservation', { clubId: r.clubId || '', type: 'reservation' });
      await d.ref.update({ warned5: true });
    }

    if (stale.length > 0) {
      const batch = db.batch();
      stale.forEach((d) => batch.update(d.ref, { status: 'expired' }));
      await batch.commit();
    }
    console.log(`expireReservations: warned ${warn.length}, expired ${stale.length}`);
    return null;
  });

// (a3) Scheduled cleanup — release held SEATS (reservation 30-min / called 10-min)
// whose hold expired, so the seat frees for the next player (1st-gen).
exports.expireHolds = functions.pubsub
  .schedule('every 1 minutes')
  .onRun(async () => {
    const now = Date.now();
    const snap = await db.collection('sessions').where('status', '==', 'held').get();
    const stale = snap.docs.filter((d) => {
      const t = d.data().heldUntil;
      const ms = t && t.toMillis ? t.toMillis() : 0;
      return ms > 0 && ms < now;
    });
    if (stale.length === 0) return null;
    const batch = db.batch();
    stale.forEach((d) =>
      batch.update(d.ref, { status: 'ended', endedAt: admin.firestore.FieldValue.serverTimestamp() }));
    await batch.commit();
    console.log(`expireHolds: released ${stale.length} expired seat holds`);
    return null;
  });

// (b) Push when a waitlist entry flips to 'called' (2nd-gen).
exports.notifyCalled = onDocumentUpdated(
  { document: 'waitlist/{id}', region: DB_REGION },
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    if (before.status === 'called' || after.status !== 'called') return;
    const variant = (after.variant || '').toString().toUpperCase();
    await sendToTokens(await playerTokens(after.playerUid), "You're called!",
      `Your ${variant} ${after.smallBlind}/${after.bigBlind} seat is ready.`,
      { clubId: after.clubId || '', type: 'waitlist.called' });
  },
);

// (d) Denormalize live club stats onto the club doc so PLAYERS (who can't read
// other clubs' sessions/waitlist) still see open seats / stakes / waitlist.
// Recompute on any session / waitlist / table write (2nd-gen).
const stakeKey = (x) => `${x.variant}-${x.smallBlind}-${x.bigBlind}-${x.currency}`;
// MUST equal the client's Stakes.label (GameVariant.label + blinds + currency),
// otherwise the denormalized club.games entries won't line up with what the app
// looks up and the player sees "—" for open seats / waitlist.
const variantLabel = (v) =>
  ({
    nlh: 'NLH',
    nlhPlo: 'NLH/PLO',
    nlhPlo5: 'NLH/PLO5',
    plo: 'PLO',
    plo5: 'PLO5',
    plo6: 'PLO6',
    dealerChoice: "Dealer's Choice",
  })[v] || 'NLH';
const fmtNum = (n) => (typeof n === 'number' && n % 1 === 0 ? String(Math.trunc(n)) : String(n));
const stakeLabel = (t) =>
  `${variantLabel(t.variant)} ${fmtNum(t.smallBlind)}/${fmtNum(t.bigBlind)} ${t.currency || ''}`.trim();

async function recomputeClub(clubId) {
  if (!clubId) return;
  const [tablesSnap, sessionsSnap, waitlistSnap] = await Promise.all([
    db.collection('clubs').doc(clubId).collection('tables').get(),
    db.collection('sessions').where('clubId', '==', clubId).where('status', '==', 'active').get(),
    db.collection('waitlist').where('clubId', '==', clubId).get(),
  ]);

  // One scoreboard entry PER OPEN TABLE (tables are independent, even at the
  // same stake). Keyed by tableId so the player's per-table card lines up.
  const games = {}; // tableId -> game accumulator
  const stakeSet = new Set(); // distinct stakes running (for club.stakes)
  tablesSnap.forEach((d) => {
    const t = d.data();
    if (t.open === false) return;
    stakeSet.add(stakeKey(t));
    games[d.id] = {
      tableId: d.id,
      label: stakeLabel(t),
      type: (t.variant || '').toUpperCase(),
      minBuyIn: t.minBuyIn != null ? t.minBuyIn : null,
      avgStack: t.avgStack != null ? t.avgStack : null,
      tables: 1,
      seats: t.seatCount || 0,
      occupied: 0,
      waiting: 0,
    };
  });
  sessionsSnap.forEach((d) => {
    const g = games[d.data().tableId];
    if (g) g.occupied += 1;
  });
  waitlistSnap.forEach((d) => {
    const w = d.data();
    if (w.status !== 'waiting' && w.status !== 'called') return;
    const g = games[w.tableId];
    if (g) g.waiting += 1;
  });

  const gamesArr = Object.values(games)
    .sort((a, b) => a.tableId.localeCompare(b.tableId))
    .map((g) => ({
      label: g.label, tableId: g.tableId, type: g.type, minBuyIn: g.minBuyIn, avgStack: g.avgStack,
      tables: g.tables, openSeats: Math.max(0, g.seats - g.occupied), waiting: g.waiting,
    }));
  const totalOccupied = Object.values(games).reduce((a, g) => a + g.occupied, 0);

  await db.collection('clubs').doc(clubId).set(
    {
      live: gamesArr.length > 0,
      openSeats: gamesArr.reduce((a, g) => a + g.openSeats, 0),
      players: totalOccupied,
      stakes: stakeSet.size,
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
    // Play the device's default notification sound on every platform.
    android: { notification: { sound: 'default' } },
    apns: { payload: { aps: { sound: 'default' } } },
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

// Reservation -> red held seat: assign the first free seat of the stake and hold
// it (status held, 30-min) so it shows blocked in the Pit cabinet. The player
// can't read sessions to pick a seat, so the server does it. No free seat ->
// stays a pending reservation (shown in the Pit's reservations list).
exports.onReservationCreate = onDocumentCreated(
  { document: 'reservations/{id}', region: DB_REGION },
  async (event) => {
    const r = event.data && event.data.data();
    if (!r || r.status !== 'held') return;
    const key = stakeKey(r);
    const tablesSnap = await db.collection('clubs').doc(r.clubId).collection('tables').get();
    const tables = tablesSnap.docs
      .map((d) => ({ id: d.id, ...d.data() }))
      .filter((t) => t.open !== false && stakeKey(t) === key);
    if (tables.length === 0) return;
    const sessSnap = await db.collection('sessions').where('clubId', '==', r.clubId).get();
    const open = sessSnap.docs
      .map((d) => d.data())
      .filter((s) => s.status === 'active' || s.status === 'held');
    let chosen = null;
    for (const t of tables) {
      const taken = new Set(open.filter((s) => s.tableId === t.id).map((s) => s.seatNumber));
      for (let n = 1; n <= (t.seatCount || 9); n++) {
        if (!taken.has(n)) { chosen = { tableId: t.id, seat: n }; break; }
      }
      if (chosen) break;
    }
    if (!chosen) return; // no free seat -> pending reservation
    const heldUntilMs =
      r.heldUntil && r.heldUntil.toMillis ? r.heldUntil.toMillis() : Date.now() + 30 * 60000;
    await db.collection('sessions').add({
      clubId: r.clubId, tableId: chosen.tableId, seatNumber: chosen.seat,
      playerUid: r.playerUid, playerName: r.playerName || '',
      variant: r.variant, smallBlind: r.smallBlind, bigBlind: r.bigBlind, currency: r.currency,
      status: 'held', startedAt: null, endedAt: null,
      holdKind: 'reservation', heldUntil: admin.firestore.Timestamp.fromMillis(heldUntilMs),
    });
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

// (d) Account deletion (GDPR right-to-erasure / App Store 5.1.1(v)): a user writes
// deletion_requests/{uid}; cascade-delete their data + Auth account, then clear it.
exports.onAccountDeletion = onDocumentCreated(
  { document: 'deletion_requests/{uid}', region: DB_REGION },
  async (event) => {
    const uid = event.params.uid;
    if (!uid) return;
    const queries = [
      db.collection('waitlist').where('playerUid', '==', uid),
      db.collection('reservations').where('playerUid', '==', uid),
      db.collection('tournament_registrations').where('playerUid', '==', uid),
      db.collection('sessions').where('playerUid', '==', uid),
      db.collection('messages').where('playerUid', '==', uid),
      db.collection('messages').where('senderUid', '==', uid),
    ];
    for (const q of queries) {
      const snap = await q.get();
      if (snap.empty) continue;
      const batch = db.batch();
      snap.forEach((d) => batch.delete(d.ref));
      await batch.commit();
    }
    await db.collection('users').doc(uid).delete().catch(() => {});
    await db.collection('deletion_requests').doc(uid).delete().catch(() => {});
    try {
      await admin.auth().deleteUser(uid);
    } catch (e) {
      // The Auth user may already be gone — ignore.
    }
  },
);
