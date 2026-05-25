import 'dart:async';

import 'package:pokerspot/features/tournaments/domain/tournament_registration.dart';
import 'package:pokerspot/features/tournaments/domain/tournament_registrations_repository.dart';

/// In-memory [TournamentRegistrationsRepository] for tests + offline UI work.
class FakeTournamentRegistrationsRepository implements TournamentRegistrationsRepository {
  FakeTournamentRegistrationsRepository({List<TournamentRegistration>? seed}) {
    for (final r in seed ?? const <TournamentRegistration>[]) {
      _items[r.id] = r;
    }
  }

  final _items = <String, TournamentRegistration>{};
  final _changes = StreamController<void>.broadcast();
  int _seq = 0;

  @override
  Stream<List<TournamentRegistration>> watchByTournament(String tournamentId) {
    final out = StreamController<List<TournamentRegistration>>();
    List<TournamentRegistration> read() =>
        _items.values.where((r) => r.tournamentId == tournamentId).toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    StreamSubscription<void>? sub;
    out.onListen = () {
      out.add(read());
      sub = _changes.stream.listen((_) => out.add(read()));
    };
    out.onCancel = () async => sub?.cancel();
    return out.stream;
  }

  @override
  Future<void> register(TournamentRegistration r) async {
    final id = r.id.isEmpty ? 'reg-${_seq++}' : r.id;
    _items[id] = TournamentRegistration(
      id: id,
      tournamentId: r.tournamentId,
      clubId: r.clubId,
      playerUid: r.playerUid,
      playerName: r.playerName,
      createdAt: r.createdAt,
    );
    _changes.add(null);
  }

  @override
  Future<void> unregister(String tournamentId, String playerUid) async {
    _items.removeWhere(
        (_, r) => r.tournamentId == tournamentId && r.playerUid == playerUid);
    _changes.add(null);
  }
}
