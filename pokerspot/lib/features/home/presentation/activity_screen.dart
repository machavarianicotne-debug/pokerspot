import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/clubs/domain/club.dart';
import 'package:pokerspot/features/clubs/presentation/providers.dart';
import 'package:pokerspot/features/floor/domain/reservation.dart';
import 'package:pokerspot/features/floor/domain/session.dart';
import 'package:pokerspot/features/floor/presentation/my_waitlist_banner.dart';
import 'package:pokerspot/features/floor/presentation/providers.dart';
import 'package:pokerspot/shared/widgets/ps_card.dart';
import 'package:pokerspot/shared/widgets/ps_countdown.dart';
import 'package:pokerspot/shared/widgets/ps_overline.dart';

/// Playtime as compact hours + minutes (mockup `fmtHM`): "1h30m" / "45m" / "2h".
/// Units are localized and tiny (h/m, ს/წ, ч/м) per the player request.
String _fmtPlaytime(int minutes, AppL10n l10n) {
  final h = minutes ~/ 60, m = minutes % 60;
  if (h > 0 && m > 0) return '$h${l10n.hoursTiny}$m${l10n.minutesTiny}';
  if (h > 0) return '$h${l10n.hoursTiny}';
  return '$m${l10n.minutesTiny}';
}

/// The player's Activity tab (mockup `my-status`): a live "now playing" card,
/// the waitlist + held reservations, and a playtime summary (today / lifetime /
/// by club) that ticks live while a session is open.
class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final entries = ref.watch(myWaitlistProvider).valueOrNull ?? const [];
    final sessions = ref.watch(mySessionProvider).valueOrNull ?? const <Session>[];
    final reservations = ref.watch(myReservationsProvider).valueOrNull ?? const <Reservation>[];
    final allSessions = ref.watch(myAllSessionsProvider).valueOrNull ?? const <Session>[];
    final clubs = ref.watch(clubsListProvider).valueOrNull ?? const <Club>[];
    final clubName = {for (final c in clubs) c.id: c.name};

    if (entries.isEmpty && sessions.isEmpty && reservations.isEmpty && allSessions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(PsSpacing.s5),
          child: Text(
            l10n.noActivityYet,
            textAlign: TextAlign.center,
            style: TextStyle(color: PsColors.textMuted, fontSize: PsType.body),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(PsSpacing.s4, PsSpacing.s2, PsSpacing.s4, 96),
      children: [
        for (final s in sessions)
          Padding(
            padding: const EdgeInsets.only(bottom: PsSpacing.s3),
            child: _NowPlayingCard(session: s, clubName: clubName[s.clubId] ?? ''),
          ),
        for (final r in reservations)
          Padding(
            padding: const EdgeInsets.only(bottom: PsSpacing.s3),
            child: _ReservationCard(reservation: r),
          ),
        const MyWaitlistBanner(),
        if (allSessions.isNotEmpty) ...[
          const SizedBox(height: PsSpacing.s2),
          Align(alignment: Alignment.centerLeft, child: PsOverline(l10n.myPlaytime)),
          const SizedBox(height: PsSpacing.s3),
          _PlaytimeCard(sessions: allSessions, clubName: clubName),
        ],
      ],
    );
  }
}

/// Live "currently playing" card — a count-up h:mm:ss timer since the Pit Boss
/// seated the player; it stops (card disappears) when the session is ended.
class _NowPlayingCard extends StatefulWidget {
  const _NowPlayingCard({required this.session, required this.clubName});
  final Session session;
  final String clubName;

  @override
  State<_NowPlayingCard> createState() => _NowPlayingCardState();
}

