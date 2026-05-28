import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/features/announcements/domain/announcement.dart';

void main() {
  test('Announcement round-trips through toMap/fromMap (incl. reactions)', () {
    final a = Announcement(
      id: 'a1',
      clubId: 'vake',
      senderUid: 'pb1',
      senderName: 'Pit Boss',
      text: 'Closed tomorrow 🔧',
      createdAt: DateTime.fromMillisecondsSinceEpoch(1700000000000),
      editedAt: null,
      reactions: const {'u1': '👍', 'u2': '❤️'},
    );
    final round = Announcement.fromMap('a1', a.toMap());
    expect(round, a);
    expect(round.reactions['u1'], '👍');
  });

  test('Announcement.fromMap defaults missing fields safely', () {
    final a = Announcement.fromMap('a1', const {'clubId': 'vake'});
    expect(a.senderUid, '');
    expect(a.text, '');
    expect(a.reactions, isEmpty);
    expect(a.createdAt, isNull);
    expect(a.editedAt, isNull);
  });
}
