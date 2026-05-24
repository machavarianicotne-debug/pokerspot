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
import 'package:pokerspot/features/chat/presentation/chat_thread_screen.dart';
import 'package:pokerspot/features/floor/domain/poker_table.dart';
import 'package:pokerspot/features/floor/domain/stakes.dart';
import 'package:pokerspot/features/floor/domain/waitlist_entry.dart';
import 'package:pokerspot/features/floor/presentation/providers.dart';
import 'package:pokerspot/features/floor/presentation/reservation_flow_screen.dart';
import 'package:pokerspot/shared/widgets/ps_button.dart';
import 'package:pokerspot/shared/widgets/ps_card.dart';
import 'package:pokerspot/shared/widgets/ps_metric.dart';
import 'package:pokerspot/shared/widgets/ps_overline.dart';
import 'package:pokerspot/shared/widgets/ps_scaffold.dart';

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
        const SizedBox(height: PsSpacing.s4),
        _ChatEntry(club: club),
        const SizedBox(height: PsSpacing.s5),
        _GamesSection(club: club),
        const SizedBox(height: PsSpacing.s4),
        PsButton(
          key: const Key('reserveSeatBtn'),
          label: l10n.reserveSeat,
          icon: Icons.event_available,
          variant: PsButtonVariant.secondary,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => ReservationFlowScreen(clubId: club.id)),
          ),
        ),
      ],
    );
  }
}

/// "Chat with Pit Boss" entry row → opens the 1-on-1 thread for this player.
class _ChatEntry extends ConsumerWidget {
  const _ChatEntry({required this.club});
  final Club club;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    return PsCard(
      key: const Key('chatEntry'),
      onTap: () {
        final uid = ref.read(authRepositoryProvider).currentUid;
        if (uid == null) return;
        final user = ref.read(currentUserProvider).valueOrNull;
        final name = user == null ? '' : '${user.firstName} ${user.lastName}'.trim();
        Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => ChatThreadScreen(
            clubId: club.id,
            playerUid: uid,
            playerName: name,
            title: club.name,
          ),
        ));
      },
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(PsRadii.md),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [PsColors.accentPrimary, PsColors.accentSecondary],
              ),
            ),
            child: const Icon(Icons.chat_bubble_outline, size: 20, color: PsColors.onAccent),
          ),
          const SizedBox(width: PsSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.chatWithPitBoss,
                    style: const TextStyle(
                        fontSize: PsType.body,
                        fontWeight: PsType.weightBold,
                        color: PsColors.text)),
                const SizedBox(height: 2),
                Text(l10n.chatEntrySub,
                    style: TextStyle(fontSize: PsType.caption, color: PsColors.textMuted)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, size: 18, color: PsColors.textFaint),
        ],
      ),
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

String _symbol(String currency) =>
    currency == 'USD' ? '\$' : currency == 'EUR' ? '€' : '₾';
String _money(String currency, num? v) => v == null ? '—' : '${_symbol(currency)}${v % 1 == 0 ? v.toInt() : v}';

/// "Live games · N stakes" + a card per stake (mockup `player-club-details`),
/// or the "No games running" empty state. Built from the club's tables (which a
/// player may read), with open-seats / waitlist counts overlaid from the
/// denormalized club.games (the player can't read other clubs' sessions).
class _GamesSection extends ConsumerWidget {
  const _GamesSection({required this.club});
  final Club club;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final tables = ref.watch(tablesProvider(club.id)).valueOrNull ?? const <PokerTable>[];
    final mine = (ref.watch(myWaitlistProvider).valueOrNull ?? const <WaitlistEntry>[])
        .where((e) => e.clubId == club.id)
        .map((e) => e.stakes.label)
        .toSet();

    // Group the club's open tables by stake (source of truth for what's running).
    final byLabel = <String, List<PokerTable>>{};
    for (final t in tables.where((t) => t.open)) {
      byLabel.putIfAbsent(t.stakes.label, () => []).add(t);
    }
    final gamesByLabel = {for (final g in club.games) g.label: g};

    if (byLabel.isEmpty) {
      return _emptyState(l10n);
    }

