import 'package:go_router/go_router.dart';
import 'package:pokerspot/features/home/presentation/home_screen.dart';

/// Minimal router. Plan 2 replaces home with the auth gate + role-based shell.
final appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
  ],
);
