import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/features/floor/domain/stakes.dart';

void main() {
  test('GameVariant parses + labels + defaults to nlh', () {
    expect(GameVariant.fromString('plo5'), GameVariant.plo5);
    expect(GameVariant.fromString('plo6'), GameVariant.plo6);
    expect(GameVariant.fromString('garbage'), GameVariant.nlh);
    expect(GameVariant.fromString(null), GameVariant.nlh);
    expect(GameVariant.nlh.label, 'NLH');
    expect(GameVariant.plo6.label, 'PLO6');
    expect(GameVariant.plo5.asString, 'plo5');
  });

  test('Stakes label formats whole + fractional blinds', () {
    const a = Stakes(variant: GameVariant.nlh, smallBlind: 1, bigBlind: 2, currency: 'GEL');
    expect(a.label, 'NLH 1/2 GEL');
    const b = Stakes(variant: GameVariant.plo, smallBlind: 0.5, bigBlind: 1, currency: 'USD');
    expect(b.label, 'PLO 0.5/1 USD');
  });

  test('fromMap/toMap round-trips; currency defaults to GEL', () {
    const s = Stakes(variant: GameVariant.plo5, smallBlind: 2, bigBlind: 5, currency: 'EUR');
    expect(Stakes.fromMap(s.toMap()), equals(s));
    final def = Stakes.fromMap(const {'variant': 'nlh', 'smallBlind': 1, 'bigBlind': 2});
    expect(def.currency, 'GEL');
  });

  test('== / hashCode / copyWith', () {
    const s = Stakes(variant: GameVariant.nlh, smallBlind: 1, bigBlind: 2, currency: 'GEL');
    expect(s.copyWith(bigBlind: 3).bigBlind, 3);
    expect(s == s.copyWith(currency: 'USD'), isFalse);
    expect(s.hashCode, equals(s.copyWith().hashCode));
  });
}
