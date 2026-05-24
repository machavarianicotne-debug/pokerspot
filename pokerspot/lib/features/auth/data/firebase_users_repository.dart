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
    required String firstName,
    required String lastName,
    required String lang,
  }) {
    return _doc(uid).set({
      'phone': phone,
      'firstName': firstName,
      'lastName': lastName,
      'role': AppRole.player.asString,
      'lang': lang,
      'blocked': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<List<AppUser>> watchAllUsers() => _firestore
      .collection('users')
      .snapshots()
      .map((s) => s.docs.map((d) => AppUser.fromMap(d.id, d.data())).toList()
        ..sort((a, b) => a.firstName.compareTo(b.firstName)));

  @override
  Future<void> updateRole(String uid, AppRole role) =>
      _doc(uid).update({'role': role.asString});

  @override
  Future<void> setBlocked(String uid, bool blocked) =>
      _doc(uid).update({'blocked': blocked});

  @override
  Future<void> assignClub(String uid, String? clubId) =>
      _doc(uid).update({'clubId': clubId});
}
