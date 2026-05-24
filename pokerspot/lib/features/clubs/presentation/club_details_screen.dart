import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/features/clubs/domain/club.dart';
import 'package:pokerspot/features/clubs/presentation/providers.dart';
import 'package:pokerspot/features/floor/domain/poker_table.dart';
import 'package:pokerspot/features/floor/domain/stakes.dart';
import 'package:pokerspot/features/floor/domain/waitlist_entry.dart';
import 'package:pokerspot/features/floor/presentation/providers.dart';
import 'package:pokerspot/shared/widgets/ps_button.dart';
import 'package:pokerspot/shared/widgets/ps_card.dart';
import 'package:pokerspot/shared/widgets/ps_scaffold.dart';
import 'package:pokerspot/shared/widgets/ps_sheet.dart';

class ClubDetailsScreen extends ConsumerWidget {
  const ClubDetailsScreen({super.key, required this.clubId});
  final String clubId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final clubAsync = ref.watch(clubProvider(clubId));
    return PsScaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Nav(title: clubAsync.valueOrNull?.name ?? l10n.clubsListTitle),
            Expanded(
              child: clubAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: PsColors.accentPrimary),
                ),
                error: (e, _) => Center(
                  child: Text('$e', style: const TextStyle(color: PsColors.statusLive)),
                ),
                data: (club) => club == null
                    ? Center(
                        child: Text(l10n.noClubsYet,
                            style: TextStyle(color: PsColors.textMuted)))
                    : _Details(club: club),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Glass nav: a round back button + the club name title (mockup `.nav-back`).
class _Nav extends StatelessWidget {
  const _Nav({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(PsSpacing.s4, PsSpacing.s2, PsSpacing.s5, PsSpacing.s3),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: l10n.backToClubs,
            child: GestureDetector(
              onTap: () => context.go('/home'),
              child: ClipOval(
                child: BackdropFilter(
                  filter: PsGlass.backdrop(PsGlass.blurThin),
                  child: Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: PsColors.glassRegular,
                      border: Border.all(color: PsColors.glassBorder),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new, size: 16, color: PsColors.text),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: PsSpacing.s3),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: PsType.body,
                fontWeight: PsType.weightBold,
                letterSpacing: PsType.trackingSnug,
                color: PsColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.club});
  final Club club;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return ListView(
      padding: const EdgeInsets.all(PsSpacing.s5),
      children: [
        _InfoCard(club: club),
        const SizedBox(height: PsSpacing.s5),
        PsButton(
          key: const Key('joinWaitlistBtn'),
          label: l10n.joinWaitlist,
          icon: Icons.event_seat,
          onPressed: () => unawaited(
            PsSheet.show<void>(context, child: _StakePickerSheet(clubId: club.id)),
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.club});
  final Club club;

  @override
  Widget build(BuildContext context) {
    return PsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _LogoOrb(name: club.name),
              const SizedBox(width: PsSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      club.name,
                      style: const TextStyle(
                        fontSize: PsType.title,
                        fontWeight: PsType.weightBlack,
                        letterSpacing: PsType.trackingSnug,
                        color: PsColors.text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      club.city,
                      style: TextStyle(
                        fontSize: PsType.subhead,
                        fontWeight: PsType.weightMedium,
                        color: PsColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: PsSpacing.s3),
          Container(height: 1, color: PsColors.glassBorder),
          const SizedBox(height: PsSpacing.s3),
          _InfoRow(icon: Icons.place_outlined, value: club.address),
          const SizedBox(height: PsSpacing.s2),
          _PhoneRow(phone: club.phone),
          const SizedBox(height: PsSpacing.s2),
          _InfoRow(icon: Icons.schedule, value: club.hoursText),
        ],
      ),
    );
  }
}

class _LogoOrb extends StatelessWidget {
  const _LogoOrb({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final letter = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(PsRadii.md),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [PsColors.accentPrimary, PsColors.accentSecondary],
        ),
        boxShadow: PsElevation.e2,
      ),
      child: Text(
        letter,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: PsType.weightBlack,
          color: PsColors.onAccent,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.value});
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: PsColors.textMuted),
        const SizedBox(width: PsSpacing.s3),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: PsType.body, color: PsColors.textMuted),
          ),
        ),
      ],
    );
  }
}

