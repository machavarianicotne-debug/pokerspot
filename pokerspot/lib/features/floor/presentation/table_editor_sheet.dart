import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/floor/domain/poker_table.dart';
import 'package:pokerspot/features/floor/domain/stakes.dart';
import 'package:pokerspot/features/floor/presentation/providers.dart';
import 'package:pokerspot/shared/widgets/ps_button.dart';
import 'package:pokerspot/shared/widgets/ps_filter_pill.dart';
import 'package:pokerspot/shared/widgets/ps_sheet.dart';
import 'package:pokerspot/shared/widgets/ps_text_field.dart';
import 'package:pokerspot/shared/widgets/ps_toggle.dart';

const _currencies = ['GEL', 'USD'];

/// Create / edit a table. Pass [existing] to edit; null to create.
class TableEditorSheet extends ConsumerStatefulWidget {
  const TableEditorSheet({super.key, required this.clubId, this.existing});

  final String clubId;
  final PokerTable? existing;

  static Future<void> show(BuildContext context, {required String clubId, PokerTable? existing}) =>
      PsSheet.show<void>(context, child: TableEditorSheet(clubId: clubId, existing: existing));

  @override
  ConsumerState<TableEditorSheet> createState() => _TableEditorSheetState();
}

class _TableEditorSheetState extends ConsumerState<TableEditorSheet> {
  late final TextEditingController _number;
  late final TextEditingController _sb;
  late final TextEditingController _bb;
  late final TextEditingController _seats;
  late GameVariant _variant;
  late String _currency;
  late bool _open;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _number = TextEditingController(text: e == null ? '' : '${e.number}');
    _sb = TextEditingController(text: e == null ? '' : _fmt(e.stakes.smallBlind));
    _bb = TextEditingController(text: e == null ? '' : _fmt(e.stakes.bigBlind));
    _seats = TextEditingController(text: e == null ? '9' : '${e.seatCount}');
    _variant = e?.stakes.variant ?? GameVariant.nlh;
    _currency = e?.stakes.currency ?? 'GEL';
    _open = e?.open ?? true;
  }

  static String _fmt(num n) => n == n.truncate() ? n.toInt().toString() : '$n';

  @override
  void dispose() {
    _number.dispose();
    _sb.dispose();
    _bb.dispose();
    _seats.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final stakes = Stakes(
      variant: _variant,
      smallBlind: num.tryParse(_sb.text.trim()) ?? 0,
      bigBlind: num.tryParse(_bb.text.trim()) ?? 0,
      currency: _currency,
    );
    final number = int.tryParse(_number.text.trim()) ?? 0;
    final seats = int.tryParse(_seats.text.trim()) ?? 9;
    final repo = ref.read(tablesRepositoryProvider);
    final navigator = Navigator.of(context);
    if (widget.existing == null) {
      await repo.createTable(
          clubId: widget.clubId, number: number, stakes: stakes, seatCount: seats, open: _open);
    } else {
      await repo.updateTable(widget.existing!.copyWith(
          number: number, stakes: stakes, seatCount: seats, open: _open));
    }
    navigator.pop();
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: PsSpacing.s2, top: PsSpacing.s3),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: PsType.caption,
            fontWeight: PsType.weightBlack,
            letterSpacing: PsType.trackingWide,
            color: PsColors.textFaint,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.existing == null ? l10n.newTable : l10n.editTable,
            style: const TextStyle(
              fontSize: PsType.headline,
              fontWeight: PsType.weightBold,
              color: PsColors.text,
            ),
          ),
          _label(l10n.gameLabel),
          Wrap(
            spacing: PsSpacing.s2,
            children: [
              for (final v in pickerGameVariants)
                PsFilterPill(
                  label: v.label,
                  active: _variant == v,
                  onTap: () => setState(() => _variant = v),
                ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label(l10n.smallBlindLabel),
                    PsTextField(controller: _sb, keyboardType: TextInputType.number, hintText: '1'),
                  ],
                ),
              ),
              const SizedBox(width: PsSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label(l10n.bigBlindLabel),
                    PsTextField(controller: _bb, keyboardType: TextInputType.number, hintText: '2'),
                  ],
                ),
              ),
            ],
          ),
          _label(l10n.currencyLabel),
          Wrap(
            spacing: PsSpacing.s2,
            children: [
              for (final c in _currencies)
                PsFilterPill(
                  label: c,
                  active: _currency == c,
                  onTap: () => setState(() => _currency = c),
                ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label(l10n.tableNumberLabel),
                    PsTextField(
                        controller: _number, keyboardType: TextInputType.number, hintText: '1'),
                  ],
                ),
              ),
              const SizedBox(width: PsSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label(l10n.seatsLabel),
                    PsTextField(
                        controller: _seats, keyboardType: TextInputType.number, hintText: '9'),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: PsSpacing.s4),
            child: PsToggle(
              value: _open,
              onChanged: (v) => setState(() => _open = v),
              label: l10n.openLabel.toUpperCase(),
            ),
          ),
          PsButton(
            key: const Key('saveTableBtn'),
            label: l10n.saveLabel,
            onPressed: _busy ? null : () => unawaited(_save()),
          ),
          const SizedBox(height: PsSpacing.s2),
        ],
      ),
    );
  }
}
