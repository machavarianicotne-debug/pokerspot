import 'dart:async';

import 'package:pokerspot/features/auth/domain/app_user.dart';
import 'package:pokerspot/features/auth/domain/users_repository.dart';

/// In-memory [UsersRepository] for tests + offline UI work. Backed by a
/// `Map<String, AppUser>` keyed by uid, with one broadcast controller per uid
/// for [watchUser]. No Firebase imports.
class FakeUsersRepository implements UsersRepository {
  final _store = <String, AppUser>{};
  final _controllers = <String, StreamController<AppUser?>>{};
  final _allController = StreamController<List<AppUser>>.broadcast();

  StreamController<AppUser?> _ctrl(String uid) =>
      _controllers.putIfAbsent(uid, () => StreamController<AppUser?>.broadcast());

  void _push(AppUser u) {
    _store[u.uid] = u;
    _ctrl(u.uid).add(u);
    _allController.add(_store.values.toList(growable: false));
  }

  @override
  Stream<AppUser?> watchUser(String uid) async* {
    yield _store[uid];
    yield* _ctrl(uid).stream;
  }

  @override
  Future<AppUser?> getUser(String uid) async => _store[uid];

  @override
  Future<void> createProfile({
    required String uid,
    required String phone,
    required String firstName,
    required String lastName,
    required String lang,
  }) async {
    _push(AppUser(
      uid: uid,
      phone: phone,
      firstName: firstName,
      lastName: lastName,
      role: AppRole.player,
      lang: lang,
      blocked: false,
    ));
  }

  @override
  Stream<List<AppUser>> watchAllUsers() async* {
    yield _store.values.toList(growable: false);
    yield* _allController.stream;
  }

  @override
  Future<void> updateRole(String uid, AppRole role) async {
    final u = _store[uid];
    if (u != null) _push(u.copyWith(role: role));
  }

  @override
  Future<void> setLang(String uid, String lang) async {
    final u = _store[uid];
    if (u != null) _push(u.copyWith(lang: lang));
  }

  @override
  Future<void> setBlocked(String uid, bool blocked) async {
    final u = _store[uid];
    if (u != null) _push(u.copyWith(blocked: blocked));
  }

  @override
  Future<void> assignClub(String uid, String? clubId) async {
    final u = _store[uid];
    if (u != null) {
      // copyWith can't null clubId, so rebuild explicitly.
      _push(AppUser(
        uid: u.uid,
        phone: u.phone,
        firstName: u.firstName,
        lastName: u.lastName,
        role: u.role,
        lang: u.lang,
        blocked: u.blocked,
        clubId: clubId,
      ));
    }
  }

  final fcmTokens = <String, List<String>>{};

  @override
  Future<void> addFcmToken(String uid, String token) async {
    (fcmTokens[uid] ??= []).add(token);
  }

  /// Deletion requests captured for assertions (the real cascade is server-side).
  final deletionRequests = <String>[];

  @override
  Future<void> requestAccountDeletion(String uid) async {
    deletionRequests.add(uid);
  }
}
