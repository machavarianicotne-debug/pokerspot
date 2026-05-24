import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/features/auth/domain/app_user.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/features/floor/domain/poker_table.dart';
import 'package:pokerspot/features/floor/domain/session.dart';
import 'package:pokerspot/features/floor/domain/stakes.dart';
import 'package:pokerspot/features/floor/domain/waitlist_entry.dart';
import 'package:pokerspot/features/floor/presentation/providers.dart';
import 'package:pokerspot/features/floor/presentation/new_game_screen.dart';
import 'package:pokerspot/features/floor/presentation/table_detail_screen.dart';
import 'package:pokerspot/features/floor/presentation/tables_screen.dart';
import 'package:pokerspot/shared/widgets/ps_seat_map.dart';
import 'package:pokerspot/shared/widgets/ps_stepper.dart';

const _stakes = Stakes(variant: GameVariant.nlh, smallBlind: 1, bigBlind: 2, currency: 'GEL');
const _table = PokerTable(
    id: 't1', clubId: 'vake', number: 1, stakes: _stakes, seatCount: 9, open: true);

AppUser _pb() => const AppUser(
    uid: 'pb', phone: '', firstName: 'Pit', lastName: 'Boss',
    role: AppRole.pitboss, lang: 'en', blocked: false, clubId: 'vake');

Session _session(int seat) => Session(
    id: 's$seat', clubId: 'vake', tableId: 't1', seatNumber: seat, playerUid: 'u',
    playerName: 'Nino K', stakes: _stakes, status: SessionStatus.active,
    startedAt: DateTime.now(), endedAt: null);

Widget _wrap(Widget home, List<Override> overrides) => ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: home,
      ),
    );

void main() {
  testWidgets('TablesScreen lists the club tables with occupancy + New table', (tester) async {
    await tester.pumpWidget(_wrap(const Scaffold(body: TablesScreen()), [
      currentUserProvider.overrideWith((ref) => Stream.value(_pb())),
      tablesProvider('vake').overrideWith((ref) => Stream.value(const [_table])),
      clubSessionsProvider('vake').overrideWith((ref) => Stream.value([_session(3)])),
    ]));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('newTableBtn')), findsOneWidget);
    expect(find.byKey(const Key('tableCard_t1')), findsOneWidget);
    expect(find.text('Table 1'), findsOneWidget);
    expect(find.text('NLH 1/2 GEL'), findsOneWidget);
    expect(find.text('1/9'), findsOneWidget); // one seat occupied of nine
  });

  testWidgets('NewGameScreen renders type/blinds/currency/tables controls', (tester) async {
    await tester.pumpWidget(_wrap(const NewGameScreen(clubId: 'vake'), [
      tablesProvider('vake').overrideWith((ref) => Stream.value(const <PokerTable>[])),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('NLH'), findsOneWidget); // type segment
    expect(find.text('GEL'), findsOneWidget); // currency segment
    expect(find.byType(PsStepper), findsOneWidget); // tables count
    expect(find.text('1/3'), findsOneWidget); // a blind preset pill
    // openGameBtn lives below the ListView fold (lazy-built) — scroll to it.
    await tester.scrollUntilVisible(find.byKey(const Key('openGameBtn')), 300,
        scrollable: find.byType(Scrollable).first);
    expect(find.byKey(const Key('openGameBtn')), findsOneWidget);
  });

  testWidgets('TablesScreen shows the empty state with no tables', (tester) async {
    await tester.pumpWidget(_wrap(const Scaffold(body: TablesScreen()), [
      currentUserProvider.overrideWith((ref) => Stream.value(_pb())),
      tablesProvider('vake').overrideWith((ref) => Stream.value(const <PokerTable>[])),
      clubSessionsProvider('vake').overrideWith((ref) => Stream.value(const <Session>[])),
    ]));
    await tester.pumpAndSettle();
    expect(find.text('No tables yet'), findsOneWidget);
  });

  testWidgets('TableDetailScreen renders a seat per seatCount; occupied shows initials',
      (tester) async {
    await tester.pumpWidget(_wrap(
      const TableDetailScreen(clubId: 'vake', tableId: 't1'),
      [
        currentUserProvider.overrideWith((ref) => Stream.value(_pb())),
        tablesProvider('vake').overrideWith((ref) => Stream.value(const [_table])),
        clubSessionsProvider('vake').overrideWith((ref) => Stream.value([_session(1)])),
        clubWaitlistProvider('vake').overrideWith((ref) => Stream.value(const <WaitlistEntry>[])),
      ],
    ));
    await tester.pumpAndSettle();

    // Oval seat map: 9 seats, 1 occupied -> 8 open ("8/9").
    expect(find.byType(PsSeatMap), findsOneWidget);
    expect(find.text('8/9'), findsOneWidget);
    expect(find.byKey(const Key('editTableBtn')), findsOneWidget);
    expect(find.byKey(const Key('deleteTableBtn')), findsOneWidget);
  });
}
