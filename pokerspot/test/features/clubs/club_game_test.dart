import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/features/clubs/domain/club.dart';

void main() {
  test('ClubGame round-trips tableId', () {
    final g = ClubGame.fromMap(const {
      'label': 'NLH 5/10 GEL', 'type': 'NLH', 'tableId': 't1',
      'minBuyIn': 500, 'avgStack': 25000, 'tables': 1, 'openSeats': 3, 'waiting': 2,
    });
    expect(g.tableId, 't1');
    expect(g.openSeats, 3);
    expect(g.waiting, 2);
  });
}
