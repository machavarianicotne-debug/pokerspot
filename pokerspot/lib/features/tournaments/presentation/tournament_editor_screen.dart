import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/tournaments/domain/tournament.dart';
import 'package:pokerspot/features/tournaments/presentation/providers.dart';
import 'package:pokerspot/shared/widgets/ps_button.dart';
import 'package:pokerspot/shared/widgets/ps_money_field.dart';
import 'package:pokerspot/shared/widgets/ps_scaffold.dart';
import 'package:pokerspot/shared/widgets/ps_segmented.dart';
import 'package:pokerspot/shared/widgets/ps_text_field.dart';
import 'package:pokerspot/shared/widgets/ps_toggle.dart';

String tournamentTypeLabel(TournamentType t, AppL10n l10n) {
  switch (t) {
    case TournamentType.freezeout:
      return l10n.typeFreezeout;
    case TournamentType.knockoutRebuy:
      return l10n.typeKnockoutRebuy;
    case TournamentType.rebuy:
      return l10n.typeRebuy;
    case TournamentType.rebuyAddon:
      return l10n.typeRebuyAddon;
  }
}

/// Pit Boss announces a tournament (type / buy-in / rebuy / add-on / blinds / date).
/// Pass [existing] to edit an already-announced tournament instead of creating one.
class TournamentEditorScreen extends ConsumerStatefulWidget {
  const TournamentEditorScreen(
      {super.key, required this.clubId, this.currency = 'GEL', this.existing});
  final String clubId;
  final String currency;
  final Tournament? existing;

  @override
  ConsumerState<TournamentEditorScreen> createState() => _TournamentEditorScreenState();
}

