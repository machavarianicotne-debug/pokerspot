import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/features/auth/domain/app_user.dart';

void main() {
  test('role parses from string, defaults to player', () {
    expect(AppRole.fromString('superadmin'), AppRole.superadmin);
    expect(AppRole.fromString('pitboss'), AppRole.pitboss);
    expect(AppRole.fromString('player'), AppRole.player);
    expect(AppRole.fromString('garbage'), AppRole.player);
    expect(AppRole.fromString(null), AppRole.player);
  });

  test('fromMap builds an AppUser', () {
    final u = AppUser.fromMap('uid1', {
      'phone': '+995555111111',
      'displayName': 'Sandro',
      'role': 'superadmin',
      'lang': 'ka',
      'blocked': false,
    });
    expect(u.uid, 'uid1');
    expect(u.displayName, 'Sandro');
    expect(u.role, AppRole.superadmin);
    expect(u.lang, 'ka');
    expect(u.blocked, isFalse);
  });

  test('fromMap applies defaults for missing fields', () {
    final u = AppUser.fromMap('uid2', const {});
    expect(u.phone, '');
    expect(u.displayName, '');
    expect(u.role, AppRole.player);
    expect(u.lang, 'en');
    expect(u.blocked, isFalse);
  });

  test('toMap round-trips', () {
    const u = AppUser(
        uid: 'x',
        phone: '+995555222222',
        displayName: 'Nino',
        role: AppRole.player,
        lang: 'en',
        blocked: false);
    final back = AppUser.fromMap('x', u.toMap());
    expect(back.displayName, 'Nino');
    expect(back.role, AppRole.player);
  });

  test('== is value equality and hashCode matches for equal users', () {
    const a = AppUser(
        uid: 'u',
        phone: '+9955551',
        displayName: 'A',
        role: AppRole.pitboss,
        lang: 'ru',
        blocked: false);
    const b = AppUser(
        uid: 'u',
        phone: '+9955551',
        displayName: 'A',
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
        displayName: 'A',
        role: AppRole.player,
        lang: 'en',
        blocked: false);
    expect(base == base.copyWith(uid: 'other'), isFalse);
    expect(base == base.copyWith(phone: '+9955559'), isFalse);
    expect(base == base.copyWith(displayName: 'B'), isFalse);
    expect(base == base.copyWith(role: AppRole.superadmin), isFalse);
    expect(base == base.copyWith(lang: 'ka'), isFalse);
    expect(base == base.copyWith(blocked: true), isFalse);
  });

  test('copyWith overrides only the given fields', () {
    const base = AppUser(
        uid: 'u',
        phone: '+9955551',
        displayName: 'A',
        role: AppRole.player,
        lang: 'en',
        blocked: false);
    final changed = base.copyWith(displayName: 'B', role: AppRole.superadmin);
    expect(changed.displayName, 'B');
    expect(changed.role, AppRole.superadmin);
    expect(changed.uid, 'u');
    expect(changed.phone, '+9955551');
    expect(changed.lang, 'en');
    expect(changed.blocked, isFalse);
  });
}
