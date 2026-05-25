import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/features/admin/presentation/observe_club_screen.dart';
import 'package:pokerspot/features/floor/domain/poker_table.dart';
import 'package:pokerspot/features/floor/domain/session.dart';
import 'package:pokerspot/features/floor/domain/stakes.dart';
import 'package:pokerspot/features/floor/domain/waitlist_entry.dart';
import 'package:pokerspot/features/floor/presentation/providers.dart';

const _stakes = Stakes(variant: GameVariant.nlh, smallBlind: 1, bigBlind: 2, currency: 'GEL');
const _table = PokerTable(
    id: 't1', clubId: 'c1', number: 1, stakes: _stakes, seatCount: 9, open: true);
Session _session(int seat) => Session(
    id: 's$seat', clubId: 'c1', tableId: 't1', seatNumber: seat, playerUid: 'u',
    playerName: 'P', stakes: _stakes, status: SessionStatus.active,
    startedAt: DateTime.now(), endedAt: null);

void main() {
  testWidgets('ObserveClubScreen lists tables read-only with occupancy', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        tablesProvider('c1').overrideWith((ref) => Stream.value(const [_table])),
        clubSessionsProvider('c1').overrideWith((ref) => Stream.value([_session(1), _session(2)])),
        clubWaitlistProvider('c1').overrideWith((ref) => Stream.value(const <WaitlistEntry>[])),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: ObserveClubScreen(clubId: 'c1', clubName: 'Vake'),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Read-only'), findsOneWidget); // badge
    expect(find.byKey(const Key('observeTable_t1')), findsOneWidget);
    expect(find.text('NLH 1/2 GEL'), findsOneWidget);
    expect(find.text('2/9'), findsOneWidget); // 2 seats occupied of 9
  });
}
