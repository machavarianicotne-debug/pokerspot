import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/features/announcements/data/fake_announcements_repository.dart';

void main() {
  test('post -> watchByClub emits the new announcement', () async {
    final repo = FakeAnnouncementsRepository();
    final stream = repo.watchByClub('vake');
    await repo.post(clubId: 'vake', senderUid: 'pb1', senderName: 'Pit', text: 'Hello');
    final first = await stream.firstWhere((l) => l.isNotEmpty);
    expect(first.single.text, 'Hello');
    expect(first.single.senderUid, 'pb1');
  });

  test('post stamps createdAt and emits newest-last (sorted ascending)', () async {
    final repo = FakeAnnouncementsRepository();
    await repo.post(clubId: 'vake', senderUid: 'pb1', senderName: 'Pit', text: 'A');
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await repo.post(clubId: 'vake', senderUid: 'pb1', senderName: 'Pit', text: 'B');
    final list = await repo.watchByClub('vake').first;
    expect(list.map((a) => a.text).toList(), ['A', 'B']);
    expect(list.every((a) => a.createdAt != null), true);
  });

  test('edit updates text and stamps editedAt', () async {
    final repo = FakeAnnouncementsRepository();
    await repo.post(clubId: 'vake', senderUid: 'pb1', senderName: 'Pit', text: 'Old');
    final id = (await repo.watchByClub('vake').first).single.id;
    await repo.edit(announcementId: id, newText: 'New');
    final list = await repo.watchByClub('vake').first;
    expect(list.single.text, 'New');
    expect(list.single.editedAt, isNotNull);
  });

  test('delete removes the announcement', () async {
    final repo = FakeAnnouncementsRepository();
    await repo.post(clubId: 'vake', senderUid: 'pb1', senderName: 'Pit', text: 'Bye');
    final id = (await repo.watchByClub('vake').first).single.id;
    await repo.delete(id);
    final list = await repo.watchByClub('vake').first;
    expect(list, isEmpty);
  });

  test('setReaction sets and (with empty emoji) clears the caller\'s reaction', () async {
    final repo = FakeAnnouncementsRepository();
    await repo.post(clubId: 'vake', senderUid: 'pb1', senderName: 'Pit', text: 'React');
    final id = (await repo.watchByClub('vake').first).single.id;
    await repo.setReaction(announcementId: id, uid: 'u1', emoji: '👍');
    expect((await repo.watchByClub('vake').first).single.reactions['u1'], '👍');
    await repo.setReaction(announcementId: id, uid: 'u1', emoji: '');
    expect((await repo.watchByClub('vake').first).single.reactions.containsKey('u1'), false);
  });
}
