import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/floor/domain/poker_table.dart';
import 'package:pokerspot/features/floor/domain/session.dart';
import 'package:pokerspot/features/floor/domain/waitlist_entry.dart';
import 'package:pokerspot/features/admin/presentation/observe_table_screen.dart';
import 'package:pokerspot/features/floor/presentation/providers.dart';
import 'package:pokerspot/shared/widgets/ps_card.dart';
import 'package:pokerspot/shared/widgets/ps_scaffold.dart';

String _sym(String c) => c == 'USD' ? '\$' : c == 'EUR' ? '€' : '₾';
String _money(String c, num? v) => v == null ? '—' : '${_sym(c)}${v % 1 == 0 ? v.toInt() : v}';
String _fmt(num n) => n % 1 == 0 ? n.toInt().toString() : '$n';

/// Super Admin read-only live floor (mockup `super-admin-observe-club`): every
/// table with occupancy + waitlist, no actions. Admin may read all
/// tables/sessions/waitlist under the rules.
class ObserveClubScreen extends ConsumerWidget {
  const ObserveClubScreen({super.key, required this.clubId, required this.clubName});
  final String clubId;
  final String clubName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final tables = (ref.watch(tablesProvider(clubId)).valueOrNull ?? const <PokerTable>[]).toList()
      ..sort((a, b) => a.number.compareTo(b.number));
    final sessions = ref.watch(clubSessionsProvider(clubId)).valueOrNull ?? const <Session>[];
    final waitlist = ref.watch(clubWaitlistProvider(clubId)).valueOrNull ?? const <WaitlistEntry>[];

    return PsScaffold(
      body: SafeArea(
        child: Column(
          children: [
            _nav(context, l10n),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(PsSpacing.s5),
                children: [
                  _banner(l10n),
                  const SizedBox(height: PsSpacing.s4),
                  if (tables.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: PsSpacing.s6),
                      child: Center(
                        child: Text(l10n.noTablesYet, style: TextStyle(color: PsColors.textMuted)),
                      ),
                    )
                  else
                    for (final t in tables)
                      Padding(
                        padding: const EdgeInsets.only(bottom: PsSpacing.s3),
                        child: _tableCard(context, l10n, t, sessions, waitlist),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tableCard(BuildContext context, AppL10n l10n, PokerTable t, List<Session> sessions,
      List<WaitlistEntry> waitlist) {
    final occupied = sessions.where((s) => s.tableId == t.id).length;
    final waiting = waitlist.where((e) => e.stakes.label == t.stakes.label).length;
    final cur = t.stakes.currency;
    return PsCard(
      key: Key('observeTable_${t.id}'),
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => ObserveTableScreen(clubId: clubId, table: t),
      )),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(PsRadii.md),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [PsColors.accentPrimary, PsColors.accentSecondary],
                  ),
                ),
                child: Text('${t.number}',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: PsType.weightBlack, color: PsColors.onAccent)),
              ),
              const SizedBox(width: PsSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.stakes.label,
                        style: const TextStyle(
                            fontSize: PsType.headline,
                            fontWeight: PsType.weightBlack,
                            color: PsColors.text)),
                    const SizedBox(height: 2),
                    Text(
                      'blinds ${_fmt(t.stakes.smallBlind)}/${_fmt(t.stakes.bigBlind)} · '
                      '${l10n.avgStackLabel.toLowerCase()} ${_money(cur, t.avgStack)} · '
                      '${l10n.minLabel.toLowerCase()} ${_money(cur, t.minBuyIn)}',
                      style: TextStyle(fontSize: PsType.caption, color: PsColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: PsSpacing.s3),
          Row(
            children: [
              // mini seat dots
              for (var i = 0; i < t.seatCount; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < occupied ? PsColors.accentPrimary : PsColors.glassRegular,
                      border: Border.all(color: PsColors.glassBorder),
                    ),
                  ),
                ),
              const Spacer(),
              Text('$occupied/${t.seatCount}',
                  style: TextStyle(
                      fontSize: PsType.subhead,
                      fontWeight: PsType.weightBlack,
                      color: occupied >= t.seatCount ? PsColors.statusFull : PsColors.text)),
              if (waiting > 0) ...[
                const SizedBox(width: PsSpacing.s2),
                Text('$waiting ${l10n.waitingWord}',
                    style: TextStyle(fontSize: PsType.caption, color: PsColors.textMuted)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _banner(AppL10n l10n) => Container(
        padding: const EdgeInsets.all(PsSpacing.s3),
        decoration: BoxDecoration(
          color: PsColors.glassThin,
          borderRadius: BorderRadius.circular(PsRadii.md),
          border: Border.all(color: PsColors.glassBorder),
        ),
        child: Row(
          children: [
            Icon(Icons.lock_outline, size: 16, color: PsColors.textMuted),
            const SizedBox(width: PsSpacing.s2),
            Expanded(
              child: Text(l10n.observeBanner,
                  style: TextStyle(fontSize: PsType.caption, color: PsColors.textMuted)),
            ),
          ],
        ),
      );

  Widget _nav(BuildContext context, AppL10n l10n) => Padding(
        padding: const EdgeInsets.fromLTRB(PsSpacing.s3, PsSpacing.s2, PsSpacing.s4, PsSpacing.s3),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.all(PsSpacing.s2),
                child: Icon(Icons.arrow_back_ios_new, size: 18, color: PsColors.text),
              ),
            ),
            const SizedBox(width: PsSpacing.s2),
            Expanded(
              child: Text(clubName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: PsType.title,
                      fontWeight: PsType.weightBlack,
                      letterSpacing: PsType.trackingSnug,
                      color: PsColors.text)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: PsColors.glassRegular,
                borderRadius: BorderRadius.circular(PsRadii.full),
                border: Border.all(color: PsColors.glassBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.visibility_outlined, size: 13, color: PsColors.textMuted),
                  const SizedBox(width: 5),
                  Text(l10n.readOnlyLabel,
                      style: TextStyle(
                          fontSize: PsType.micro,
                          fontWeight: PsType.weightBlack,
                          color: PsColors.textMuted)),
                ],
              ),
            ),
          ],
        ),
      );
}
