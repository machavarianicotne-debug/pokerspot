import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/features/tournaments/data/fake_tournaments_repository.dart';
import 'package:pokerspot/features/tournaments/domain/tournament.dart';

Tournament _t({String id = '', TournamentType type = TournamentType.freezeout}) => Tournament(
      id: id, clubId: 'c1', name: 'Sunday Major', type: type,
      startAt: DateTime(2026, 6, 1, 20), buyIn: 100, rebuyFee: type.hasRebuy ? 100 : null,
      hasAddon: false, addonFee: null, blindMinutes: 20, currency: 'GEL');

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
}
