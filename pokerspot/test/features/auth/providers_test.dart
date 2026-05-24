import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/features/auth/data/fake_auth_repository.dart';
import 'package:pokerspot/features/auth/data/fake_users_repository.dart';
import 'package:pokerspot/features/auth/domain/app_user.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';

void main() {
  test('currentUserProvider follows auth + profile', () async {
    final auth = FakeAuthRepository();
    final users = FakeUsersRepository();
    final container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      usersRepositoryProvider.overrideWithValue(users),
    ]);
    addTearDown(container.dispose);

    // sign in
    final s = await auth.sendOtp('+995555222222');
    await auth.confirmOtp(s, '222222');
    final uid = auth.currentUid!;

    // Keep currentUserProvider active so it subscribes to the auth + users
    // streams (like the UI would). We read state after letting microtasks
    // settle, rather than awaiting `.future`, which hangs when the provider
    // rebuilds (uid: loading -> data) while still in its initial loading state.
    final sub = container.listen(currentUserProvider, (_, __) {});
    addTearDown(sub.close);

    // no profile yet
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(container.read(currentUserProvider).valueOrNull, isNull);

    // create profile
    await users.createProfile(
        uid: uid, phone: '+995555222222', firstName: 'Nino', lastName: 'Kapanadze', lang: 'en');
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(container.read(currentUserProvider).valueOrNull?.role, AppRole.player);
  });
}
