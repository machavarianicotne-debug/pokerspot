import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/features/clubs/domain/club.dart';

void main() {
  test('fromMap builds a Club; toMap round-trips (id excluded from map)', () {
    const c = Club(
      id: 'c1',
      name: 'PokerSpot Vake',
      city: 'Tbilisi',
      address: 'Chavchavadze Ave 47',
      photoUrl: null,
      hoursText: 'Daily 14:00–04:00',
      phone: '+995 32 200 0000',
      enabled: true,
    );
    final map = c.toMap();
    expect(map.containsKey('id'), isFalse);
    final back = Club.fromMap('c1', map);
    expect(back, equals(c));
    expect(back.name, 'PokerSpot Vake');
    expect(back.photoUrl, isNull);
    expect(back.enabled, isTrue);
  });

  test('fromMap applies defaults for missing fields', () {
    final c = Club.fromMap('c2', const {});
    expect(c.id, 'c2');
    expect(c.name, '');
    expect(c.city, '');
    expect(c.address, '');
    expect(c.photoUrl, isNull);
    expect(c.hoursText, '');
    expect(c.phone, '');
    expect(c.enabled, isFalse);
  });

  test('fromMap reads a non-null photoUrl', () {
    final c = Club.fromMap('c3', const {'photoUrl': 'https://x/y.jpg'});
    expect(c.photoUrl, 'https://x/y.jpg');
  });

  test('== is value equality and hashCode matches for equal clubs', () {
    const a = Club(
        id: 'c', name: 'N', city: 'T', address: 'A', photoUrl: null,
        hoursText: 'H', phone: 'P', enabled: true);
    const b = Club(
        id: 'c', name: 'N', city: 'T', address: 'A', photoUrl: null,
        hoursText: 'H', phone: 'P', enabled: true);
    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
  });

  test('== distinguishes clubs that differ in any field', () {
    const base = Club(
        id: 'c', name: 'N', city: 'T', address: 'A', photoUrl: null,
        hoursText: 'H', phone: 'P', enabled: true);
    expect(base == base.copyWith(id: 'other'), isFalse);
    expect(base == base.copyWith(name: 'X'), isFalse);
    expect(base == base.copyWith(city: 'Batumi'), isFalse);
    expect(base == base.copyWith(address: 'B'), isFalse);
    expect(base == base.copyWith(photoUrl: 'u'), isFalse);
    expect(base == base.copyWith(hoursText: 'HH'), isFalse);
    expect(base == base.copyWith(phone: 'PP'), isFalse);
    expect(base == base.copyWith(enabled: false), isFalse);
  });

  test('copyWith overrides only the given fields', () {
    const base = Club(
        id: 'c', name: 'N', city: 'T', address: 'A', photoUrl: null,
        hoursText: 'H', phone: 'P', enabled: true);
    final changed = base.copyWith(name: 'New', enabled: false);
    expect(changed.name, 'New');
    expect(changed.enabled, isFalse);
    expect(changed.id, 'c');
    expect(changed.city, 'T');
    expect(changed.address, 'A');
    expect(changed.hoursText, 'H');
    expect(changed.phone, 'P');
  });
}
