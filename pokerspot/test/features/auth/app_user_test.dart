import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/features/auth/domain/app_user.dart';

void main() {
  test('role parses snake_case (canonical) AND legacy enum-name strings', () {
    // Canonical snake_case (what Firestore + the Super Admin UI now store).
    expect(AppRole.fromString('super_admin'), AppRole.superadmin);
    expect(AppRole.fromString('pit_boss'), AppRole.pitboss);
    expect(AppRole.fromString('player'), AppRole.player);
    // Legacy enum-name form still accepted.
    expect(AppRole.fromString('superadmin'), AppRole.superadmin);
    expect(AppRole.fromString('pitboss'), AppRole.pitboss);
    // Unknown / null -> player (safe default).
    expect(AppRole.fromString('garbage'), AppRole.player);
    expect(AppRole.fromString(null), AppRole.player);
  });

  test('asString writes canonical snake_case + round-trips back', () {
    expect(AppRole.superadmin.asString, 'super_admin');
    expect(AppRole.pitboss.asString, 'pit_boss');
    expect(AppRole.player.asString, 'player');
    for (final r in AppRole.values) {
      expect(AppRole.fromString(r.asString), r);
    }
  });

  test('fromMap builds an AppUser', () {
    final u = AppUser.fromMap('uid1', {
      'phone': '+995555111111',
      'firstName': 'Sandro',
      'lastName': 'Beridze',
      'role': 'superadmin',
      'lang': 'ka',
      'blocked': false,
      'clubId': 'club-vake',
    });
    expect(u.uid, 'uid1');
    expect(u.firstName, 'Sandro');
    expect(u.lastName, 'Beridze');
    expect(u.role, AppRole.superadmin);
    expect(u.lang, 'ka');
    expect(u.blocked, isFalse);
    expect(u.clubId, 'club-vake');
  });

  test('fromMap defaults missing fields (incl. legacy docs without names)', () {
    final u = AppUser.fromMap('uid2', const {});
    expect(u.phone, '');
    expect(u.firstName, '');
    expect(u.lastName, '');
    expect(u.role, AppRole.player);
    expect(u.lang, 'en');
    expect(u.blocked, isFalse);
    expect(u.clubId, isNull); // legacy users have no club assignment
  });

  test('toMap round-trips', () {
    const u = AppUser(
        uid: 'x',
        phone: '+995555222222',
        firstName: 'Nino',
        lastName: 'Kapanadze',
        role: AppRole.player,
        lang: 'en',
        blocked: false);
    final back = AppUser.fromMap('x', u.toMap());
    expect(back.firstName, 'Nino');
    expect(back.lastName, 'Kapanadze');
    expect(back.role, AppRole.player);
  });

  test('== is value equality and hashCode matches for equal users', () {
    const a = AppUser(
        uid: 'u',
        phone: '+9955551',
        firstName: 'A',
        lastName: 'B',
        role: AppRole.pitboss,
        lang: 'ru',
        blocked: false);
    const b = AppUser(
        uid: 'u',
        phone: '+9955551',
        firstName: 'A',
        lastName: 'B',
        role: AppRole.pitboss,
        lang: 'ru',
        blocked: false);
    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
  });

  test('== distinguishes users that differ in any field', () {
    const base = AppUser(
        uid: 'u',
        phone: '+9955551',
        firstName: 'A',
        lastName: 'B',
        role: AppRole.player,
        lang: 'en',
        blocked: false);
    expect(base == base.copyWith(uid: 'other'), isFalse);
    expect(base == base.copyWith(phone: '+9955559'), isFalse);
    expect(base == base.copyWith(firstName: 'X'), isFalse);
    expect(base == base.copyWith(lastName: 'Y'), isFalse);
    expect(base == base.copyWith(role: AppRole.superadmin), isFalse);
    expect(base == base.copyWith(lang: 'ka'), isFalse);
    expect(base == base.copyWith(blocked: true), isFalse);
    expect(base == base.copyWith(clubId: 'club-1'), isFalse);
  });

  test('copyWith overrides only the given fields', () {
    const base = AppUser(
        uid: 'u',
        phone: '+9955551',
        firstName: 'A',
        lastName: 'B',
        role: AppRole.player,
        lang: 'en',
        blocked: false);
    final changed = base.copyWith(firstName: 'X', role: AppRole.superadmin);
    expect(changed.firstName, 'X');
    expect(changed.lastName, 'B');
    expect(changed.role, AppRole.superadmin);
    expect(changed.uid, 'u');
    expect(changed.phone, '+9955551');
    expect(changed.lang, 'en');
    expect(changed.blocked, isFalse);
  });
}
