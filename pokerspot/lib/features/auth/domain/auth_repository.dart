// Auth domain interface (spec §12). Pure Dart — no Firebase imports.
// Concrete FakeAuthRepository / FirebaseAuthRepository implementations live
// in a later task; this file defines only the contract + helper types.

/// Thrown when OTP verification fails.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => 'AuthException: $message';
}

/// Opaque handle returned by sendOtp, passed back to confirmOtp.
class OtpSession {
  final Object handle;
  const OtpSession(this.handle);
}

abstract interface class AuthRepository {
  /// Emits the current user's uid, or null when signed out.
  Stream<String?> uidChanges();

  /// The current uid synchronously (null if signed out).
  String? get currentUid;

  /// Start phone sign-in (web: triggers reCAPTCHA + SMS). Returns a session.
  Future<OtpSession> sendOtp(String phoneE164);

  /// Confirm the SMS code for a session. Throws [AuthException] on failure.
  Future<void> confirmOtp(OtpSession session, String smsCode);

  Future<void> signOut();
}
