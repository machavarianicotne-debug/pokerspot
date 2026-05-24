import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/features/floor/data/fake_floor_repositories.dart';
import 'package:pokerspot/features/floor/domain/stakes.dart';
import 'package:pokerspot/features/floor/domain/waitlist_entry.dart';
import 'package:pokerspot/features/floor/presentation/my_waitlist_banner.dart';
import 'package:pokerspot/features/floor/presentation/providers.dart';

const _stakes = Stakes(variant: GameVariant.nlh, smallBlind: 1, bigBlind: 2, currency: 'GEL');

WaitlistEntry _entry(String id, WaitlistStatus status) => WaitlistEntry(
      id: id,
      clubId: 'c',
      playerUid: 'u',
      playerName: 'Nino',
      stakes: _stakes,
      status: status,
      createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
      calledAt: null,
    );

// myWaitlistProvider is overridden with a single-emission Stream.value (stable
// under pumpAndSettle), so these stay deterministic.
Widget _wrap(List<Override> overrides) => ProviderScope(
      overrides: overrides,
      child: const MaterialApp(
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: Scaffold(body: MyWaitlistBanner()),
      ),
    );

void main() {
  testWidgets('waiting entry shows stake + Waiting + cancel', (tester) async {
    await tester.pumpWidget(_wrap([
      myWaitlistProvider.overrideWith((ref) => Stream.value([_entry('e1', WaitlistStatus.waiting)])),
    ]));
    await tester.pumpAndSettle();

    expect(find.text('NLH 1/2 GEL'), findsOneWidget);
    expect(find.text('Waiting'), findsOneWidget);
    expect(find.byKey(const Key('cancelWaitlist_e1')), findsOneWidget);
  });

  testWidgets('called entry shows the called status', (tester) async {
    await tester.pumpWidget(_wrap([
      myWaitlistProvider.overrideWith((ref) => Stream.value([_entry('e2', WaitlistStatus.called)])),
    ]));
    await tester.pumpAndSettle();
    expect(find.text("You've been called!"), findsOneWidget);
  });

  testWidgets('no entries -> renders nothing', (tester) async {
    await tester.pumpWidget(_wrap([
      myWaitlistProvider.overrideWith((ref) => Stream.value(const <WaitlistEntry>[])),
    ]));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsNothing);
    expect(find.text('Waiting'), findsNothing);
  });

  testWidgets('cancel calls the repository', (tester) async {
    final store = FakeFloorStore();
    final wl = FakeWaitlistRepository(store);
    await wl.join(clubId: 'c', playerUid: 'u', playerName: 'Nino', stakes: _stakes);
    final entry = store.waitlist.values.first;

    await tester.pumpWidget(_wrap([
      myWaitlistProvider.overrideWith((ref) => Stream.value([entry])),
      waitlistRepositoryProvider.overrideWithValue(wl),
    ]));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(Key('cancelWaitlist_${entry.id}')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(store.waitlist[entry.id]!.status, WaitlistStatus.cancelled);
  });
}
