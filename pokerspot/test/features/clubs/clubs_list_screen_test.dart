import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/features/clubs/data/fake_clubs_repository.dart';
import 'package:pokerspot/features/clubs/domain/club.dart';
import 'package:pokerspot/features/clubs/presentation/clubs_list_screen.dart';
import 'package:pokerspot/features/clubs/presentation/providers.dart';

Club _club(String id, {String name = '', String city = 'Tbilisi'}) => Club(
      id: id,
      name: name.isEmpty ? 'Club $id' : name,
      city: city,
      address: 'Addr $id',
      photoUrl: null,
      hoursText: 'Daily',
      phone: '+995',
      enabled: true,
    );

Widget _wrap(List<Override> overrides) => ProviderScope(
      overrides: overrides,
      child: const MaterialApp(
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: Scaffold(body: ClubsListScreen()),
      ),
    );

void main() {
  testWidgets('shows a loading indicator while the stream has no value', (tester) async {
    await tester.pumpWidget(_wrap([
      clubsListProvider.overrideWith(
          (ref) => Stream<List<Club>>.fromFuture(Completer<List<Club>>().future)),
    ]));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('empty repository shows the empty state', (tester) async {
    await tester.pumpWidget(_wrap([
      clubsRepositoryProvider.overrideWithValue(FakeClubsRepository()),
    ]));
    await tester.pumpAndSettle();
    expect(find.text('No clubs yet'), findsOneWidget);
  });

  testWidgets('renders a card per club with name + city', (tester) async {
    await tester.pumpWidget(_wrap([
      clubsRepositoryProvider.overrideWithValue(FakeClubsRepository(seed: [
        _club('a', name: 'PokerSpot Vake', city: 'Tbilisi'),
        _club('b', name: 'Batumi Royal', city: 'Batumi'),
      ])),
    ]));
    await tester.pumpAndSettle();
    expect(find.text('PokerSpot Vake'), findsOneWidget);
    expect(find.text('Batumi Royal'), findsOneWidget);
    expect(find.text('Batumi'), findsOneWidget);
    expect(find.byKey(const Key('clubCard_a')), findsOneWidget);
  });

  testWidgets('tapping a club navigates to /home/club/:id', (tester) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const Scaffold(body: ClubsListScreen())),
        GoRoute(
            path: '/home/club/:id',
            builder: (_, st) => Scaffold(body: Text('DETAIL ${st.pathParameters['id']}'))),
      ],
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        clubsRepositoryProvider.overrideWithValue(FakeClubsRepository(seed: [_club('a')])),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        routerConfig: router,
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('clubCard_a')));
    await tester.pumpAndSettle();
    expect(find.text('DETAIL a'), findsOneWidget);
  });

  testWidgets('desktop width (1280): list is capped by the 440px pane', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap([
      clubsRepositoryProvider.overrideWithValue(FakeClubsRepository(seed: [_club('a')])),
    ]));
    await tester.pumpAndSettle();

    final w = tester.getSize(find.byType(ListView)).width;
    expect(w, lessThanOrEqualTo(440));
    expect(w, greaterThan(300));
  });

  testWidgets('mobile width (375): list is (near) full-width', (tester) async {
    tester.view.physicalSize = const Size(375, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap([
      clubsRepositoryProvider.overrideWithValue(FakeClubsRepository(seed: [_club('a')])),
    ]));
    await tester.pumpAndSettle();

    final w = tester.getSize(find.byType(ListView)).width;
    expect(w, lessThanOrEqualTo(375));
    expect(w, greaterThan(300));
  });
}
