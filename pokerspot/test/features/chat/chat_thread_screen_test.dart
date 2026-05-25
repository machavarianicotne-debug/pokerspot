import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/features/auth/data/fake_auth_repository.dart';
import 'package:pokerspot/features/auth/domain/app_user.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/features/chat/data/fake_chat_repository.dart';
import 'package:pokerspot/features/chat/domain/message.dart';
import 'package:pokerspot/features/chat/presentation/chat_thread_screen.dart';
import 'package:pokerspot/features/chat/presentation/providers.dart';
import 'package:pokerspot/shared/widgets/ps_chat.dart';

Message _m(String id, String sender, String text) => Message(
      id: id, clubId: 'c1', playerUid: 'u1', playerName: 'Nino',
      senderUid: sender, senderRole: sender == 'u1' ? AppRole.player : AppRole.pitboss,
      text: text, at: DateTime.fromMillisecondsSinceEpoch(1700000000000 + int.parse(id)));

void main() {
  testWidgets('renders the thread bubbles + composer', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        chatRepositoryProvider.overrideWithValue(FakeChatRepository()), // markThreadRead on open
        threadProvider((clubId: 'c1', playerUid: 'u1')).overrideWith(
            (ref) => Stream.value([_m('1', 'u1', 'Dress code tonight?'), _m('2', 'pb', 'Smart casual.')])),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: ChatThreadScreen(clubId: 'c1', playerUid: 'u1', playerName: 'Nino', title: 'Royal Poker'),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Royal Poker'), findsOneWidget);
    expect(find.text('Dress code tonight?'), findsOneWidget);
    expect(find.text('Smart casual.'), findsOneWidget);
    expect(find.byType(PsChatBubble), findsNWidgets(2));
    expect(find.byType(PsComposer), findsOneWidget);
  });
}
