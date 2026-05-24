import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/features/admin/domain/audit_entry.dart';
import 'package:pokerspot/features/admin/presentation/providers.dart';
import 'package:pokerspot/features/auth/domain/app_user.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/features/clubs/domain/club.dart';
import 'package:pokerspot/features/clubs/presentation/providers.dart';
import 'package:pokerspot/features/floor/domain/reservation.dart';
import 'package:pokerspot/features/floor/domain/session.dart';
import 'package:pokerspot/features/floor/domain/waitlist_entry.dart';
import 'package:pokerspot/features/floor/presentation/providers.dart';
import 'package:pokerspot/features/home/presentation/pit_boss_home.dart';
import 'package:pokerspot/features/home/presentation/player_home.dart';
import 'package:pokerspot/features/home/presentation/role_home.dart';
import 'package:pokerspot/features/home/presentation/super_admin_home.dart';

/// Builds the user from a raw Firestore map (proves the role-STRING -> enum ->
/// route chain), then pumps RoleHome with all downstream streams stubbed empty.
Future<void> _pumpForRole(WidgetTester tester, String roleString) async {
  final user = AppUser.fromMap('uid', {
    'phone': '+995555111111',
    'firstName': 'Sandro',
    'lastName': 'B',
    'role': roleString,
    'lang': 'en',
    'blocked': false,
    // clubId null so the Pit Boss tabs short-circuit (no floor reads).
  });
  await tester.pumpWidget(ProviderScope(
    overrides: [
      currentUserProvider.overrideWith((ref) => Stream.value(user)),
      clubsListProvider.overrideWith((ref) => Stream.value(const <Club>[])),
      allClubsProvider.overrideWith((ref) => Stream.value(const <Club>[])),
      allUsersProvider.overrideWith((ref) => Stream.value(<AppUser>[user])),
      recentAuditProvider.overrideWith((ref) => Stream.value(const <AuditEntry>[])),
      myWaitlistProvider.overrideWith((ref) => Stream.value(const <WaitlistEntry>[])),
      mySessionProvider.overrideWith((ref) => Stream.value(const <Session>[])),
      myReservationsProvider.overrideWith((ref) => Stream.value(const <Reservation>[])),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      home: RoleHome(),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets("role 'super_admin' routes to SuperAdminHome", (tester) async {
    await _pumpForRole(tester, 'super_admin');
    expect(find.byType(SuperAdminHome), findsOneWidget);
    expect(find.byType(PlayerHome), findsNothing);
  });

  testWidgets("role 'pit_boss' routes to PitBossHome", (tester) async {
    await _pumpForRole(tester, 'pit_boss');
    expect(find.byType(PitBossHome), findsOneWidget);
    expect(find.byType(PlayerHome), findsNothing);
  });

  testWidgets("role 'player' routes to PlayerHome", (tester) async {
    await _pumpForRole(tester, 'player');
    expect(find.byType(PlayerHome), findsOneWidget);
    expect(find.byType(SuperAdminHome), findsNothing);
  });
}
