import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/features/admin/domain/audit_entry.dart';
import 'package:pokerspot/features/admin/presentation/admin_assign_pitboss_screen.dart';
import 'package:pokerspot/features/admin/presentation/admin_clubs_screen.dart';
import 'package:pokerspot/features/admin/presentation/admin_overview_screen.dart';
import 'package:pokerspot/features/admin/presentation/admin_users_screen.dart';
import 'package:pokerspot/features/admin/presentation/providers.dart';
import 'package:pokerspot/features/auth/domain/app_user.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/features/clubs/domain/club.dart';
import 'package:pokerspot/features/clubs/presentation/providers.dart';

const _vake = Club(
    id: 'c1', name: 'Vake', city: 'Tbilisi', address: 'A', photoUrl: null,
    hoursText: 'H', phone: 'P', enabled: true);
const _batumi = Club(
    id: 'c2', name: 'Batumi Royal', city: 'Adjara', address: 'A', photoUrl: null,
    hoursText: 'H', phone: 'P', enabled: false);

AppUser _admin() => const AppUser(
    uid: 'a', phone: '', firstName: 'Super', lastName: 'Admin',
    role: AppRole.superadmin, lang: 'en', blocked: false);
AppUser _player() => const AppUser(
    uid: 'u1', phone: '+995555111111', firstName: 'Nino', lastName: 'K',
    role: AppRole.player, lang: 'en', blocked: false);
AppUser _pitboss() => const AppUser(
    uid: 'pb1', phone: '+995555333333', firstName: 'Giorgi', lastName: 'M',
    role: AppRole.pitboss, lang: 'en', blocked: false, clubId: 'c1');

Widget _wrap(Widget home, List<Override> overrides) => ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: Scaffold(body: home),
      ),
    );

void main() {
  testWidgets('AdminClubsScreen lists all clubs (incl disabled) + New club', (tester) async {
    await tester.pumpWidget(_wrap(const AdminClubsScreen(), [
      currentUserProvider.overrideWith((ref) => Stream.value(_admin())),
      allClubsProvider.overrideWith((ref) => Stream.value(const [_vake, _batumi])),
    ]));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('newClubBtn')), findsOneWidget);
    expect(find.byKey(const Key('adminClubCard_c1')), findsOneWidget);
    expect(find.byKey(const Key('adminClubCard_c2')), findsOneWidget);
    expect(find.text('Vake'), findsOneWidget);
    expect(find.text('Batumi Royal'), findsOneWidget);
  });

  testWidgets('AdminUsersScreen lists users + filters by search query', (tester) async {
    await tester.pumpWidget(_wrap(const AdminUsersScreen(), [
      currentUserProvider.overrideWith((ref) => Stream.value(_admin())),
      allUsersProvider.overrideWith((ref) => Stream.value([_player()])),
    ]));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('userSearch')), findsOneWidget);
    expect(find.byKey(const Key('userCard_u1')), findsOneWidget);
    expect(find.text('Nino K'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('userCard_u1')), findsNothing); // filtered out
  });

  testWidgets('AdminAssignPitBossScreen lists active assignments + assign form', (tester) async {
    await tester.pumpWidget(_wrap(const AdminAssignPitBossScreen(), [
      currentUserProvider.overrideWith((ref) => Stream.value(_admin())),
      allClubsProvider.overrideWith((ref) => Stream.value(const [_vake, _batumi])),
      allUsersProvider.overrideWith((ref) => Stream.value([_pitboss(), _player()])),
    ]));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pb_pb1')), findsOneWidget); // active assignment
    expect(find.text('Giorgi M'), findsOneWidget);
    expect(find.byKey(const Key('assignPbBtn')), findsOneWidget);
  });

  testWidgets('AdminOverviewScreen shows aggregate metrics', (tester) async {
    await tester.pumpWidget(_wrap(const AdminOverviewScreen(), [
      allClubsProvider.overrideWith((ref) => Stream.value(const [_vake, _batumi])),
      allUsersProvider.overrideWith((ref) => Stream.value([_player(), _admin()])),
      recentAuditProvider.overrideWith((ref) => Stream.value(const <AuditEntry>[])),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('2'), findsWidgets); // 2 clubs / 2 users
    expect(find.text('1'), findsOneWidget); // 1 enabled club
  });
}
