import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/features/floor/domain/stakes.dart';
import 'package:pokerspot/features/floor/domain/waitlist_entry.dart';

const _stakes = Stakes(variant: GameVariant.nlh, smallBlind: 1, bigBlind: 2, currency: 'GEL');

void main() {
  test('WaitlistStatus parses; defaults to waiting', () {
    expect(WaitlistStatus.fromString('called'), WaitlistStatus.called);
    expect(WaitlistStatus.fromString('seated'), WaitlistStatus.seated);
    expect(WaitlistStatus.fromString('cancelled'), WaitlistStatus.cancelled);
    expect(WaitlistStatus.fromString(null), WaitlistStatus.waiting);
  });

  test('fromMap/toMap round-trips incl. timestamp millis', () {
    final created = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    final e = WaitlistEntry(
      id: 'e1',
      clubId: 'c',
      playerUid: 'u',
      playerName: 'Nino',
      stakes: _stakes,
      status: WaitlistStatus.waiting,
      createdAt: created,
      calledAt: null,
    );
    final back = WaitlistEntry.fromMap('e1', e.toMap());
    expect(back, equals(e));
    expect(back.createdAt, created);
    expect(back.calledAt, isNull);
    expect(e.toMap()['createdAt'], 1700000000000);
    expect(e.toMap()['variant'], 'nlh');
  });

  test('fromMap defaults + null timestamps', () {
    final e = WaitlistEntry.fromMap('e', const {});
    expect(e.clubId, '');
    expect(e.playerUid, '');
    expect(e.status, WaitlistStatus.waiting);
    expect(e.createdAt, isNull);
    expect(e.stakes.variant, GameVariant.nlh);
  });

  test('== / copyWith', () {
    const e = WaitlistEntry(
      id: 'e',
      clubId: 'c',
      playerUid: 'u',
      playerName: 'N',
      stakes: _stakes,
      status: WaitlistStatus.waiting,
      createdAt: null,
      calledAt: null,
    );
    expect(e == e.copyWith(status: WaitlistStatus.called), isFalse);
    expect(e.copyWith(playerName: 'X').playerName, 'X');
    expect(e, equals(e.copyWith()));
  });
}
