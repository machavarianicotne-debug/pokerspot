import 'dart:async';

import 'package:pokerspot/features/auth/domain/auth_repository.dart';

/// In-memory [AuthRepository] for tests + offline UI work. Mirrors the six
/// Firebase Console test phone numbers so widget tests can "log in" without a
/// live backend. No Firebase imports.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({Map<String, String>? testCodes})
      : _codes = testCodes ??
            const {
              '+995555111111': '111111',
              '+995555222222': '222222',
              '+995555333333': '333333',
              '+995555444444': '444444',
              '+995555555555': '555555',
              '+995555666666': '666666',
            };

  final Map<String, String> _codes;
  final StreamController<String?> _controller =
      StreamController<String?>.broadcast();
  String? _uid;

  static String _normalize(String phone) => phone.replaceAll(RegExp(r'\s'), '');

  @override
  String? get currentUid => _uid;

  /// Replays the current uid to each new subscriber, then forwards live
  /// changes. Backed by a broadcast controller so any number of independent
  /// subscriptions work; the source listen happens synchronously in [onListen]
  /// so no change emitted right after subscribing is dropped.
  @override
  Stream<String?> uidChanges() {
    final out = StreamController<String?>();
    StreamSubscription<String?>? source;
    out.onListen = () {
      out.add(_uid);
      source = _controller.stream.listen(out.add, onError: out.addError);
    };
    out.onCancel = () async {
      await source?.cancel();
    };
    return out.stream;
  }

  @override
  Future<OtpSession> sendOtp(String phoneE164) async {
    final phone = _normalize(phoneE164);
    if (!_codes.containsKey(phone)) {
      throw const AuthException('unknown test number');
    }
    return OtpSession(phone);
  }

  @override
  Future<void> confirmOtp(OtpSession session, String smsCode) async {
    final phone = session.handle as String;
    final expected = _codes[phone];
    if (expected == null || expected != smsCode) {
      throw const AuthException('invalid code');
    }
    _uid = 'fake-${phone.substring(phone.length - 6)}';
    _controller.add(_uid);
  }

  @override
  Future<void> signOut() async {
    _uid = null;
    _controller.add(null);
  }
}
