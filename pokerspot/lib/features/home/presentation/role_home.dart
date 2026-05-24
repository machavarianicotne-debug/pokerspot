import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/auth/domain/app_user.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/features/home/presentation/player_home.dart';
import 'package:pokerspot/features/home/presentation/pit_boss_home.dart';
import 'package:pokerspot/features/home/presentation/super_admin_home.dart';

/// Routes to the role-specific home based on the current profile.
class RoleHome extends ConsumerWidget {
  const RoleHome({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    switch (user?.role) {
      case AppRole.superadmin:
        return const SuperAdminHome();
      case AppRole.pitboss:
        return const PitBossHome();
      case AppRole.player:
        return const PlayerHome();
      case null:
        return const Scaffold(
            backgroundColor: PsColors.bg0,
            body: Center(child: CircularProgressIndicator()));
    }
  }
}
