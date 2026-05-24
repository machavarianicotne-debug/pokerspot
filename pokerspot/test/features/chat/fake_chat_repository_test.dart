import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/features/auth/domain/app_user.dart';
import 'package:pokerspot/features/chat/data/fake_chat_repository.dart';
import 'package:pokerspot/features/chat/domain/message.dart';

Message _seed(String id, String player, String name, int atMs) => Message(
      id: id, clubId: 'c1', playerUid: player, playerName: name,
      senderUid: player, senderRole: AppRole.player, text: 'msg-$id',
      at: DateTime.fromMillisecondsSinceEpoch(atMs));

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
    // Seed explicit timestamps so ordering is deterministic (u2 newer than u1).
    final repo = FakeChatRepository(seed: [
      _seed('1', 'u1', 'Nino', 1700000000000),
      _seed('2', 'u2', 'Davit', 1700000050000),
    ]);
    final threads = await repo.watchClubThreads('c1').first;
    expect(threads.length, 2);
    expect(threads.first.playerUid, 'u2'); // most recent
    expect(threads.map((t) => t.playerName), containsAll(['Nino', 'Davit']));
  });
}
