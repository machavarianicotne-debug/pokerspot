import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/admin/presentation/providers.dart';
import 'package:pokerspot/features/auth/domain/app_user.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/features/clubs/domain/club.dart';
import 'package:pokerspot/features/clubs/presentation/providers.dart';
import 'package:pokerspot/shared/widgets/ps_avatar.dart';
import 'package:pokerspot/shared/widgets/ps_button.dart';
import 'package:pokerspot/shared/widgets/ps_card.dart';
import 'package:pokerspot/shared/widgets/ps_filter_pill.dart';
import 'package:pokerspot/shared/widgets/ps_list_tile.dart';
import 'package:pokerspot/shared/widgets/ps_overline.dart';
import 'package:pokerspot/shared/widgets/ps_text_field.dart';

String _norm(String phone) => phone.replaceAll(RegExp(r'[^\d+]'), '');

String _initials(String s) {
  final t = s.trim();
  return t.isEmpty ? '?' : t[0].toUpperCase();
}

/// Super Admin "Pit Bosses" tab (mockup `super-admin-assign-pitboss`): active
/// assignments + assign an existing user (by phone) to a club. Invites for
/// not-yet-registered phones are deferred (no invites collection yet — spec §7).
class AdminAssignPitBossScreen extends ConsumerStatefulWidget {
  const AdminAssignPitBossScreen({super.key});

  @override
  ConsumerState<AdminAssignPitBossScreen> createState() => _State();
}

class _State extends ConsumerState<AdminAssignPitBossScreen> {
  final _phone = TextEditingController();
  String? _clubId;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  void _assign(List<AppUser> users, List<Club> clubs) {
    final messenger = ScaffoldMessenger.of(context);
    final actor = ref.read(currentUserProvider).valueOrNull?.uid ?? 'admin';
    final phone = _norm(_phone.text);
    final clubId = _clubId ?? (clubs.isNotEmpty ? clubs.first.id : null);
    if (phone.isEmpty || clubId == null) return;
    AppUser? match;
    for (final u in users) {
      if (_norm(u.phone) == phone) match = u;
    }
    if (match == null) {
      messenger.showSnackBar(SnackBar(content: Text(AppL10n.of(context).noUserForPhone)));
      return;
    }
    unawaited(ref.read(usersRepositoryProvider).updateRole(match.uid, AppRole.pitboss));
    unawaited(ref.read(usersRepositoryProvider).assignClub(match.uid, clubId));
    unawaited(ref.read(adminRepositoryProvider).log(
        actorUid: actor, action: 'pitboss.assign', target: match.uid, meta: {'clubId': clubId}));
    _phone.clear();
  }

  void _remove(AppUser u, String actor) {
    unawaited(ref.read(usersRepositoryProvider).updateRole(u.uid, AppRole.player));
    unawaited(ref.read(usersRepositoryProvider).assignClub(u.uid, null));
    unawaited(ref.read(adminRepositoryProvider).log(
        actorUid: actor, action: 'pitboss.remove', target: u.uid));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final users = ref.watch(allUsersProvider).valueOrNull ?? const <AppUser>[];
    final clubs = ref.watch(allClubsProvider).valueOrNull ?? const <Club>[];
    final actor = ref.read(currentUserProvider).valueOrNull?.uid ?? 'admin';
    final active = users.where((u) => u.role == AppRole.pitboss).toList();
    String clubName(String? id) =>
        clubs.where((c) => c.id == id).map((c) => c.name).firstOrNull ?? (id ?? '—');
    _clubId ??= clubs.isNotEmpty ? clubs.first.id : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(PsSpacing.s4, PsSpacing.s4, PsSpacing.s4, 96),
      children: [
        PsOverline('${l10n.activeAssignmentsHeader} · ${active.length}'),
        const SizedBox(height: PsSpacing.s3),
        for (final u in active)
          Padding(
            padding: const EdgeInsets.only(bottom: PsSpacing.s2),
            child: PsCard(
              key: Key('pb_${u.uid}'),
              child: PsListTile(
                leading: PsAvatar(initials: _initials('${u.firstName} ${u.lastName}'.trim())),
                title: '${u.firstName} ${u.lastName}'.trim(),
                subtitle: clubName(u.clubId),
                trailing: GestureDetector(
                  key: Key('removePb_${u.uid}'),
                  onTap: () => _remove(u, actor),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(PsSpacing.s1),
                    child: Text(l10n.removeLabel,
                        style: const TextStyle(
                            fontSize: PsType.subhead,
                            fontWeight: PsType.weightBold,
                            color: PsColors.statusLive)),
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: PsSpacing.s5),
        PsOverline(l10n.assignPitBossHeader),
        const SizedBox(height: PsSpacing.s3),
        PsTextField(controller: _phone, keyboardType: TextInputType.phone, hintText: l10n.phoneHint),
        const SizedBox(height: PsSpacing.s3),
        Wrap(
          spacing: PsSpacing.s2,
          runSpacing: PsSpacing.s2,
          children: [
            for (final c in clubs)
              PsFilterPill(
                label: c.name,
                active: _clubId == c.id,
                onTap: () => setState(() => _clubId = c.id),
              ),
          ],
        ),
        const SizedBox(height: PsSpacing.s4),
        SizedBox(
          width: double.infinity,
          child: PsButton(
            key: const Key('assignPbBtn'),
            label: l10n.assignBtn,
            onPressed: () => _assign(users, clubs),
          ),
        ),
      ],
    );
  }
}
