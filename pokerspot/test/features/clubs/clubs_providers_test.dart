import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/features/clubs/data/fake_clubs_repository.dart';
import 'package:pokerspot/features/clubs/domain/club.dart';
import 'package:pokerspot/features/clubs/presentation/providers.dart';

Club _club(String id, {bool enabled = true}) => Club(
      id: id,
      name: 'Club $id',
      city: 'Tbilisi',
      address: 'A',
      photoUrl: null,
      hoursText: 'H',
      phone: 'P',
      enabled: enabled,
    );

void main() {
  test('clubsListProvider reflects the repository (enabled only)', () async {
    final repo = FakeClubsRepository(seed: [_club('a'), _club('b', enabled: false)]);
    final container = ProviderContainer(
      overrides: [clubsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    final list = await container.read(clubsListProvider.future);
    expect(list.map((c) => c.id), ['a']);
  });

  test('clubProvider(id) emits the matching club', () async {
    final repo = FakeClubsRepository(seed: [_club('a')]);
    final container = ProviderContainer(
      overrides: [clubsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    final c = await container.read(clubProvider('a').future);
    expect(c?.id, 'a');
    expect(await container.read(clubProvider('missing').future), isNull);
  });
}
