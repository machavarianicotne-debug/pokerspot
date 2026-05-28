import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/features/chat/domain/message.dart';
import 'package:pokerspot/features/chat/presentation/player_chat_inbox_screen.dart';
import 'package:pokerspot/features/chat/presentation/providers.dart';
import 'package:pokerspot/features/clubs/domain/club.dart';
import 'package:pokerspot/features/clubs/presentation/providers.dart';

const _vake = Club(
    id: 'vake', name: 'PokerSpot Vake', city: 'Tbilisi', address: 'A', photoUrl: null,
    hoursText: 'H', phone: 'P', enabled: true);

Widget _wrap(List<Override> overrides) => ProviderScope(
      overrides: overrides,
      child: const MaterialApp(
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: Scaffold(body: PlayerChatInboxScreen()),
      ),
    );

void main() {
  testWidgets('inbox tab lists the player\'s 1-on-1 thread per club', (tester) async {
    final thread = ChatThread(
      clubId: 'vake', playerUid: 'me', playerName: 'Me',
      lastText: 'See you tonight', lastAt: DateTime(2026, 5, 25), unread: 0,
    );
    await tester.pumpWidget(_wrap([
      myThreadsProvider.overrideWith((ref) => Stream.value([thread])),
      clubsListProvider.overrideWith((ref) => Stream.value(const [_vake])),
    ]));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('myThread_vake')), findsOneWidget);
    expect(find.text('See you tonight'), findsOneWidget); // last message
  });

  testWidgets('inbox tab shows an unread count badge', (tester) async {
    final thread = ChatThread(
      clubId: 'vake', playerUid: 'me', playerName: 'Me',
      lastText: 'New offer', lastAt: DateTime(2026, 5, 25), unread: 3,
    );
    await tester.pumpWidget(_wrap([
      myThreadsProvider.overrideWith((ref) => Stream.value([thread])),
      clubsListProvider.overrideWith((ref) => Stream.value(const [_vake])),
    ]));
    await tester.pumpAndSettle();
    expect(find.text('3'), findsOneWidget); // unread badge
  });

  testWidgets('inbox tab shows the empty state with no threads', (tester) async {
    await tester.pumpWidget(_wrap([
      myThreadsProvider.overrideWith((ref) => Stream.value(const <ChatThread>[])),
      clubsListProvider.overrideWith((ref) => Stream.value(const <Club>[])),
    ]));
    await tester.pumpAndSettle();
    expect(find.text('No conversations yet'), findsWidgets);
  });

  testWidgets('Club Chats tab lists one entry per club', (tester) async {
    await tester.pumpWidget(_wrap([
      myThreadsProvider.overrideWith((ref) => Stream.value(const <ChatThread>[])),
      clubsListProvider.overrideWith((ref) => Stream.value(const [_vake])),
    ]));
    await tester.pumpAndSettle();

    // Switch to the Club Chats tab.
    await tester.tap(find.byKey(const Key('chatHubTab_1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('clubChat_vake')), findsOneWidget);
    expect(find.text('PokerSpot Vake'), findsOneWidget);
  });
}
