import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/features/floor/domain/session.dart';
import 'package:pokerspot/features/floor/domain/stakes.dart';
import 'package:pokerspot/features/floor/presentation/game_detail_screen.dart';

const _nlh = Stakes(variant: GameVariant.nlh, smallBlind: 1, bigBlind: 2, currency: 'GEL');

Session _session({
  required String tableId,
  required String uid,
  required SessionStatus status,
}) =>
    Session(
      id: '$tableId-$uid-${status.name}',
      clubId: 'vake',
      tableId: tableId,
      seatNumber: 1,
      playerUid: uid,
      playerName: 'P',
      stakes: _nlh,
      status: status,
      startedAt: null,
      endedAt: null,
    );

void main() {
  // The same player can't be seated twice at the same table (requirement: a
  // user already seated/held at a table can't be seated/held there again).
  test('active session at the table blocks re-seating', () {
    final sessions = [_session(tableId: 't1', uid: 'u1', status: SessionStatus.active)];
    expect(GameDetailScreen.seatedAtTable(sessions, 'u1', 't1'), isTrue);
  });

  test('held session at the table blocks re-seating', () {
    final sessions = [_session(tableId: 't1', uid: 'u1', status: SessionStatus.held)];
    expect(GameDetailScreen.seatedAtTable(sessions, 'u1', 't1'), isTrue);
  });

  test('a seat at a DIFFERENT table does not block (per-table rule)', () {
    final sessions = [_session(tableId: 't2', uid: 'u1', status: SessionStatus.active)];
    expect(GameDetailScreen.seatedAtTable(sessions, 'u1', 't1'), isFalse);
  });

  test('an ended session does not block', () {
    final sessions = [_session(tableId: 't1', uid: 'u1', status: SessionStatus.ended)];
    expect(GameDetailScreen.seatedAtTable(sessions, 'u1', 't1'), isFalse);
  });

  test('a different player does not block', () {
    final sessions = [_session(tableId: 't1', uid: 'u2', status: SessionStatus.active)];
    expect(GameDetailScreen.seatedAtTable(sessions, 'u1', 't1'), isFalse);
  });

  test('walk-ins (empty uid) are never matched', () {
    final sessions = [_session(tableId: 't1', uid: '', status: SessionStatus.active)];
    expect(GameDetailScreen.seatedAtTable(sessions, '', 't1'), isFalse);
  });

  test('no sessions never blocks', () {
    expect(GameDetailScreen.seatedAtTable(const [], 'u1', 't1'), isFalse);
  });
}
