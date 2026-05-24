import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/features/auth/domain/app_user.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/features/floor/domain/session.dart';
import 'package:pokerspot/features/floor/domain/stakes.dart';
import 'package:pokerspot/features/floor/presentation/providers.dart';
import 'package:pokerspot/features/home/presentation/pit_boss_settings_screen.dart';
import 'package:pokerspot/features/home/presentation/pit_boss_stats_screen.dart';

const _stakes = Stakes(variant: GameVariant.nlh, smallBlind: 1, bigBlind: 2, currency: 'GEL');

AppUser _pb() => const AppUser(
    uid: 'pb', phone: '', firstName: 'Pit', lastName: 'Boss',
    role: AppRole.pitboss, lang: 'en', blocked: false, clubId: 'vake');

Session _session(String uid, String name, int agoMin) => Session(
    id: 's_$uid', clubId: 'vake', tableId: 't1', seatNumber: 1, playerUid: uid,
    playerName: name, stakes: _stakes, status: SessionStatus.ended,
    startedAt: DateTime.now().subtract(Duration(minutes: agoMin)), endedAt: DateTime.now());

Widget _wrap(Widget home, List<Override> overrides) => ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: Scaffold(body: home),
      ),
    );

void main() {
  testWidgets('Stats leaderboard lists registered players with hours', (tester) async {
    await tester.pumpWidget(_wrap(const PitBossStatsScreen(), [
      currentUserProvider.overrideWith((ref) => Stream.value(_pb())),
      clubSessionsAllProvider('vake')
          .overrideWith((ref) => Stream.value([_session('u1', 'Nino K', 120)])),
    ]));
    await tester.pumpAndSettle();
    expect(find.text('Registered'), findsOneWidget); // segment
    expect(find.text('Nino K'), findsOneWidget);
    expect(find.text('2.0h'), findsOneWidget); // 120 min
  });

  testWidgets('Settings shows availability + notifications + sign-out', (tester) async {
    await tester.pumpWidget(_wrap(const PitBossSettingsScreen(), [
      currentUserProvider.overrideWith((ref) => Stream.value(_pb())),
    ]));
    await tester.pumpAndSettle();
    expect(find.text('Available for chat'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
    expect(find.text('Online'), findsOneWidget); // availability pill (toggle on)
    expect(find.text('New chat message'), findsOneWidget); // one of the 5 notif rows
    await tester.scrollUntilVisible(find.byKey(const Key('signOutBtn')), 300,
        scrollable: find.byType(Scrollable).first);
    expect(find.byKey(const Key('signOutBtn')), findsOneWidget);
  });
}
