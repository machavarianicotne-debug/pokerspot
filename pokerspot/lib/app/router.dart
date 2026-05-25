import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pokerspot/core/auth/auth_redirect.dart';
import 'package:pokerspot/features/auth/presentation/login_screen.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/features/clubs/presentation/club_details_screen.dart';
import 'package:pokerspot/features/home/presentation/role_home.dart';
import 'package:pokerspot/features/onboarding/presentation/onboarding_screen.dart';

/// Notifies GoRouter when auth or profile state changes.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    ref.listen(uidProvider, (_, __) => notifyListeners());
    ref.listen(currentUserProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh(ref);
  ref.onDispose(refresh.dispose);
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refresh,
    redirect: (context, state) {
      final uid = ref.read(uidProvider).valueOrNull;
      final profile = ref.read(currentUserProvider);
      // Once signed in, wait for the profile to load before choosing onboarding
      // vs home — otherwise a registered user briefly sees the name form.
      final profileResolved = uid == null || !profile.isLoading;
      return authRedirect(
        uid: uid,
        hasProfile: profile.valueOrNull != null,
        location: state.matchedLocation,
        profileResolved: profileResolved,
      );
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/home', builder: (_, __) => const RoleHome()),
      GoRoute(
          path: '/home/club/:id',
          builder: (ctx, state) =>
              ClubDetailsScreen(clubId: state.pathParameters['id']!)),
    ],
  );
});
