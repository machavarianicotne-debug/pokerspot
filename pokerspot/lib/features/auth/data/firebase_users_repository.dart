import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pokerspot/features/auth/domain/app_user.dart';
import 'package:pokerspot/features/auth/domain/users_repository.dart';

/// Firestore-backed [UsersRepository]. Profiles live in the `users` collection,
/// one doc per uid. (De)serialized via [AppUser.fromMap] / [AppUser.toMap].
class FirebaseUsersRepository implements UsersRepository {
  FirebaseUsersRepository(this._firestore);
  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _firestore.collection('users').doc(uid);

  @override
  Stream<AppUser?> watchUser(String uid) => _doc(uid).snapshots().map(
        (s) => s.exists ? AppUser.fromMap(uid, s.data()!) : null,
      );

  @override
  Future<AppUser?> getUser(String uid) async {
    final s = await _doc(uid).get();
    return s.exists ? AppUser.fromMap(uid, s.data()!) : null;
  }

  @override
  Future<void> createProfile({
    required String uid,
    required String phone,
    required String displayName,
    required String lang,
  }) {
    return _doc(uid).set({
      'phone': phone,
      'displayName': displayName,
      'role': AppRole.player.asString,
      'lang': lang,
      'blocked': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
