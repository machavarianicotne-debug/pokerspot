import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/features/floor/domain/poker_table.dart';
import 'package:pokerspot/features/floor/domain/stakes.dart';

void main() {
  test('fromMap reads stake fields + parent clubId; toMap excludes id/clubId', () {
    final t = PokerTable.fromMap('t1', 'club1', const {
      'number': 3,
      'variant': 'plo',
      'smallBlind': 1,
      'bigBlind': 2,
      'currency': 'GEL',
      'seatCount': 8,
      'open': true,
    });
    expect(t.id, 't1');
    expect(t.clubId, 'club1');
    expect(t.number, 3);
    expect(t.stakes.variant, GameVariant.plo);
    expect(t.stakes.label, 'PLO 1/2 GEL');
    expect(t.seatCount, 8);
    expect(t.open, isTrue);

    final map = t.toMap();
    expect(map.containsKey('id'), isFalse);
    expect(map.containsKey('clubId'), isFalse);
    expect(map['variant'], 'plo');
    expect(map['number'], 3);
  });

  test('fromMap defaults (seatCount = BusinessRules.maxPlayersPerTable)', () {
    final t = PokerTable.fromMap('t', 'c', const {});
    expect(t.number, 0);
    expect(t.seatCount, 9);
    expect(t.open, isFalse);
    expect(t.stakes.variant, GameVariant.nlh);
  });

  test('== / copyWith', () {
    const s = Stakes(variant: GameVariant.nlh, smallBlind: 1, bigBlind: 2, currency: 'GEL');
    const t = PokerTable(id: 't', clubId: 'c', number: 1, stakes: s, seatCount: 9, open: true);
    expect(t == t.copyWith(number: 2), isFalse);
    expect(t.copyWith(open: false).open, isFalse);
    expect(t, equals(t.copyWith()));
  });

  test('NLH/PLO mixed-game config round-trips through toMap/fromMap', () {
    const s = Stakes(variant: GameVariant.nlhPlo, smallBlind: 1, bigBlind: 2, currency: 'GEL');
    const t = PokerTable(
      id: 't', clubId: 'c', number: 1, stakes: s, seatCount: 9, open: true,
      omahaPerCircle: 2, omahaVariant: GameVariant.plo5,
    );
    final back = PokerTable.fromMap('t', 'c', t.toMap());
    expect(back.stakes.variant, GameVariant.nlhPlo);
    expect(back.omahaPerCircle, 2);
    expect(back.omahaVariant, GameVariant.plo5);
    // Defaults to null when absent (e.g. a plain NLH table).
    final plain = PokerTable.fromMap('t', 'c', const {'variant': 'nlh'});
    expect(plain.omahaPerCircle, isNull);
    expect(plain.omahaVariant, isNull);
  });
}
