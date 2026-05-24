import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/features/auth/domain/app_user.dart';
import 'package:pokerspot/features/chat/data/fake_chat_repository.dart';

void main() {
  test('send -> watchThread returns the thread oldest-first', () async {
    final repo = FakeChatRepository();
    await repo.send(
        clubId: 'c1', playerUid: 'u1', playerName: 'Nino',
        senderUid: 'u1', senderRole: AppRole.player, text: 'Hi');
    await repo.send(
        clubId: 'c1', playerUid: 'u1', playerName: 'Nino',
        senderUid: 'pb', senderRole: AppRole.pitboss, text: 'Hello!');

    final thread = await repo.watchThread(clubId: 'c1', playerUid: 'u1').first;
    expect(thread.length, 2);
    expect(thread.first.text, 'Hi');
    expect(thread.first.fromPlayer, isTrue);
    expect(thread.last.text, 'Hello!');
    expect(thread.last.fromPlayer, isFalse);
  });

  test('watchClubThreads groups by player, newest activity first', () async {
    final repo = FakeChatRepository();
    await repo.send(
        clubId: 'c1', playerUid: 'u1', playerName: 'Nino',
        senderUid: 'u1', senderRole: AppRole.player, text: 'first');
    await repo.send(
        clubId: 'c1', playerUid: 'u2', playerName: 'Davit',
        senderUid: 'u2', senderRole: AppRole.player, text: 'later');

    final threads = await repo.watchClubThreads('c1').first;
    expect(threads.length, 2);
    expect(threads.first.playerUid, 'u2'); // most recent
    expect(threads.first.lastText, 'later');
    expect(threads.map((t) => t.playerName), containsAll(['Nino', 'Davit']));
  });
}
