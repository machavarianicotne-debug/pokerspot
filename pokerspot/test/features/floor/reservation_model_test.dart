import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/features/floor/domain/stakes.dart';
import 'package:pokerspot/features/floor/domain/reservation.dart';

void main() {
  const stakes = Stakes(variant: GameVariant.nlh, smallBlind: 5, bigBlind: 10, currency: 'GEL');

  test('Reservation round-trips tableId', () {
    const r = Reservation(
      id: 'r1', clubId: 'vake', tableId: 't2', playerUid: 'u', playerName: 'Levan',
      stakes: stakes, status: ReservationStatus.held, heldUntil: null, createdAt: null);
    final round = Reservation.fromMap('r1', r.toMap());
    expect(round.tableId, 't2');
    expect(round, r);
  });
}
