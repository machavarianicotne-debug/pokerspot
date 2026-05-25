import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/auth/domain/app_user.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/features/floor/domain/session.dart';
import 'package:pokerspot/features/floor/presentation/providers.dart';
import 'package:pokerspot/shared/widgets/ps_avatar.dart';
import 'package:pokerspot/shared/widgets/ps_card.dart';
import 'package:pokerspot/shared/widgets/ps_overline.dart';
import 'package:pokerspot/shared/widgets/ps_segmented.dart';
import 'package:pokerspot/shared/widgets/ps_sheet.dart';
import 'package:pokerspot/shared/widgets/ps_text_field.dart';

class _Stat {
  _Stat(this.uid, this.name, this.walkIn);
  final String uid;
  final String name;
  final bool walkIn;
  int sessions = 0;
  int minutes = 0;
  double get hours => minutes / 60;
}

/// Playtime as hours + minutes (e.g. "2h 15m" / "1h" / "45m") — not a bare
/// decimal hour. Units are localized (h/m, სთ/წთ, ч/м).
String _fmtHm(int minutes, AppL10n l10n) {
  final h = minutes ~/ 60, m = minutes % 60;
  if (h > 0 && m > 0) return '$h${l10n.hoursShort} $m${l10n.minutesShort}';
  if (h > 0) return '$h${l10n.hoursShort}';
  return '$m${l10n.minutesShort}';
}

/// Pit Boss Stats tab (mockup `pit-boss-stats`): a registered / walk-in
/// leaderboard aggregated from the club's sessions (count + total hours).
class PitBossStatsScreen extends ConsumerStatefulWidget {
  const PitBossStatsScreen({super.key});

  @override
  ConsumerState<PitBossStatsScreen> createState() => _PitBossStatsScreenState();
}

class _PitBossStatsScreenState extends ConsumerState<PitBossStatsScreen> {
  bool _walkIn = false;
  final _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  String _initials(String s) {
    final parts = s.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return (parts.length == 1
            ? (parts.first.length >= 2 ? parts.first.substring(0, 2) : parts.first)
            : parts.first[0] + parts.last[0])
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final clubId = ref.watch(currentUserProvider).valueOrNull?.clubId;
    if (clubId == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(PsSpacing.s5),
          child: Text(l10n.noClubAssigned,
              textAlign: TextAlign.center,
              style: TextStyle(color: PsColors.textMuted, fontSize: PsType.body)),
        ),
      );
    }
    final sessions = ref.watch(clubSessionsAllProvider(clubId)).valueOrNull ?? const <Session>[];
    final now = DateTime.now();
    final byPlayer = <String, _Stat>{};
    final byPlayerSessions = <String, List<Session>>{};
    for (final s in sessions) {
      final walkIn = s.playerUid.startsWith('walk-in:');
      final stat = byPlayer.putIfAbsent(s.playerUid, () => _Stat(s.playerUid, s.playerName, walkIn));
      stat.sessions += 1;
      stat.minutes += s.elapsedAt(now)?.inMinutes ?? 0;
      (byPlayerSessions[s.playerUid] ??= []).add(s);
    }
    final query = _q.text.trim().toLowerCase();
    final rows = byPlayer.values
        .where((s) => s.walkIn == _walkIn)
        .where((s) => query.isEmpty || s.name.toLowerCase().contains(query))
        .toList()
      ..sort((a, b) => b.minutes.compareTo(a.minutes));

    return ListView(
      padding: const EdgeInsets.fromLTRB(PsSpacing.s4, PsSpacing.s4, PsSpacing.s4, 96),
      children: [
        PsSegmented<bool>(
          value: _walkIn,
          segments: [
            PsSegment(false, l10n.registeredLabel),
            PsSegment(true, l10n.walkInLabel),
          ],
          onChanged: (v) => setState(() => _walkIn = v),
        ),
        const SizedBox(height: PsSpacing.s3),
        PsTextField(
          key: const Key('statsSearch'),
          controller: _q,
          hintText: l10n.searchUsersHint,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: PsSpacing.s4),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: PsSpacing.s8),
            child: Text(l10n.noStatsYet,
                textAlign: TextAlign.center,
                style: TextStyle(color: PsColors.textMuted, fontSize: PsType.body)),
          )
        else
          for (var i = 0; i < rows.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: PsSpacing.s2),
              child: _StatRow(
                  rank: i + 1,
                  stat: rows[i],
                  initials: _initials(rows[i].name),
                  sessions: byPlayerSessions[rows[i].uid] ?? const <Session>[],
                  l10n: l10n),
            ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow(
      {required this.rank,
      required this.stat,
      required this.initials,
      required this.sessions,
      required this.l10n});
  final int rank;
  final _Stat stat;
  final String initials;
  final List<Session> sessions;
  final AppL10n l10n;

  @override
  Widget build(BuildContext context) {
    final avgMin = stat.sessions == 0 ? 0 : (stat.minutes / stat.sessions).round();
    return PsCard(
      key: Key('statRow_${stat.uid}'),
      onTap: () => _PlayerStatsSheet.show(context, stat: stat, sessions: sessions),
      child: Row(
        children: [
          SizedBox(
            width: 26,
            child: Text('$rank',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: PsType.headline,
                    fontWeight: PsType.weightBlack,
                    color: rank == 1 ? PsColors.accentPrimary : PsColors.textFaint)),
          ),
          const SizedBox(width: PsSpacing.s2),
          PsAvatar(initials: initials, size: 40),
          const SizedBox(width: PsSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stat.name.isEmpty ? '—' : stat.name,
                    style: const TextStyle(
                        fontSize: PsType.body, fontWeight: PsType.weightBold, color: PsColors.text)),
                const SizedBox(height: 2),
                Text('${stat.sessions} ${l10n.sessionsLabel.toLowerCase()} · ${l10n.avgMinLabel} $avgMin${l10n.minutesShort}',
                    style: TextStyle(fontSize: PsType.caption, color: PsColors.textMuted)),
              ],
            ),
          ),
          Text(_fmtHm(stat.minutes, l10n),
              style: const TextStyle(
                  fontSize: PsType.headline,
                  fontWeight: PsType.weightBlack,
                  color: PsColors.accentPrimary)),
        ],
      ),
    );
  }
}

