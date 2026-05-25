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
    required String firstName,
    required String lastName,
    required String lang,
  });

  /// Live list of ALL users (Super Admin search/management).
  Stream<List<AppUser>> watchAllUsers();

  /// Set a user's role (promote/demote).
  Future<void> updateRole(String uid, AppRole role);

  /// Block / unblock a user.
  Future<void> setBlocked(String uid, bool blocked);

  /// Assign (or clear, when null) the club a Pit Boss staffs.
  Future<void> assignClub(String uid, String? clubId);

  /// Register a Web Push (FCM) token for this user (read by notifyCalled).
  Future<void> addFcmToken(String uid, String token);
}
