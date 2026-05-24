import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/features/auth/data/fake_auth_repository.dart';
import 'package:pokerspot/features/auth/domain/app_user.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/features/floor/domain/poker_table.dart';
import 'package:pokerspot/features/floor/domain/session.dart';
import 'package:pokerspot/features/floor/domain/stakes.dart';
import 'package:pokerspot/features/floor/domain/waitlist_entry.dart';
import 'package:pokerspot/features/floor/presentation/providers.dart';
import 'package:pokerspot/features/home/presentation/pit_boss_home.dart';

const _stakes = Stakes(variant: GameVariant.nlh, smallBlind: 1, bigBlind: 2, currency: 'GEL');
const _table = PokerTable(
    id: 't1', clubId: 'vake', number: 1, stakes: _stakes, seatCount: 6, open: true);

AppUser _pb({String? clubId}) => AppUser(
      uid: 'pb', phone: '', firstName: 'Pit', lastName: 'Boss',
      role: AppRole.pitboss, lang: 'en', blocked: false, clubId: clubId);

Widget _wrap(List<Override> overrides) => ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(FakeAuthRepository()), ...overrides],
      child: const MaterialApp(
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: PitBossHome(),
      ),
    );

void main() {
  testWidgets('no club assigned -> the Floor shows the message', (tester) async {
    await tester.pumpWidget(_wrap([
      currentUserProvider.overrideWith((ref) => Stream.value(_pb())),
    ]));
    await tester.pumpAndSettle();
    expect(find.text('No club is assigned to your account'), findsOneWidget);
  });

  testWidgets('with a club -> the Floor (table-centric) lists table cards', (tester) async {
    await tester.pumpWidget(_wrap([
      currentUserProvider.overrideWith((ref) => Stream.value(_pb(clubId: 'vake'))),
      tablesProvider('vake').overrideWith((ref) => Stream.value(const [_table])),
      clubSessionsProvider('vake').overrideWith((ref) => Stream.value(const <Session>[])),
      clubWaitlistProvider('vake').overrideWith((ref) => Stream.value(const <WaitlistEntry>[])),
    ]));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tableCard_t1')), findsOneWidget);
    expect(find.byKey(const Key('newGameBtn')), findsOneWidget); // no separate Tables tab
  });
}
