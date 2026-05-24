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
import 'package:pokerspot/shared/widgets/ps_card.dart';
import 'package:pokerspot/shared/widgets/ps_filter_pill.dart';
import 'package:pokerspot/shared/widgets/ps_sheet.dart';
import 'package:pokerspot/shared/widgets/ps_text_field.dart';
import 'package:pokerspot/shared/widgets/ps_toggle.dart';

/// Super Admin "Users" tab: search, change role, block/unblock, assign a Pit
/// Boss to a club. Every change is audited.
class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final users = ref.watch(allUsersProvider).valueOrNull ?? const <AppUser>[];
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? users
        : users.where((u) =>
            '${u.firstName} ${u.lastName}'.toLowerCase().contains(q) ||
            u.phone.toLowerCase().contains(q)).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(PsSpacing.s4, PsSpacing.s4, PsSpacing.s4, 96),
      children: [
        PsTextField(
          key: const Key('userSearch'),
          hintText: l10n.searchUsersHint,
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: PsSpacing.s4),
        for (final u in filtered)
          Padding(
            padding: const EdgeInsets.only(bottom: PsSpacing.s3),
            child: _UserCard(user: u),
          ),
      ],
    );
  }
}

class _UserCard extends ConsumerWidget {
  const _UserCard({required this.user});
  final AppUser user;

  String _roleLabel(AppL10n l10n, AppRole r) {
    switch (r) {
      case AppRole.player:
        return l10n.playerHome;
      case AppRole.pitboss:
        return l10n.pitBossHome;
      case AppRole.superadmin:
        return l10n.superAdminHome;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final actor = ref.read(currentUserProvider).valueOrNull?.uid ?? 'admin';
    final name = '${user.firstName} ${user.lastName}'.trim();

    void setRole(AppRole r) {
      unawaited(ref.read(usersRepositoryProvider).updateRole(user.uid, r));
      unawaited(ref.read(adminRepositoryProvider).log(
          actorUid: actor, action: 'user.role', target: user.uid, meta: {'role': r.asString}));
    }

    return PsCard(
      key: Key('userCard_${user.uid}'),
      accentRail: user.blocked ? PsColors.statusFull : PsColors.accentSecondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name.isEmpty ? user.phone : name,
              style: const TextStyle(
                  fontSize: PsType.body, fontWeight: PsType.weightBold, color: PsColors.text)),
          if (user.phone.isNotEmpty)
            Text(user.phone,
                style: TextStyle(fontSize: PsType.subhead, color: PsColors.textMuted)),
          const SizedBox(height: PsSpacing.s3),
          Wrap(
            spacing: PsSpacing.s2,
            children: [
              for (final r in AppRole.values)
                PsFilterPill(
                  label: _roleLabel(l10n, r),
                  active: user.role == r,
                  onTap: () => setRole(r),
                ),
            ],
          ),
          const SizedBox(height: PsSpacing.s3),
          Row(
            children: [
              PsToggle(
                value: user.blocked,
                label: l10n.blockLabel.toUpperCase(),
                onChanged: (v) {
                  unawaited(ref.read(usersRepositoryProvider).setBlocked(user.uid, v));
                  unawaited(ref.read(adminRepositoryProvider).log(
                      actorUid: actor,
                      action: v ? 'user.block' : 'user.unblock',
                      target: user.uid));
                },
              ),
              const Spacer(),
              if (user.role == AppRole.pitboss)
                GestureDetector(
                  key: Key('assignClubBtn_${user.uid}'),
                  onTap: () => _assignClub(context, ref, actor),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(PsSpacing.s1),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.storefront, size: 16, color: PsColors.accentPrimary),
                        const SizedBox(width: 6),
                        Text(user.clubId ?? l10n.assignClubLabel,
                            style: const TextStyle(
                                fontSize: PsType.subhead,
                                fontWeight: PsType.weightBold,
                                color: PsColors.accentPrimary)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _assignClub(BuildContext context, WidgetRef ref, String actor) {
    final l10n = AppL10n.of(context);
    final clubs = ref.read(allClubsProvider).valueOrNull ?? const <Club>[];
    void assign(String? clubId) {
      unawaited(ref.read(usersRepositoryProvider).assignClub(user.uid, clubId));
      unawaited(ref.read(adminRepositoryProvider).log(
          actorUid: actor, action: 'user.assignClub', target: user.uid, meta: {'clubId': clubId}));
      Navigator.of(context).pop();
    }

    PsSheet.show<void>(
      context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.assignClubLabel,
              style: const TextStyle(
                  fontSize: PsType.headline, fontWeight: PsType.weightBold, color: PsColors.text)),
          const SizedBox(height: PsSpacing.s3),
          _AssignRow(label: l10n.noneLabel, onTap: () => assign(null)),
          for (final c in clubs) _AssignRow(label: c.name, onTap: () => assign(c.id)),
        ],
      ),
    );
  }
}

class _AssignRow extends StatelessWidget {
  const _AssignRow({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: PsSpacing.s2),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: PsSpacing.s4, vertical: PsSpacing.s3),
          decoration: BoxDecoration(
            color: PsColors.glassThin,
            borderRadius: BorderRadius.circular(PsRadii.md),
            border: Border.all(color: PsColors.glassBorder),
          ),
          child: Text(label,
              style: const TextStyle(
                  fontSize: PsType.body, fontWeight: PsType.weightBold, color: PsColors.text)),
        ),
      ),
    );
  }
}
