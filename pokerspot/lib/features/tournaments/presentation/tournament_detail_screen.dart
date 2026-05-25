import 'package:flutter/material.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/tournaments/domain/tournament.dart';
import 'package:pokerspot/features/tournaments/presentation/tournament_editor_screen.dart' show tournamentTypeLabel;
import 'package:pokerspot/shared/widgets/ps_card.dart';
import 'package:pokerspot/shared/widgets/ps_scaffold.dart';
import 'package:pokerspot/shared/widgets/ps_settings_group.dart';

String tournamentMoney(String currency, num? v) {
  if (v == null) return '—';
  final sym = currency == 'USD' ? '\$' : currency == 'EUR' ? '€' : '₾';
  return '$sym${v % 1 == 0 ? v.toInt() : v}';
}

String _two(int n) => n.toString().padLeft(2, '0');

String tournamentWhen(Tournament t) {
  final s = t.startAt;
  if (s == null) return '—';
  return '${_two(s.day)}.${_two(s.month)}.${s.year} · ${_two(s.hour)}:${_two(s.minute)}';
}

/// Player view of one tournament (type / buy-in / rebuy / add-on / blinds / date).
class TournamentDetailScreen extends StatelessWidget {
  const TournamentDetailScreen({super.key, required this.tournament});

  final Tournament tournament;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final t = tournament;
    final cur = t.currency;
    return PsScaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
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
                    child: Text(t.name.isEmpty ? tournamentTypeLabel(t.type, l10n) : t.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: PsType.title,
                            fontWeight: PsType.weightBlack,
                            letterSpacing: PsType.trackingSnug,
                            color: PsColors.text)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(PsSpacing.s5),
                children: [
                  PsCard(
                    accentRail: PsColors.accentSecondary,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('🏆 ${tournamentTypeLabel(t.type, l10n)}',
                            style: const TextStyle(
                                fontSize: PsType.headline,
                                fontWeight: PsType.weightBlack,
                                color: PsColors.text)),
                        const SizedBox(height: 4),
                        Text(tournamentWhen(t),
                            style: const TextStyle(
                                fontSize: PsType.body,
                                fontWeight: PsType.weightBold,
                                color: PsColors.accentPrimary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: PsSpacing.s4),
                  PsSettingsGroup(children: [
                    PsSettingsRow(label: l10n.tournamentType, value: tournamentTypeLabel(t.type, l10n)),
                    PsSettingsRow(label: l10n.buyInLabel, value: tournamentMoney(cur, t.buyIn)),
                    if (t.type.hasRebuy)
                      PsSettingsRow(label: l10n.rebuyFeeLabel, value: tournamentMoney(cur, t.rebuyFee)),
                    if (t.hasAddon)
                      PsSettingsRow(label: l10n.addonFeeLabel, value: tournamentMoney(cur, t.addonFee)),
                    PsSettingsRow(label: l10n.blindMinutesLabel, value: '${t.blindMinutes}'),
                    PsSettingsRow(label: l10n.startsLabel, value: tournamentWhen(t)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
