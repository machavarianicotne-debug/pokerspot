import 'package:flutter_test/flutter_test.dart';
import 'package:pokerspot/features/admin/data/fake_admin_repository.dart';
import 'package:pokerspot/features/auth/data/fake_users_repository.dart';
import 'package:pokerspot/features/auth/domain/app_user.dart';
import 'package:pokerspot/features/clubs/data/fake_clubs_repository.dart';
import 'package:pokerspot/features/clubs/domain/club.dart';

const _draft = Club(
  id: '', name: 'New Club', city: 'Tbilisi', address: 'A', photoUrl: null,
  hoursText: 'H', phone: 'P', enabled: true,
);

void main() {
  test('clubs: create -> watchAllClubs, enable/disable, update', () async {
    final repo = FakeClubsRepository();
    final id = await repo.createClub(_draft);
    expect((await repo.watchAllClubs().first).length, 1);
    expect((await repo.watchEnabledClubs().first).length, 1);

    await repo.setClubEnabled(id, false);
    expect(await repo.watchEnabledClubs().first, isEmpty);
    expect((await repo.watchAllClubs().first).length, 1); // still there, disabled

    await repo.updateClub((await repo.watchAllClubs().first).first.copyWith(name: 'Renamed'));
    expect((await repo.watchAllClubs().first).first.name, 'Renamed');
  });

  test('users: watchAllUsers, updateRole, setBlocked, assign/clear club', () async {
    final repo = FakeUsersRepository();
    await repo.createProfile(uid: 'u1', phone: '+1', firstName: 'Nino', lastName: 'K', lang: 'en');
    expect((await repo.watchAllUsers().first).length, 1);

    await repo.updateRole('u1', AppRole.pitboss);
    expect((await repo.getUser('u1'))!.role, AppRole.pitboss);

    await repo.assignClub('u1', 'club-9');
    expect((await repo.getUser('u1'))!.clubId, 'club-9');
    await repo.assignClub('u1', null);
    expect((await repo.getUser('u1'))!.clubId, isNull);

    await repo.setBlocked('u1', true);
    expect((await repo.getUser('u1'))!.blocked, isTrue);
  });

  test('admin: log appends; watchRecent returns newest first', () async {
    final repo = FakeAdminRepository();
    await repo.log(actorUid: 'admin', action: 'club.create', target: 'club-1');
    await repo.log(actorUid: 'admin', action: 'user.block', target: 'u1');
    final recent = await repo.watchRecent(limit: 50).first;
    expect(recent.length, 2);
    expect(recent.first.action, 'user.block'); // newest first
  });
}
