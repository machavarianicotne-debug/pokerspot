import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/features/auth/data/fake_users_repository.dart';
import 'package:pokerspot/features/auth/domain/app_user.dart';

void main() {
  test('createProfile defaults role to player; watchUser emits it', () async {
    final repo = FakeUsersRepository();
    expect(await repo.watchUser('u1').first, isNull);

    await repo.createProfile(uid: 'u1', phone: '+995555222222', displayName: 'Nino', lang: 'ka');
    final u = await repo.watchUser('u1').first;
    expect(u, isNotNull);
    expect(u!.displayName, 'Nino');
    expect(u.role, AppRole.player);
    expect(u.lang, 'ka');
  });

  test('getUser returns null before, the profile after createProfile', () async {
    final repo = FakeUsersRepository();
    expect(await repo.getUser('u2'), isNull);

    await repo.createProfile(uid: 'u2', phone: '+995555333333', displayName: 'Lika', lang: 'ru');
    final u = await repo.getUser('u2');
    expect(u, isNotNull);
    expect(u!.uid, 'u2');
    expect(u.phone, '+995555333333');
    expect(u.role, AppRole.player);
    expect(u.lang, 'ru');
    expect(u.blocked, isFalse);
  });

  test('watchUser pushes the new profile to an existing subscriber', () async {
    final repo = FakeUsersRepository();
    final seen = <AppUser?>[];
    final sub = repo.watchUser('u3').listen(seen.add);
    // Let the stream emit its initial (null) value and subscribe to the source.
    await Future<void>.delayed(const Duration(milliseconds: 5));

    await repo.createProfile(uid: 'u3', phone: '+995555444444', displayName: 'Dato', lang: 'en');
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await sub.cancel();

    expect(seen.first, isNull);
    expect(seen.last?.displayName, 'Dato');
  });
}
