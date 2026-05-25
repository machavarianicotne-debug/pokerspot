import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/features/floor/domain/session.dart';
import 'package:pokerspot/features/floor/domain/stakes.dart';

const _stakes = Stakes(variant: GameVariant.nlh, smallBlind: 1, bigBlind: 2, currency: 'GEL');

void main() {
  test('fromMap/toMap round-trips', () {
    final started = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final s = Session(
      id: 's1',
      clubId: 'c',
      tableId: 't',
      seatNumber: 4,
      playerUid: 'u',
      playerName: 'N',
      stakes: _stakes,
      status: SessionStatus.active,
      startedAt: started,
      endedAt: null,
    );
    final back = Session.fromMap('s1', s.toMap());
    expect(back, equals(s));
    expect(back.seatNumber, 4);
    expect(back.startedAt, started);
    expect(s.toMap()['startedAt'], 1700000000000);
  });

  test('held session round-trips heldUntil + holdKind (epoch millis)', () {
    final heldUntil = DateTime.fromMillisecondsSinceEpoch(1700000600000);
    final s = Session(
      id: 'h1',
      clubId: 'c',
      tableId: 't',
      seatNumber: 2,
      playerUid: 'u',
      playerName: 'N',
      stakes: _stakes,
      status: SessionStatus.held,
      startedAt: null,
      endedAt: null,
      heldUntil: heldUntil,
      holdKind: HoldKind.reservation,
    );
    final map = s.toMap();
    // The Firebase repo converts the stored Timestamp to these millis before
    // fromMap; given millis, parsing must succeed (regression: heldUntil left as
    // a Timestamp made `millis as int` throw and blanked the Pit floor + stats).
    expect(map['heldUntil'], 1700000600000);
    final back = Session.fromMap('h1', map);
    expect(back, equals(s));
    expect(back.heldUntil, heldUntil);
    expect(back.isHeld, isTrue);
  });

  test('SessionStatus parses; defaults active', () {
    expect(SessionStatus.fromString('ended'), SessionStatus.ended);
    expect(SessionStatus.fromString(null), SessionStatus.active);
  });

  test('elapsedAt uses endedAt when ended, else now; null if not started', () {
    final start = DateTime(2026, 1, 1, 10);
    final active = Session(
      id: 's',
      clubId: 'c',
      tableId: 't',
      seatNumber: 1,
      playerUid: 'u',
      playerName: 'N',
      stakes: _stakes,
      status: SessionStatus.active,
      startedAt: start,
      endedAt: null,
    );
    expect(active.elapsedAt(DateTime(2026, 1, 1, 12)), const Duration(hours: 2));

    final ended = active.copyWith(
        status: SessionStatus.ended, endedAt: DateTime(2026, 1, 1, 11));
    expect(ended.elapsedAt(DateTime(2026, 1, 1, 12)), const Duration(hours: 1));

    const notStarted = Session(
      id: 's',
      clubId: 'c',
      tableId: 't',
      seatNumber: 1,
      playerUid: 'u',
      playerName: 'N',
      stakes: _stakes,
      status: SessionStatus.active,
      startedAt: null,
      endedAt: null,
    );
    expect(notStarted.elapsedAt(DateTime(2026, 1, 1, 12)), isNull);
  });
}
