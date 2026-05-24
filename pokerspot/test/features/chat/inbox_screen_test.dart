import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/features/auth/domain/app_user.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/features/chat/domain/message.dart';
import 'package:pokerspot/features/chat/presentation/inbox_screen.dart';
import 'package:pokerspot/features/chat/presentation/providers.dart';

AppUser _pb() => const AppUser(
    uid: 'pb', phone: '', firstName: 'Pit', lastName: 'Boss',
    role: AppRole.pitboss, lang: 'en', blocked: false, clubId: 'vake');

ChatThread _thread(String uid, String name, String last) =>
    ChatThread(clubId: 'vake', playerUid: uid, playerName: name, lastText: last, lastAt: DateTime.now(), unread: 0);

Widget _wrap(List<Override> overrides) => ProviderScope(
      overrides: overrides,
      child: const MaterialApp(
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: Scaffold(body: InboxScreen()),
      ),
    );

void main() {
  testWidgets('lists club threads', (tester) async {
    await tester.pumpWidget(_wrap([
      currentUserProvider.overrideWith((ref) => Stream.value(_pb())),
      clubThreadsProvider('vake').overrideWith((ref) => Stream.value([_thread('u1', 'Nino', 'Dress code?')])),
    ]));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('thread_u1')), findsOneWidget);
    expect(find.text('Nino'), findsOneWidget);
    expect(find.text('Dress code?'), findsOneWidget);
  });

  testWidgets('empty state with no threads', (tester) async {
    await tester.pumpWidget(_wrap([
      currentUserProvider.overrideWith((ref) => Stream.value(_pb())),
      clubThreadsProvider('vake').overrideWith((ref) => Stream.value(const <ChatThread>[])),
    ]));
    await tester.pumpAndSettle();
    expect(find.text('No conversations yet'), findsOneWidget);
  });
}
