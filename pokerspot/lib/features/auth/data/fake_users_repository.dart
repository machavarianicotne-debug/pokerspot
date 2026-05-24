import 'dart:async';

import 'package:pokerspot/features/auth/domain/app_user.dart';
import 'package:pokerspot/features/auth/domain/users_repository.dart';

/// In-memory [UsersRepository] for tests + offline UI work. Backed by a
/// `Map<String, AppUser>` keyed by uid, with one broadcast controller per uid
/// for [watchUser]. No Firebase imports.
class FakeUsersRepository implements UsersRepository {
  final _store = <String, AppUser>{};
  final _controllers = <String, StreamController<AppUser?>>{};

  StreamController<AppUser?> _ctrl(String uid) =>
      _controllers.putIfAbsent(uid, () => StreamController<AppUser?>.broadcast());

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
    final user = AppUser(
      uid: uid,
      phone: phone,
      firstName: firstName,
      lastName: lastName,
      role: AppRole.player,
      lang: lang,
      blocked: false,
    );
    _store[uid] = user;
    _ctrl(uid).add(user);
  }
}