/// Per-player detail (mockup stats drill-down): name + phone, total playtime and
/// a by-day breakdown. Opened by tapping a leaderboard row.
class _PlayerStatsSheet extends ConsumerWidget {
  const _PlayerStatsSheet({required this.stat, required this.sessions});
  final _Stat stat;
  final List<Session> sessions;

  static void show(BuildContext context, {required _Stat stat, required List<Session> sessions}) {
    PsSheet.show<void>(context, child: _PlayerStatsSheet(stat: stat, sessions: sessions));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final now = DateTime.now();
    // Group this player's playtime by day (date -> minutes), newest first.
    final byDay = <DateTime, int>{};
    var total = 0;
    for (final s in sessions) {
      final start = s.startedAt;
      final mins = s.elapsedAt(now)?.inMinutes ?? 0;
      if (start == null || mins <= 0) continue;
      total += mins;
      final day = DateTime(start.year, start.month, start.day);
      byDay[day] = (byDay[day] ?? 0) + mins;
    }
    final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));

    // Phone (registered players only).
    String phone = '';
    for (final u in ref.watch(allUsersProvider).valueOrNull ?? const <AppUser>[]) {
      if (u.uid == stat.uid) {
        phone = u.phone;
        break;
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            PsAvatar(initials: stat.name.isEmpty ? '?' : stat.name[0].toUpperCase(), size: 48),
            const SizedBox(width: PsSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stat.name.isEmpty ? '—' : stat.name,
                      style: const TextStyle(
                          fontSize: PsType.headline,
                          fontWeight: PsType.weightBlack,
                          color: PsColors.text)),
                  if (phone.isNotEmpty)
                    Text(phone, style: TextStyle(fontSize: PsType.caption, color: PsColors.textMuted)),
                ],
              ),
            ),
            Text(_fmtHm(total, l10n),
                style: const TextStyle(
                    fontSize: PsType.title,
                    fontWeight: PsType.weightBlack,
                    color: PsColors.accentPrimary)),
          ],
        ),
        const SizedBox(height: PsSpacing.s4),
        PsOverline(l10n.sessionsLabel),
        const SizedBox(height: PsSpacing.s2),
        for (final d in days)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text('${d.day}.${d.month}.${d.year}',
                      style: const TextStyle(
                          fontSize: PsType.subhead,
                          fontWeight: PsType.weightBold,
                          color: PsColors.text)),
                ),
                Text(_fmtHm(byDay[d]!, l10n),
                    style: const TextStyle(
                        fontSize: PsType.subhead,
                        fontWeight: PsType.weightBlack,
                        color: PsColors.accentPrimary)),
              ],
            ),
          ),
      ],
    );
  }
}