class _TournamentEditorScreenState extends ConsumerState<TournamentEditorScreen> {
  final _name = TextEditingController();
  final _buyIn = TextEditingController();
  final _rebuyFee = TextEditingController();
  final _addonFee = TextEditingController();
  final _blind = TextEditingController(text: '20');
  final _maxPlayers = TextEditingController();
  TournamentType _type = TournamentType.freezeout;
  bool _addon = false;
  late DateTime _start;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _name.text = e.name;
      _buyIn.text = _numText(e.buyIn);
      _rebuyFee.text = e.rebuyFee == null ? '' : _numText(e.rebuyFee!);
      _addonFee.text = e.addonFee == null ? '' : _numText(e.addonFee!);
      _blind.text = '${e.blindMinutes}';
      _maxPlayers.text = e.maxPlayers == null ? '' : '${e.maxPlayers}';
      _type = e.type;
      _addon = e.hasAddon;
      _start = e.startAt ?? DateTime.now().add(const Duration(days: 1));
    } else {
      final t = DateTime.now().add(const Duration(days: 1));
      _start = DateTime(t.year, t.month, t.day, 20, 0);
    }
  }

  static String _numText(num n) => n % 1 == 0 ? n.toInt().toString() : '$n';

  /// Editing keeps the tournament's own currency; new ones use the passed one.
  String get _ccy => widget.existing?.currency ?? widget.currency;

  @override
  void dispose() {
    _name.dispose();
    _buyIn.dispose();
    _rebuyFee.dispose();
    _addonFee.dispose();
    _blind.dispose();
    _maxPlayers.dispose();
    super.dispose();
  }

  String _sym() => _ccy == 'USD' ? '\$' : _ccy == 'EUR' ? '€' : '₾';

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _start = DateTime(d.year, d.month, d.day, _start.hour, _start.minute));
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_start));
    if (t != null) {
      setState(() => _start = DateTime(_start.year, _start.month, _start.day, t.hour, t.minute));
    }
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final nav = Navigator.of(context);
    final repo = ref.read(tournamentsRepositoryProvider);
    final t = Tournament(
      id: widget.existing?.id ?? '',
      clubId: widget.clubId,
      name: _name.text.trim(),
      type: _type,
      startAt: _start,
      buyIn: num.tryParse(_buyIn.text.trim()) ?? 0,
      rebuyFee: _type.hasRebuy ? num.tryParse(_rebuyFee.text.trim()) : null,
      hasAddon: _addon,
      addonFee: _addon ? num.tryParse(_addonFee.text.trim()) : null,
      blindMinutes: int.tryParse(_blind.text.trim()) ?? 20,
      currency: _ccy,
      maxPlayers: int.tryParse(_maxPlayers.text.trim()),
    );
    if (widget.existing == null) {
      await repo.create(t);
    } else {
      await repo.update(t);
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

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
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
                  Text(widget.existing == null ? l10n.newTournament : l10n.editTournament,
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
                  _label(l10n.tournamentName),
                  PsTextField(controller: _name, hintText: l10n.tournamentName),
                  _label(l10n.tournamentType),
                  PsSegmented<TournamentType>(
                    value: _type,
                    segments: [
                      for (final t in TournamentType.values) PsSegment(t, tournamentTypeLabel(t, l10n)),
                    ],
                    onChanged: (t) => setState(() => _type = t),
                  ),
                  _label(l10n.buyInLabel),
                  PsMoneyField(symbol: _sym(), controller: _buyIn, hintText: '100'),
                  if (_type.hasRebuy) ...[
                    _label(l10n.rebuyFeeLabel),
                    PsMoneyField(symbol: _sym(), controller: _rebuyFee, hintText: '100'),
                  ],
                  Padding(
                    padding: const EdgeInsets.only(top: PsSpacing.s4),
                    child: PsToggle(
                        value: _addon,
                        onChanged: (v) => setState(() => _addon = v),
                        label: l10n.addonLabel.toUpperCase()),
                  ),
                  if (_addon) ...[
                    _label(l10n.addonFeeLabel),
                    PsMoneyField(symbol: _sym(), controller: _addonFee, hintText: '100'),
                  ],
                  _label(l10n.blindMinutesLabel),
                  PsTextField(controller: _blind, keyboardType: TextInputType.number, hintText: '20'),
                  _label(l10n.maxPlayersLabel),
                  PsTextField(
                      controller: _maxPlayers,
                      keyboardType: TextInputType.number,
                      hintText: '50'),
                  _label(l10n.startsLabel),
                  Row(
                    children: [
                      Expanded(
                        child: _pickerTile(
                            key: const Key('pickDateBtn'),
                            label: l10n.pickDate,
                            value: '${_two(_start.day)}.${_two(_start.month)}.${_start.year}',
                            onTap: () => unawaited(_pickDate())),
                      ),
                      const SizedBox(width: PsSpacing.s2),
                      Expanded(
                        child: _pickerTile(
                            key: const Key('pickTimeBtn'),
                            label: l10n.pickTime,
                            value: '${_two(_start.hour)}:${_two(_start.minute)}',
                            onTap: () => unawaited(_pickTime())),
                      ),
                    ],
                  ),
                  const SizedBox(height: PsSpacing.s6),
                  PsButton(
                    key: const Key('saveTournamentBtn'),
                    label: widget.existing == null ? l10n.announceTournament : l10n.saveLabel,
                    onPressed: _busy ? null : () => unawaited(_save()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pickerTile(
      {required Key key, required String label, required String value, required VoidCallback onTap}) {
    return GestureDetector(
      key: key,
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: PsSpacing.s4, vertical: PsSpacing.s3),
        decoration: BoxDecoration(
          color: PsColors.glassThin,
          borderRadius: BorderRadius.circular(PsRadii.md),
          border: Border.all(color: PsColors.glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(),
                style: TextStyle(
                    fontSize: PsType.micro, fontWeight: PsType.weightBold, color: PsColors.textFaint)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    fontSize: PsType.body, fontWeight: PsType.weightBold, color: PsColors.text)),
          ],
        ),
      ),
    );
  }
}
