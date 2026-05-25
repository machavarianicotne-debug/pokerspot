import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/app/router.dart';
import 'package:pokerspot/core/push/push_service.dart';
import 'package:pokerspot/core/theme/app_theme.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';

class PokerSpotApp extends ConsumerWidget {
  const PokerSpotApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Register the Web Push token once the user is signed in (best-effort).
    ref.listen(uidProvider, (prev, next) {
      final uid = next.valueOrNull;
      if (uid != null) {
        unawaited(registerPush(uid, ref.read(usersRepositoryProvider)));
      }
    });
    return MaterialApp.router(
      onGenerateTitle: (context) => AppL10n.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.liquidSport(),
      routerConfig: ref.watch(routerProvider),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
    );
  }
}
