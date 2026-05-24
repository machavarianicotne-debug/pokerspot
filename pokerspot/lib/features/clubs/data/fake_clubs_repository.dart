import 'dart:async';

import 'package:pokerspot/features/clubs/domain/club.dart';
import 'package:pokerspot/features/clubs/domain/clubs_repository.dart';

/// In-memory [ClubsRepository] for tests + offline UI work. No Firebase imports.
/// Streams replay the current value on subscribe (source listen happens
/// synchronously in [onListen], so nothing emitted right after subscribing is
/// dropped) and forward live changes via broadcast controllers.
class FakeClubsRepository implements ClubsRepository {
  FakeClubsRepository({List<Club>? seed}) {
    for (final c in seed ?? const <Club>[]) {
      _store[c.id] = c;
    }
  }

  final _store = <String, Club>{};
  final _listController = StreamController<List<Club>>.broadcast();
  final _clubControllers = <String, StreamController<Club?>>{};

  List<Club> get _enabled =>
      _store.values.where((c) => c.enabled).toList(growable: false);

  StreamController<Club?> _ctrl(String id) =>
      _clubControllers.putIfAbsent(id, () => StreamController<Club?>.broadcast());

  /// Test helper: add or replace a club and notify listeners.
  void upsert(Club club) {
    _store[club.id] = club;
    _listController.add(_enabled);
    _ctrl(club.id).add(club);
  }

  @override
  Stream<List<Club>> watchEnabledClubs() {
    final out = StreamController<List<Club>>();
    StreamSubscription<List<Club>>? sub;
    out.onListen = () {
      out.add(_enabled);
      sub = _listController.stream.listen(out.add, onError: out.addError);
    };
    out.onCancel = () async {
      await sub?.cancel();
    };
    return out.stream;
  }

  @override
  Stream<Club?> watchClub(String id) {
    final out = StreamController<Club?>();
    StreamSubscription<Club?>? sub;
    out.onListen = () {
      out.add(_store[id]);
      sub = _ctrl(id).stream.listen(out.add, onError: out.addError);
    };
    out.onCancel = () async {
      await sub?.cancel();
    };
    return out.stream;
  }

  @override
  Future<Club?> getClub(String id) async => _store[id];
}
