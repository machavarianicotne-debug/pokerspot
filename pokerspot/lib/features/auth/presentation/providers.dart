import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/features/auth/data/firebase_auth_repository.dart';
import 'package:pokerspot/features/auth/data/firebase_users_repository.dart';
import 'package:pokerspot/features/auth/domain/app_user.dart';
import 'package:pokerspot/features/auth/domain/auth_repository.dart';
import 'package:pokerspot/features/auth/domain/users_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
    (ref) => FirebaseAuthRepository(FirebaseAuth.instance));

final usersRepositoryProvider = Provider<UsersRepository>(
    (ref) => FirebaseUsersRepository(FirebaseFirestore.instance));

/// Current uid (null when signed out).
final uidProvider = StreamProvider<String?>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  return auth.uidChanges();
});

/// Current user profile (null when signed out OR no profile doc yet).
final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final uid = ref.watch(uidProvider).valueOrNull;
  if (uid == null) return Stream<AppUser?>.value(null);
  return ref.watch(usersRepositoryProvider).watchUser(uid);
});

/// Live list of ALL users (Super Admin management).
final allUsersProvider = StreamProvider<List<AppUser>>((ref) {
  return ref.watch(usersRepositoryProvider).watchAllUsers();
});
