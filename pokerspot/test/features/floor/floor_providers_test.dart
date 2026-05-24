import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/features/auth/data/fake_auth_repository.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/features/floor/data/fake_floor_repositories.dart';
import 'package:pokerspot/features/floor/domain/poker_table.dart';
import 'package:pokerspot/features/floor/domain/stakes.dart';
import 'package:pokerspot/features/floor/presentation/providers.dart';

const _stakes = Stakes(variant: GameVariant.nlh, smallBlind: 1, bigBlind: 2, currency: 'GEL');

void main() {
  test('tablesProvider reflects the repository', () async {
    final store = FakeFloorStore(tables: const [
      PokerTable(id: 't1', clubId: 'c1', number: 1, stakes: _stakes, seatCount: 9, open: true),
    ]);
    final container = ProviderContainer(
      overrides: [tablesRepositoryProvider.overrideWithValue(FakeTablesRepository(store))],
    );
    addTearDown(container.dispose);
    final list = await container.read(tablesProvider('c1').future);
    expect(list.length, 1);
    expect(list.first.id, 't1');
  });

  test('clubWaitlistProvider reflects the repository', () async {
    final store = FakeFloorStore();
    final wl = FakeWaitlistRepository(store);
    await wl.join(clubId: 'c1', playerUid: 'u1', playerName: 'Nino', stakes: _stakes);
    final container = ProviderContainer(
      overrides: [waitlistRepositoryProvider.overrideWithValue(wl)],
    );
    addTearDown(container.dispose);
    final list = await container.read(clubWaitlistProvider('c1').future);
    expect(list.length, 1);
    expect(list.first.playerName, 'Nino');
  });

  test('myWaitlistProvider follows the signed-in uid', () async {
    final auth = FakeAuthRepository();
    final s = await auth.sendOtp('+995555222222');
    await auth.confirmOtp(s, '222222');
    final uid = auth.currentUid!;

    final store = FakeFloorStore();
    final wl = FakeWaitlistRepository(store);
    await wl.join(clubId: 'c1', playerUid: uid, playerName: 'Nino', stakes: _stakes);

    final container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      waitlistRepositoryProvider.overrideWithValue(wl),
    ]);
    addTearDown(container.dispose);

    // Keep it active; uidProvider transitions loading -> data (avoid .future hang).
    final sub = container.listen(myWaitlistProvider, (_, __) {});
    addTearDown(sub.close);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(container.read(myWaitlistProvider).valueOrNull?.length, 1);
  });
}
