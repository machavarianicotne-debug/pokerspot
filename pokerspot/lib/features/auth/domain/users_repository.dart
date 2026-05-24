import 'package:pokerspot/features/auth/domain/app_user.dart';

abstract interface class UsersRepository {
  /// Live user doc (null until the profile exists).
  Stream<AppUser?> watchUser(String uid);

  /// One-shot read.
  Future<AppUser?> getUser(String uid);

  /// Create the profile on first onboarding. Role defaults to player.
  Future<void> createProfile({
    required String uid,
    required String phone,
    required String displayName,
    required String lang,
  });
}
