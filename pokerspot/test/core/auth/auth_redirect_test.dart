import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/core/auth/auth_redirect.dart';

void main() {
  test('signed out → /login (unless already there)', () {
    expect(authRedirect(uid: null, hasProfile: false, location: '/home'), '/login');
    expect(authRedirect(uid: null, hasProfile: false, location: '/login'), isNull);
  });

  test('signed in, no profile → /onboarding (unless already there)', () {
    expect(authRedirect(uid: 'u', hasProfile: false, location: '/login'), '/onboarding');
    expect(authRedirect(uid: 'u', hasProfile: false, location: '/onboarding'), isNull);
  });

  test('signed in with profile → /home from auth pages, else stay', () {
    expect(authRedirect(uid: 'u', hasProfile: true, location: '/login'), '/home');
    expect(authRedirect(uid: 'u', hasProfile: true, location: '/onboarding'), '/home');
    expect(authRedirect(uid: 'u', hasProfile: true, location: '/home'), isNull);
  });
}
