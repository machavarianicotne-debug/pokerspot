import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/features/clubs/domain/club.dart';
import 'package:pokerspot/features/clubs/presentation/providers.dart';
import 'package:pokerspot/features/floor/domain/poker_table.dart';
import 'package:pokerspot/features/floor/domain/stakes.dart';
import 'package:pokerspot/features/floor/presentation/providers.dart';
import 'package:pokerspot/features/floor/presentation/reservation_flow_screen.dart';

const _stakes = Stakes(variant: GameVariant.nlh, smallBlind: 1, bigBlind: 2, currency: 'GEL');
const _table = PokerTable(
    id: 't1', clubId: 'vake', number: 1, stakes: _stakes, seatCount: 9, open: true);
const _game = ClubGame(
    tableId: 't1', label: 'NLH 1/2 GEL', type: 'NLH', minBuyIn: null, avgStack: null,
    tables: 1, openSeats: 9, waiting: 0);
const _vake = Club(
    id: 'vake', name: 'PokerSpot Vake', city: 'Tbilisi', address: 'A', photoUrl: null,
    hoursText: 'H', phone: 'P', enabled: true, games: [_game]);

void main() {
  testWidgets('ReservationFlowScreen shows club + stake choices + reserve', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        clubProvider('vake').overrideWith((ref) => Stream.value(_vake)),
        tablesProvider('vake').overrideWith((ref) => Stream.value(const [_table])),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: ReservationFlowScreen(clubId: 'vake'),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('PokerSpot Vake'), findsOneWidget);
    // Pill now shows the open-seat count (reserve is gated on an open seat).
    expect(find.textContaining('NLH 1/2 GEL'), findsWidgets);
    expect(find.textContaining('9 open'), findsOneWidget);
    await tester.scrollUntilVisible(find.byKey(const Key('reserveNowBtn')), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.byKey(const Key('reserveNowBtn')), findsOneWidget);
  });
}
