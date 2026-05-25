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
  testWidgets('player chat inbox lists a thread per club by club name', (tester) async {
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
    expect(find.text('PokerSpot Vake'), findsOneWidget); // resolved club name
    expect(find.text('See you tonight'), findsOneWidget); // last message
  });

  testWidgets('player chat inbox shows an unread count badge', (tester) async {
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

  testWidgets('player chat inbox shows the empty state with no threads', (tester) async {
    await tester.pumpWidget(_wrap([
      myThreadsProvider.overrideWith((ref) => Stream.value(const <ChatThread>[])),
      clubsListProvider.overrideWith((ref) => Stream.value(const <Club>[])),
    ]));
    await tester.pumpAndSettle();
    expect(find.text('No conversations yet'), findsOneWidget);
  });
}
