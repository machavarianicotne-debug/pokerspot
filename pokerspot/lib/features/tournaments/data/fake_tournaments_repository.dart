import 'dart:async';

import 'package:pokerspot/features/tournaments/domain/tournament.dart';
import 'package:pokerspot/features/tournaments/domain/tournaments_repository.dart';

/// In-memory [TournamentsRepository] for tests + offline UI work.
class FakeTournamentsRepository implements TournamentsRepository {
  FakeTournamentsRepository({List<Tournament>? seed}) {
    for (final t in seed ?? const <Tournament>[]) {
      _items[t.id] = t;
    }
  }

  final _items = <String, Tournament>{};
  final _changes = StreamController<void>.broadcast();
  int _seq = 0;

  @override
  Stream<List<Tournament>> watchByClub(String clubId) {
    final out = StreamController<List<Tournament>>();
    List<Tournament> read() => _items.values.where((t) => t.clubId == clubId).toList()
      ..sort((a, b) => (a.startAt?.millisecondsSinceEpoch ?? 0)
          .compareTo(b.startAt?.millisecondsSinceEpoch ?? 0));
    StreamSubscription<void>? sub;
    out.onListen = () {
      out.add(read());
      sub = _changes.stream.listen((_) => out.add(read()));
    };
    out.onCancel = () async => sub?.cancel();
    return out.stream;
  }

  @override
  Future<void> create(Tournament t) async {
    final id = t.id.isEmpty ? 'tmt-${_seq++}' : t.id;
    _items[id] = Tournament(
      id: id, clubId: t.clubId, name: t.name, type: t.type, startAt: t.startAt,
      buyIn: t.buyIn, rebuyFee: t.rebuyFee, hasAddon: t.hasAddon, addonFee: t.addonFee,
      blindMinutes: t.blindMinutes, currency: t.currency,
    );
    _changes.add(null);
  }

  @override
  Future<void> delete(String id) async {
    _items.remove(id);
    _changes.add(null);
  }
}
