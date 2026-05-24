import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/features/clubs/data/fake_clubs_repository.dart';
import 'package:pokerspot/features/clubs/domain/club.dart';

Club _club(String id, {bool enabled = true, String city = 'Tbilisi'}) => Club(
      id: id,
      name: 'Club $id',
      city: city,
      address: 'Addr $id',
      photoUrl: null,
      hoursText: 'Daily',
      phone: '+995',
      enabled: enabled,
    );

void main() {
  test('watchEnabledClubs emits only enabled clubs', () async {
    final repo = FakeClubsRepository(seed: [
      _club('a'),
      _club('b'),
      _club('c', enabled: false),
    ]);
    final list = await repo.watchEnabledClubs().first;
    expect(list.map((c) => c.id), containsAll(['a', 'b']));
    expect(list.any((c) => c.id == 'c'), isFalse);
    expect(list.length, 2);
  });

  test('getClub returns the club or null', () async {
    final repo = FakeClubsRepository(seed: [_club('a')]);
    expect((await repo.getClub('a'))?.name, 'Club a');
    expect(await repo.getClub('missing'), isNull);
  });

  test('watchClub replays current and pushes upserts to a subscriber', () async {
    final repo = FakeClubsRepository(seed: [_club('a')]);
    expect((await repo.watchClub('a').first)?.id, 'a');

    final seen = <Club?>[];
    final sub = repo.watchClub('a').listen(seen.add);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    repo.upsert(_club('a', city: 'Batumi'));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await sub.cancel();
    expect(seen.first?.city, 'Tbilisi');
    expect(seen.last?.city, 'Batumi');
  });

  test('watchEnabledClubs pushes list changes to a subscriber', () async {
    final repo = FakeClubsRepository(seed: [_club('a')]);
    final seen = <List<Club>>[];
    final sub = repo.watchEnabledClubs().listen(seen.add);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    repo.upsert(_club('b'));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await sub.cancel();
    expect(seen.first.length, 1);
    expect(seen.last.length, 2);
  });
}
