import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pokerspot/features/auth/domain/auth_repository.dart';

/// Firebase-backed auth.
///
/// Phone sign-in differs by platform:
/// - **Web**: `signInWithPhoneNumber` (shows reCAPTCHA, returns a
///   ConfirmationResult).
/// - **iOS/Android**: `verifyPhoneNumber` (APNs / SafetyNet verification).
///   `signInWithPhoneNumber` is NOT supported natively — it throws
///   "RecaptchaVerifier is not implemented".
///
/// [OtpSession.handle] therefore holds a ConfirmationResult on web and the
/// verificationId [String] on mobile; [confirmOtp] branches on the same.
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
      if (kIsWeb) {
        final confirmation = await _auth.signInWithPhoneNumber(phone);
        return OtpSession(confirmation);
      }
      // Native (iOS/Android): verifyPhoneNumber + manual code entry.
      final completer = Completer<OtpSession>();
      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (_) {
          // Android auto-retrieval — ignored; the user enters the code manually.
        },
        verificationFailed: (e) {
          if (!completer.isCompleted) {
            completer.completeError(AuthException('${e.code}: ${e.message ?? ''}'));
          }
        },
        codeSent: (verificationId, _) {
          if (!completer.isCompleted) completer.complete(OtpSession(verificationId));
        },
        codeAutoRetrievalTimeout: (_) {},
      );
      return completer.future;
    } on FirebaseAuthException catch (e) {
      throw AuthException('${e.code}: ${e.message ?? ''}');
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<void> confirmOtp(OtpSession session, String smsCode) async {
    try {
      if (kIsWeb) {
        await (session.handle as ConfirmationResult).confirm(smsCode);
        return;
      }
      final credential = PhoneAuthProvider.credential(
        verificationId: session.handle as String,
        smsCode: smsCode,
      );
      await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw AuthException('${e.code}: ${e.message ?? ''}');
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
