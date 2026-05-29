import 'package:firebase_auth/firebase_auth.dart';
import 'package:pokerspot/features/auth/domain/auth_repository.dart';

/// Firebase-backed auth. Uses signInWithPhoneNumber, which on web shows the
/// reCAPTCHA flow and returns a ConfirmationResult (the same backend as native).
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);
  final FirebaseAuth _auth;

  @override
  String? get currentUid => _auth.currentUser?.uid;

  @override
  String? get currentPhone => _auth.currentUser?.phoneNumber;

  @override
  Stream<String?> uidChanges() => _auth.authStateChanges().map((u) => u?.uid);

  @override
  Future<OtpSession> sendOtp(String phoneE164) async {
    final phone = phoneE164.replaceAll(RegExp(r'\s'), '');
    try {
      final confirmation = await _auth.signInWithPhoneNumber(phone);
      return OtpSession(confirmation);
    } on FirebaseAuthException catch (e) {
      throw AuthException('${e.code}: ${e.message ?? ''}');
    } catch (e) {
      // Surface non-FirebaseAuthException errors (e.g. iOS APNs/reCAPTCHA setup
      // issues) instead of silently failing with no UI reaction.
      throw AuthException(e.toString());
    }
  }

  @override
  Future<void> confirmOtp(OtpSession session, String smsCode) async {
    try {
      await (session.handle as ConfirmationResult).confirm(smsCode);
    } on FirebaseAuthException catch (e) {
      throw AuthException('${e.code}: ${e.message ?? ''}');
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