class _NowPlayingCardState extends State<_NowPlayingCard> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _hms(Duration d) =>
      '${d.inHours}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final s = widget.session;
    final elapsed = s.elapsedAt(DateTime.now()) ?? Duration.zero;
    final meta = [
      if (widget.clubName.isNotEmpty) widget.clubName,
      s.stakes.label,
      '#${s.seatNumber}',
    ].join(' · ');
    return PsCard(
      accentRail: PsColors.statusLive,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🟢 ${l10n.nowPlaying}',
                    style: const TextStyle(
                        fontSize: PsType.headline,
                        fontWeight: PsType.weightBlack,
                        color: PsColors.text)),
                const SizedBox(height: 2),
                Text(meta, style: TextStyle(fontSize: PsType.caption, color: PsColors.textMuted)),
                const SizedBox(height: 6),
                Text(_hms(elapsed),
                    style: const TextStyle(
                        fontSize: PsType.title,
                        fontWeight: PsType.weightBlack,
                        color: PsColors.statusLive,
                        fontFeatures: [FontFeature.tabularFigures()])),
                const SizedBox(height: 6),
                Text(l10n.nowPlayingHint,
                    style: TextStyle(
                        fontSize: PsType.caption,
                        fontStyle: FontStyle.italic,
                        color: PsColors.textFaint)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Playtime summary: Today + Lifetime totals (ticking live while a session is
/// open) and a per-club breakdown with bars.
class _PlaytimeCard extends StatefulWidget {
  const _PlaytimeCard({required this.sessions, required this.clubName});
  final List<Session> sessions;
  final Map<String, String> clubName;

  @override
  State<_PlaytimeCard> createState() => _PlaytimeCardState();
}

class _PlaytimeCardState extends State<_PlaytimeCard> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Tick only while a session is still open (live total) — otherwise static.
    if (widget.sessions.any((s) => s.endedAt == null && s.startedAt != null)) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    var lifetimeMin = 0;
    var todayMin = 0;
    final byClub = <String, int>{};
    for (final s in widget.sessions) {
      final start = s.startedAt;
      if (start == null) continue;
      final end = s.endedAt ?? now; // active session counts up to now
      final mins = end.difference(start).inMinutes;
      if (mins <= 0) continue;
      lifetimeMin += mins;
      byClub[s.clubId] = (byClub[s.clubId] ?? 0) + mins;
      // Today = only the part of the session that falls within today (handles
      // sessions that started earlier / span midnight), not the whole session.
      final tStart = start.isBefore(today) ? today : start;
      if (end.isAfter(tStart)) todayMin += end.difference(tStart).inMinutes;
    }
    final ranked = byClub.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final maxMin = ranked.isEmpty ? 1 : ranked.first.value;

    return PsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _total(_fmtPlaytime(todayMin, l10n), l10n.todayLabel, PsColors.accentPrimary)),
              Expanded(
                child: _total('${_fmtPlaytime(lifetimeMin, l10n)} · ${widget.sessions.length}',
                    l10n.lifetimeLabel, PsColors.text),
              ),
            ],
          ),
          const SizedBox(height: PsSpacing.s4),
          PsOverline(l10n.byClubLabel),
          const SizedBox(height: PsSpacing.s2),
          for (final e in ranked)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(widget.clubName[e.key] ?? '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: PsType.subhead,
                            fontWeight: PsType.weightBold,
                            color: PsColors.text)),
                  ),
                  Container(
                    width: 70,
                    height: 6,
                    decoration: BoxDecoration(
                      color: PsColors.glassRegular,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (e.value / maxMin).clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [PsColors.accentSecondary, PsColors.accentPrimary],
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: PsSpacing.s3),
                  SizedBox(
                    width: 64,
                    child: Text(_fmtPlaytime(e.value, l10n),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontSize: PsType.subhead,
                            fontWeight: PsType.weightBlack,
                            color: PsColors.accentPrimary,
                            fontFeatures: [FontFeature.tabularFigures()])),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _total(String value, String label, Color color) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: PsType.display2,
                  fontWeight: PsType.weightBlack,
                  color: color,
                  height: 1,
                  fontFeatures: const [FontFeature.tabularFigures()])),
          const SizedBox(height: 6),
          PsOverline(label),
        ],
      );
}

class _ReservationCard extends ConsumerWidget {
  const _ReservationCard({required this.reservation});
  final Reservation reservation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final until = reservation.heldUntil;
    return PsCard(
      accentRail: PsColors.accentSecondary,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reservation.stakes.label,
                    style: const TextStyle(
                        fontSize: PsType.body,
                        fontWeight: PsType.weightBold,
                        color: PsColors.text)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text('${l10n.reservedBadge} · ',
                        style: TextStyle(fontSize: PsType.subhead, color: PsColors.textMuted)),
                    if (until != null)
                      PsCountdown(deadline: until, color: PsColors.accentSecondary),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            key: Key('cancelReservation_${reservation.id}'),
            onTap: () => unawaited(ref.read(reservationsRepositoryProvider).cancel(reservation.id)),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: PsSpacing.s2, vertical: PsSpacing.s1),
              child: Text(
                l10n.cancelWaitlist,
                style: const TextStyle(
                    fontSize: PsType.subhead,
                    fontWeight: PsType.weightBold,
                    color: PsColors.statusLive),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
