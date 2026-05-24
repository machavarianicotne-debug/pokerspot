import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/features/auth/data/fake_auth_repository.dart';
import 'package:pokerspot/features/auth/domain/auth_repository.dart';

void main() {
  test('correct test code signs in; wrong code throws; signOut clears', () async {
    final repo = FakeAuthRepository();
    expect(repo.currentUid, isNull);

    final session = await repo.sendOtp('+995555111111');
    expect(() => repo.confirmOtp(session, '000000'), throwsA(isA<AuthException>()));
    expect(repo.currentUid, isNull);

    await repo.confirmOtp(session, '111111');
    expect(repo.currentUid, isNotNull);

    await repo.signOut();
    expect(repo.currentUid, isNull);
  });

  test('uidChanges stream emits on sign-in and sign-out', () async {
    final repo = FakeAuthRepository();
    final seen = <String?>[];
    final sub = repo.uidChanges().listen(seen.add);
    final s = await repo.sendOtp('+995555222222');
    await repo.confirmOtp(s, '222222');
    await repo.signOut();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await sub.cancel();
    expect(seen.where((e) => e != null), isNotEmpty);
    expect(seen.last, isNull);
  });

  test('sendOtp throws for an unknown number', () async {
    final repo = FakeAuthRepository();
    expect(() => repo.sendOtp('+15555550000'), throwsA(isA<AuthException>()));
  });

  test('confirmOtp sets a deterministic uid derived from the phone', () async {
    final repo = FakeAuthRepository();
    final s = await repo.sendOtp('+995555111111');
    await repo.confirmOtp(s, '111111');
    expect(repo.currentUid, 'fake-111111');
  });

  test('uidChanges replays the current uid to a late subscriber', () async {
    final repo = FakeAuthRepository();
    final s = await repo.sendOtp('+995555333333');
    await repo.confirmOtp(s, '333333');
    // Subscribe AFTER sign-in: should receive the current uid immediately.
    final first = await repo.uidChanges().first;
    expect(first, isNotNull);
    expect(first, repo.currentUid);
  });

  test('all six console test numbers sign in with their codes', () async {
    const pairs = {
      '+995555111111': '111111',
      '+995555222222': '222222',
      '+995555333333': '333333',
      '+995555444444': '444444',
      '+995555555555': '555555',
      '+995555666666': '666666',
    };
    for (final entry in pairs.entries) {
      final repo = FakeAuthRepository();
      final s = await repo.sendOtp(entry.key);
      await repo.confirmOtp(s, entry.value);
      expect(repo.currentUid, isNotNull);
    }
  });
}
