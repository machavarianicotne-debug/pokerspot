import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/features/floor/domain/poker_table.dart';
import 'package:pokerspot/features/floor/domain/session.dart';
import 'package:pokerspot/features/floor/presentation/providers.dart';
import 'package:pokerspot/features/floor/presentation/new_game_screen.dart';
import 'package:pokerspot/features/floor/presentation/table_detail_screen.dart';
import 'package:pokerspot/features/floor/presentation/table_editor_sheet.dart';
import 'package:pokerspot/shared/widgets/ps_button.dart';
import 'package:pokerspot/shared/widgets/ps_card.dart';
import 'package:pokerspot/shared/widgets/ps_list_tile.dart';
import 'package:pokerspot/shared/widgets/ps_status_badge.dart';

/// Pit Boss "Tables" tab: the club's tables with live occupancy, plus a
/// New table action. Tap a table to open its seat map.
class TablesScreen extends ConsumerWidget {
  const TablesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    final tables = ref.watch(tablesProvider(clubId)).valueOrNull ?? const <PokerTable>[];
    final sessions = ref.watch(clubSessionsProvider(clubId)).valueOrNull ?? const <Session>[];
    int occupied(String tableId) => sessions.where((s) => s.tableId == tableId).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(PsSpacing.s4, PsSpacing.s4, PsSpacing.s4, 96),
      children: [
        Row(
          children: [
            Expanded(
              child: PsButton(
                key: const Key('newGameBtn'),
                label: l10n.newGame,
                icon: Icons.add,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => NewGameScreen(clubId: clubId)),
                ),
              ),
            ),
            const SizedBox(width: PsSpacing.s2),
            Expanded(
              child: PsButton(
                key: const Key('newTableBtn'),
                label: l10n.newTable,
                variant: PsButtonVariant.secondary,
                onPressed: () => TableEditorSheet.show(context, clubId: clubId),
              ),
            ),
          ],
        ),
        const SizedBox(height: PsSpacing.s4),
        if (tables.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: PsSpacing.s8),
            child: Text(l10n.noTablesYet,
                textAlign: TextAlign.center,
                style: TextStyle(color: PsColors.textMuted, fontSize: PsType.body)),
          )
        else
          for (final t in tables)
            Padding(
              padding: const EdgeInsets.only(bottom: PsSpacing.s3),
              child: _TableCard(table: t, occupied: occupied(t.id)),
            ),
      ],
    );
  }
}

class _TableCard extends StatelessWidget {
  const _TableCard({required this.table, required this.occupied});
  final PokerTable table;
  final int occupied;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final full = occupied >= table.seatCount;
    return PsCard(
      key: Key('tableCard_${table.id}'),
      accentRail: table.open ? PsColors.accentPrimary : PsColors.statusClosed,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TableDetailScreen(clubId: table.clubId, tableId: table.id),
        ),
      ),
      child: PsListTile(
        title: '${l10n.tableLabel} ${table.number}',
        subtitle: table.stakes.label,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$occupied/${table.seatCount}',
              style: TextStyle(
                fontSize: PsType.body,
                fontWeight: PsType.weightBlack,
                color: full ? PsColors.statusFull : PsColors.text,
              ),
            ),
            if (table.open) ...[
              const SizedBox(width: PsSpacing.s2),
              PsStatusBadge(status: PsStatus.open, label: l10n.openLabel),
            ],
          ],
        ),
      ),
    );
  }
}
