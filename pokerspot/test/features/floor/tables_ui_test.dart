import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/features/auth/domain/app_user.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/features/floor/domain/poker_table.dart';
import 'package:pokerspot/features/floor/domain/reservation.dart';
import 'package:pokerspot/features/floor/domain/session.dart';
import 'package:pokerspot/features/floor/domain/stakes.dart';
import 'package:pokerspot/features/floor/domain/waitlist_entry.dart';
import 'package:pokerspot/features/floor/presentation/providers.dart';
import 'package:pokerspot/features/floor/presentation/game_detail_screen.dart';
import 'package:pokerspot/features/floor/presentation/new_game_screen.dart';
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
  testWidgets('TablesScreen lists the club tables with occupancy + New game', (tester) async {
    await tester.pumpWidget(_wrap(const Scaffold(body: TablesScreen()), [
      currentUserProvider.overrideWith((ref) => Stream.value(_pb())),
      tablesProvider('vake').overrideWith((ref) => Stream.value(const [_table])),
      clubSessionsProvider('vake').overrideWith((ref) => Stream.value([_session(3)])),
      clubWaitlistProvider('vake').overrideWith((ref) => Stream.value(const <WaitlistEntry>[])),
    ]));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('newGameBtn')), findsOneWidget);
    expect(find.byKey(const Key('newTableBtn')), findsNothing); // hidden — New Game covers it
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
    expect(find.text('1/3'), findsOneWidget); // a blind preset pill
    // The stepper + openGameBtn live below the ListView fold (lazy-built) — scroll down.
    await tester.scrollUntilVisible(find.byKey(const Key('openGameBtn')), 300,
        scrollable: find.byType(Scrollable).first);
    expect(find.byKey(const Key('openGameBtn')), findsOneWidget);
    expect(find.byType(PsStepper), findsOneWidget); // tables count
  });

  testWidgets('TablesScreen shows the empty state with no tables', (tester) async {
    await tester.pumpWidget(_wrap(const Scaffold(body: TablesScreen()), [
      currentUserProvider.overrideWith((ref) => Stream.value(_pb())),
      tablesProvider('vake').overrideWith((ref) => Stream.value(const <PokerTable>[])),
      clubSessionsProvider('vake').overrideWith((ref) => Stream.value(const <Session>[])),
      clubWaitlistProvider('vake').overrideWith((ref) => Stream.value(const <WaitlistEntry>[])),
    ]));
    await tester.pumpAndSettle();
    expect(find.text('No tables yet'), findsOneWidget);
  });

  testWidgets('GameDetailScreen (game-centric) shows the table seat map + seated timer', (tester) async {
    await tester.pumpWidget(_wrap(
      const GameDetailScreen(clubId: 'vake', stakeLabel: 'NLH 1/2 GEL'),
      [
        currentUserProvider.overrideWith((ref) => Stream.value(_pb())),
        tablesProvider('vake').overrideWith((ref) => Stream.value(const [_table])),
        clubSessionsProvider('vake').overrideWith((ref) => Stream.value([_session(1)])),
        clubWaitlistProvider('vake').overrideWith((ref) => Stream.value(const <WaitlistEntry>[])),
        clubReservationsProvider('vake').overrideWith((ref) => Stream.value(const <Reservation>[])),
      ],
    ));
    // Live timers (Timer.periodic) never settle — pump instead of pumpAndSettle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byKey(const Key('tableCard_t1')), findsOneWidget);
    expect(find.byType(PsSeatMap), findsOneWidget);
    expect(find.text('8/9'), findsOneWidget); // 9 seats, 1 occupied
    expect(find.byKey(const Key('seated_s1')), findsOneWidget); // seated list row
    expect(find.text('Nino K'), findsOneWidget); // seated player name
  });

  testWidgets('GameDetailScreen waitlist row has Seat + remove actions', (tester) async {
    final entry = WaitlistEntry(
        id: 'e1', clubId: 'vake', playerUid: 'u', playerName: 'Nino K', stakes: _stakes,
        status: WaitlistStatus.waiting, createdAt: DateTime.now(), calledAt: null);
    await tester.pumpWidget(_wrap(
      const GameDetailScreen(clubId: 'vake', stakeLabel: 'NLH 1/2 GEL'),
      [
        currentUserProvider.overrideWith((ref) => Stream.value(_pb())),
        tablesProvider('vake').overrideWith((ref) => Stream.value(const [_table])),
        clubSessionsProvider('vake').overrideWith((ref) => Stream.value(const <Session>[])),
        clubWaitlistProvider('vake').overrideWith((ref) => Stream.value([entry])),
        clubReservationsProvider('vake').overrideWith((ref) => Stream.value(const <Reservation>[])),
      ],
    ));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const Key('wlRow_e1')), 200,
        scrollable: find.byType(Scrollable).first);
    // Call was removed — players are auto-notified when a seat frees.
    expect(find.byKey(const Key('callBtn_e1')), findsNothing);
    expect(find.byKey(const Key('seatBtn_e1')), findsOneWidget);
    expect(find.byKey(const Key('removeWlBtn_e1')), findsOneWidget);
  });

  testWidgets('GameDetailScreen shows a held reservation with Seat + reject', (tester) async {
    final res = Reservation(
        id: 'r1', clubId: 'vake', playerUid: 'u9', playerName: 'Levan', stakes: _stakes,
        status: ReservationStatus.held,
        heldUntil: DateTime.now().add(const Duration(minutes: 30)), createdAt: DateTime.now());
    await tester.pumpWidget(_wrap(
      const GameDetailScreen(clubId: 'vake', stakeLabel: 'NLH 1/2 GEL'),
      [
        currentUserProvider.overrideWith((ref) => Stream.value(_pb())),
        tablesProvider('vake').overrideWith((ref) => Stream.value(const [_table])),
        clubSessionsProvider('vake').overrideWith((ref) => Stream.value(const <Session>[])),
        clubWaitlistProvider('vake').overrideWith((ref) => Stream.value(const <WaitlistEntry>[])),
        clubReservationsProvider('vake').overrideWith((ref) => Stream.value([res])),
      ],
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.scrollUntilVisible(find.byKey(const Key('resRow_r1')), 200,
        scrollable: find.byType(Scrollable).first);
    // Reservations are now handled like the waitlist: Seat (+ reject), no Arrived.
    expect(find.byKey(const Key('resSeatBtn_r1')), findsOneWidget);
    expect(find.byKey(const Key('rejectResBtn_r1')), findsOneWidget);
    expect(find.text('Levan'), findsOneWidget);
  });

  testWidgets('GameDetailScreen shows the shared waitlist with a Seat action', (tester) async {
    final entry = WaitlistEntry(
        id: 'e1', clubId: 'vake', playerUid: 'u', playerName: 'Nino K', stakes: _stakes,
        status: WaitlistStatus.waiting, createdAt: DateTime.now(), calledAt: null);
    await tester.pumpWidget(_wrap(
      const GameDetailScreen(clubId: 'vake', stakeLabel: 'NLH 1/2 GEL'),
      [
        currentUserProvider.overrideWith((ref) => Stream.value(_pb())),
        tablesProvider('vake').overrideWith((ref) => Stream.value(const [_table])),
        clubSessionsProvider('vake').overrideWith((ref) => Stream.value(const <Session>[])),
        clubWaitlistProvider('vake').overrideWith((ref) => Stream.value([entry])),
      ],
    ));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const Key('wlRow_e1')), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.byKey(const Key('wlRow_e1')), findsOneWidget);
    expect(find.byKey(const Key('seatBtn_e1')), findsOneWidget);
  });
}