/// The callable phone row (accent-secondary) with a copy action.
class _PhoneRow extends StatelessWidget {
  const _PhoneRow({required this.phone});
  final String phone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            key: const Key('phoneTile'),
            onTap: () {
              // Normalize to digits + a single leading '+' — the tel: URI spec
              // forbids spaces (the seeded numbers contain them), which made some
              // browsers ignore the link entirely.
              final tel = phone.replaceAll(RegExp(r'[^\d+]'), '');
              unawaited(launchUrl(Uri.parse('tel:$tel')));
            },
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                const Icon(Icons.call, size: 18, color: PsColors.accentSecondary),
                const SizedBox(width: PsSpacing.s3),
                Expanded(
                  child: Text(
                    phone,
                    style: const TextStyle(
                      fontSize: PsType.body,
                      fontWeight: PsType.weightBold,
                      color: PsColors.accentSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        GestureDetector(
          key: const Key('copyPhoneBtn'),
          onTap: () {
            // Copy the display-formatted number (with spaces) — easier to read.
            unawaited(Clipboard.setData(ClipboardData(text: phone)));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.phoneCopied)),
            );
          },
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.all(PsSpacing.s2),
            child: Icon(Icons.copy, size: 18, color: PsColors.textMuted),
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet listing the club's distinct stakes (from its tables). Tapping a
/// stake joins the waitlist for it; a stake the player already waits for shows
/// "Waiting" and is not tappable.
class _StakePickerSheet extends ConsumerWidget {
  const _StakePickerSheet({required this.clubId});
  final String clubId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final tables = ref.watch(tablesProvider(clubId)).valueOrNull ?? const <PokerTable>[];
    final mine = ref.watch(myWaitlistProvider).valueOrNull ?? const <WaitlistEntry>[];

    final byLabel = <String, Stakes>{};
    for (final t in tables) {
      byLabel[t.stakes.label] = t.stakes;
    }
    final stakes = byLabel.values.toList();
    final myLabels =
        mine.where((e) => e.clubId == clubId).map((e) => e.stakes.label).toSet();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.chooseStake,
          style: const TextStyle(
            fontSize: PsType.headline,
            fontWeight: PsType.weightBold,
            color: PsColors.text,
          ),
        ),
        const SizedBox(height: PsSpacing.s3),
        if (stakes.isEmpty)
          Padding(
            padding: const EdgeInsets.all(PsSpacing.s4),
            child: Text(l10n.noStakesYet, style: TextStyle(color: PsColors.textMuted)),
          )
        else
          for (final s in stakes)
            _StakeRow(
              stakes: s,
              waiting: myLabels.contains(s.label),
              onJoin: myLabels.contains(s.label)
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(context);
                      final uid = ref.read(authRepositoryProvider).currentUid;
                      final user = ref.read(currentUserProvider).valueOrNull;
                      if (uid != null) {
                        await ref.read(waitlistRepositoryProvider).join(
                              clubId: clubId,
                              playerUid: uid,
                              playerName: user == null
                                  ? ''
                                  : '${user.firstName} ${user.lastName}'.trim(),
                              stakes: s,
                            );
                      }
                      navigator.pop();
                      messenger.showSnackBar(SnackBar(content: Text(l10n.joinedWaitlist)));
                    },
            ),
      ],
    );
  }
}

class _StakeRow extends StatelessWidget {
  const _StakeRow({required this.stakes, required this.waiting, this.onJoin});
  final Stakes stakes;
  final bool waiting;
  final Future<void> Function()? onJoin;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: PsSpacing.s2),
      child: GestureDetector(
        key: Key('stake_${stakes.label}'),
        onTap: onJoin == null ? null : () => unawaited(onJoin!()),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: PsSpacing.s4, vertical: PsSpacing.s3),
          decoration: BoxDecoration(
            color: PsColors.glassThin,
            borderRadius: BorderRadius.circular(PsRadii.md),
            border: Border.all(color: PsColors.glassBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  stakes.label,
                  style: const TextStyle(
                    fontSize: PsType.body,
                    fontWeight: PsType.weightBold,
                    color: PsColors.text,
                  ),
                ),
              ),
              if (waiting)
                Text(
                  l10n.statusWaiting,
                  style: const TextStyle(
                    fontSize: PsType.subhead,
                    fontWeight: PsType.weightBold,
                    color: PsColors.accentSecondary,
                  ),
                )
              else
                const Icon(Icons.add, color: PsColors.accentPrimary),
            ],
          ),
        ),
      ),
    );
  }
}