    final labels = byLabel.keys.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: PsSpacing.s3),
          child: PsOverline('${l10n.liveGamesTitle} · ${labels.length} ${l10n.stakesLabel.toLowerCase()}'),
        ),
        for (final label in labels)
          _GameCard(
            clubId: club.id,
            stakes: byLabel[label]!.first.stakes,
            game: gamesByLabel[label],
            tableCount: byLabel[label]!.length,
            tableMinBuyIn: byLabel[label]!.first.minBuyIn,
            tableAvgStack: byLabel[label]!.first.avgStack,
            alreadyWaiting: mine.contains(label),
          ),
      ],
    );
  }

  Widget _emptyState(AppL10n l10n) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: PsSpacing.s3),
            child: PsOverline(l10n.liveGamesTitle),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: PsSpacing.s10, horizontal: PsSpacing.s5),
            decoration: BoxDecoration(
              color: PsColors.glassThin,
              borderRadius: BorderRadius.circular(PsRadii.lg),
              border: Border.all(color: PsColors.glassBorder, style: BorderStyle.solid),
            ),
            child: Column(
              children: [
                const Text('🪑', style: TextStyle(fontSize: 40)),
                const SizedBox(height: PsSpacing.s3),
                Text(l10n.noGamesTitle,
                    style: const TextStyle(
                        fontSize: PsType.headline,
                        fontWeight: PsType.weightBlack,
                        color: PsColors.text)),
                const SizedBox(height: PsSpacing.s2),
                Text(l10n.noGamesSub,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: PsType.subhead, color: PsColors.textMuted)),
              ],
            ),
          ),
        ],
      );
}

class _GameCard extends ConsumerWidget {
  const _GameCard({
    required this.clubId,
    required this.stakes,
    required this.game,
    required this.tableCount,
    required this.tableMinBuyIn,
    required this.tableAvgStack,
    required this.alreadyWaiting,
  });
  final String clubId;
  final Stakes stakes;
  final ClubGame? game;
  final int tableCount;
  final num? tableMinBuyIn;
  final num? tableAvgStack;
  final bool alreadyWaiting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final cur = stakes.currency;
    final tables = game?.tables ?? tableCount;
    final minBuyIn = game?.minBuyIn ?? tableMinBuyIn;
    final avgStack = game?.avgStack ?? tableAvgStack;
    final openSeats = game?.openSeats; // null until syncClubStats runs
    final waiting = game?.waiting;
    final full = openSeats == 0;
    final type = stakes.variant.label;

    return Padding(
      padding: const EdgeInsets.only(bottom: PsSpacing.s4),
      child: PsCard(
        key: Key('gameCard_${stakes.label}'),
        accentRail: full ? PsColors.statusFull : PsColors.accentPrimary,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(PsSpacing.s4, 14, PsSpacing.s4, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(stakes.label,
                            style: const TextStyle(
                                fontSize: PsType.headline,
                                fontWeight: PsType.weightBlack,
                                letterSpacing: PsType.trackingSnug,
                                color: PsColors.text)),
                        const SizedBox(height: 3),
                        Text(
                          '$type · ${l10n.minLabel} ${_money(cur, minBuyIn)} · '
                          '${l10n.avgStackLabel} ${_money(cur, avgStack)} · '
                          '$tables ${l10n.tablesMetric.toLowerCase()}',
                          style: TextStyle(
                              fontSize: PsType.caption,
                              fontWeight: PsType.weightMedium,
                              color: PsColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(PsSpacing.s4, 0, PsSpacing.s4, PsSpacing.s3),
              child: Row(
                children: [
                  if (full)
                    PsMetric(value: l10n.fullLabel, label: l10n.noSeatsLabel, variant: PsMetricVariant.full)
                  else
                    PsMetric(
                        value: openSeats?.toString() ?? '—',
                        label: l10n.openSeatsLabel,
                        variant: PsMetricVariant.hero),
                  const SizedBox(width: PsSpacing.s3),
                  PsMetric(value: '$tables', label: l10n.tablesMetric),
                  const SizedBox(width: PsSpacing.s3),
                  PsMetric(value: waiting?.toString() ?? '—', label: l10n.waitlistTitle),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(PsSpacing.s4, 0, PsSpacing.s4, PsSpacing.s4),
              child: PsButton(
                key: Key('joinGame_${stakes.label}'),
                label: alreadyWaiting ? l10n.statusWaiting : l10n.joinWaitlist,
                variant: alreadyWaiting ? PsButtonVariant.secondary : PsButtonVariant.primary,
                onPressed: alreadyWaiting ? null : () => _join(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _join(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final uid = ref.read(authRepositoryProvider).currentUid;
    if (uid == null) return;
    final user = ref.read(currentUserProvider).valueOrNull;
    unawaited(ref.read(waitlistRepositoryProvider).join(
          clubId: clubId,
          playerUid: uid,
          playerName: user == null ? '' : '${user.firstName} ${user.lastName}'.trim(),
          stakes: stakes,
        ));
    messenger.showSnackBar(SnackBar(content: Text(l10n.joinedWaitlist)));
  }
}
