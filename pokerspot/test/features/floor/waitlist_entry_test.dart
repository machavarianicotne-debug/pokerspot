import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/features/floor/domain/stakes.dart';
import 'package:pokerspot/features/floor/domain/waitlist_entry.dart';

void main() {
  const stakes = Stakes(variant: GameVariant.nlh, smallBlind: 5, bigBlind: 10, currency: 'GEL');

  test('WaitlistEntry round-trips tableId through toMap/fromMap', () {
    final e = WaitlistEntry(
      id: 'e1', clubId: 'vake', tableId: 't1', playerUid: 'u', playerName: 'Nino',
      stakes: stakes, status: WaitlistStatus.waiting, createdAt: null, calledAt: null);
    final round = WaitlistEntry.fromMap('e1', e.toMap());
    expect(round.tableId, 't1');
    expect(round, e);
  });

  test('WaitlistEntry tableId is null for legacy docs (no tableId key)', () {
    final e = WaitlistEntry.fromMap('e1', {
      'clubId': 'vake', 'playerUid': 'u', 'playerName': 'Nino',
      ...stakes.toMap(), 'status': 'waiting',
    });
    expect(e.tableId, isNull);
  });
}
