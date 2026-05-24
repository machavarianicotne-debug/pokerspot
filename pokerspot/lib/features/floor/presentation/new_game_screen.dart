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
import 'package:pokerspot/shared/widgets/ps_money_field.dart';
import 'package:pokerspot/shared/widgets/ps_scaffold.dart';
import 'package:pokerspot/shared/widgets/ps_segmented.dart';
import 'package:pokerspot/shared/widgets/ps_stepper.dart';
import 'package:pokerspot/shared/widgets/ps_text_field.dart';

const _currencies = ['GEL', 'USD', 'EUR'];
const _blindPresets = ['1/3', '2/5', '5/5', '5/10'];
String _symbol(String c) => c == 'USD' ? '\$' : c == 'EUR' ? '€' : '₾';

/// Open a new game (mockup `pit-boss-new-game`): pick type / blinds / currency /
/// tables and create N same-stake tables. Min buy-in + avg stack are collected
/// but not persisted yet (PokerTable has no such fields — deferred per spec §7).
class NewGameScreen extends ConsumerStatefulWidget {
  const NewGameScreen({super.key, required this.clubId});
  final String clubId;

  @override
  ConsumerState<NewGameScreen> createState() => _NewGameScreenState();
}

class _NewGameScreenState extends ConsumerState<NewGameScreen> {
  GameVariant _variant = GameVariant.nlh;
  String _blinds = '1/3';
  bool _custom = false;
  final _customBlinds = TextEditingController();
  final _minBuyIn = TextEditingController();
  final _avgStack = TextEditingController();
  String _currency = 'GEL';
  int _tables = 1;
  bool _busy = false;

  @override
  void dispose() {
    _customBlinds.dispose();
    _minBuyIn.dispose();
    _avgStack.dispose();
    super.dispose();
  }

  (num, num) _parseBlinds() {
    final raw = _custom ? _customBlinds.text.trim() : _blinds;
    final parts = raw.split('/');
    final sb = parts.isNotEmpty ? num.tryParse(parts[0].trim()) ?? 1 : 1;
    final bb = parts.length > 1 ? num.tryParse(parts[1].trim()) ?? 2 : 2;
    return (sb, bb);
  }

  Future<void> _open() async {
    setState(() => _busy = true);
    final (sb, bb) = _parseBlinds();
    final stakes = Stakes(variant: _variant, smallBlind: sb, bigBlind: bb, currency: _currency);
    final repo = ref.read(tablesRepositoryProvider);
    final existing = ref.read(tablesProvider(widget.clubId)).valueOrNull ?? const <PokerTable>[];
    var next = existing.fold<int>(0, (m, t) => t.number > m ? t.number : m) + 1;
    final nav = Navigator.of(context);
    for (var i = 0; i < _tables; i++) {
      await repo.createTable(
          clubId: widget.clubId, number: next++, stakes: stakes, seatCount: 9, open: true);
    }
    nav.pop();
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: PsSpacing.s2, top: PsSpacing.s4),
        child: Text(text.toUpperCase(),
            style: TextStyle(
                fontSize: PsType.caption,
                fontWeight: PsType.weightBlack,
                letterSpacing: PsType.trackingWide,
                color: PsColors.textFaint)),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final sym = _symbol(_currency);
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
                  Text(l10n.newGame,
                      style: const TextStyle(
                          fontSize: PsType.title,
                          fontWeight: PsType.weightBlack,
                          letterSpacing: PsType.trackingSnug,
                          color: PsColors.text)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(PsSpacing.s5, 0, PsSpacing.s5, PsSpacing.s8),
                children: [
                  _label(l10n.gameLabel),
                  PsSegmented<GameVariant>(
                    value: _variant,
                    segments: [for (final v in GameVariant.values) PsSegment(v, v.label)],
                    onChanged: (v) => setState(() => _variant = v),
                  ),
                  _label(l10n.blindsLabel),
                  Wrap(
                    spacing: PsSpacing.s2,
                    runSpacing: PsSpacing.s2,
                    children: [
                      for (final b in _blindPresets)
                        PsFilterPill(
                          label: b,
                          active: !_custom && _blinds == b,
                          onTap: () => setState(() {
                            _custom = false;
                            _blinds = b;
                          }),
                        ),
                      PsFilterPill(
                        label: l10n.customLabel,
                        active: _custom,
                        onTap: () => setState(() => _custom = true),
                      ),
                    ],
                  ),
                  if (_custom) ...[
                    const SizedBox(height: PsSpacing.s2),
                    PsTextField(controller: _customBlinds, hintText: 'e.g. 10/20'),
                  ],
                  _label(l10n.currencyLabel),
                  PsSegmented<String>(
                    value: _currency,
                    segments: [for (final c in _currencies) PsSegment(c, c)],
                    onChanged: (c) => setState(() => _currency = c),
                  ),
                  _label(l10n.minBuyInLabel),
                  PsMoneyField(symbol: sym, controller: _minBuyIn, hintText: '200'),
                  _label(l10n.avgStackLabel),
                  PsMoneyField(symbol: sym, controller: _avgStack, hintText: '—'),
                  _label(l10n.tablesToOpenLabel),
                  PsStepper(value: _tables, min: 1, max: 3, onChanged: (n) => setState(() => _tables = n)),
                  const SizedBox(height: PsSpacing.s6),
                  PsButton(
                    key: const Key('openGameBtn'),
                    label: l10n.openGameBtn,
                    onPressed: _busy ? null : () => unawaited(_open()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
