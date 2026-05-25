import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/features/tournaments/data/fake_tournament_registrations_repository.dart';
import 'package:pokerspot/features/tournaments/data/fake_tournaments_repository.dart';
import 'package:pokerspot/features/tournaments/domain/tournament.dart';
import 'package:pokerspot/features/tournaments/domain/tournament_registration.dart';

Tournament _t({String id = '', TournamentType type = TournamentType.freezeout, int? maxPlayers = 50}) =>
    Tournament(
      id: id, clubId: 'c1', name: 'Sunday Major', type: type,
      startAt: DateTime(2026, 6, 1, 20), buyIn: 100, rebuyFee: type.hasRebuy ? 100 : null,
      hasAddon: false, addonFee: null, blindMinutes: 20, currency: 'GEL', maxPlayers: maxPlayers);

TournamentRegistration _reg(String uid, int createdAt) => TournamentRegistration(
    id: '', tournamentId: 'tmt-0', clubId: 'c1', playerUid: uid, playerName: uid, createdAt: createdAt);

void main() {
  test('TournamentType.hasRebuy is true only for rebuy variants', () {
    expect(TournamentType.freezeout.hasRebuy, isFalse);
    expect(TournamentType.knockoutRebuy.hasRebuy, isTrue);
    expect(TournamentType.rebuy.hasRebuy, isTrue);
    expect(TournamentType.rebuyAddon.hasRebuy, isTrue);
  });

  test('Tournament round-trips through fromMap/toMap', () {
    final t = _t(id: 'x', type: TournamentType.rebuyAddon);
    final back = Tournament.fromMap('x', t.toMap());
    expect(back, t);
  });

  test('fake repo: create -> watchByClub (sorted) -> delete', () async {
    final repo = FakeTournamentsRepository();
    await repo.create(_t());
    var list = await repo.watchByClub('c1').first;
    expect(list.length, 1);
    expect(list.first.name, 'Sunday Major');
    expect(list.first.buyIn, 100);

    await repo.delete(list.first.id);
    list = await repo.watchByClub('c1').first;
    expect(list, isEmpty);
  });

  test('Tournament keeps maxPlayers through fromMap/toMap', () {
    final t = _t(id: 'x', maxPlayers: 30);
    expect(Tournament.fromMap('x', t.toMap()).maxPlayers, 30);
    // Legacy doc without the field round-trips to null (unlimited).
    final legacy = Map<String, dynamic>.from(t.toMap())..remove('maxPlayers');
    expect(Tournament.fromMap('x', legacy).maxPlayers, isNull);
  });

  test('registrations: sign-up order is preserved; unregister shifts the queue', () async {
    final repo = FakeTournamentRegistrationsRepository();
    await repo.register(_reg('a', 100));
    await repo.register(_reg('b', 200));
    await repo.register(_reg('c', 300));

    var list = await repo.watchByTournament('tmt-0').first;
    expect(list.map((r) => r.playerUid), ['a', 'b', 'c']); // oldest first

    // 'a' leaves -> 'b' is now first (would-be promoted off any waitlist).
    await repo.unregister('tmt-0', 'a');
    list = await repo.watchByTournament('tmt-0').first;
    expect(list.map((r) => r.playerUid), ['b', 'c']);
  });
}
