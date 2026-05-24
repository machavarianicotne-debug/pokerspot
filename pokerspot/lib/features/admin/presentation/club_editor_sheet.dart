import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/admin/presentation/providers.dart';
import 'package:pokerspot/features/auth/presentation/providers.dart';
import 'package:pokerspot/features/clubs/domain/club.dart';
import 'package:pokerspot/features/clubs/presentation/providers.dart';
import 'package:pokerspot/shared/widgets/ps_button.dart';
import 'package:pokerspot/shared/widgets/ps_sheet.dart';
import 'package:pokerspot/shared/widgets/ps_text_field.dart';
import 'package:pokerspot/shared/widgets/ps_toggle.dart';

/// Create / edit a club (Super Admin). Pass [existing] to edit.
class ClubEditorSheet extends ConsumerStatefulWidget {
  const ClubEditorSheet({super.key, this.existing});
  final Club? existing;

  static Future<void> show(BuildContext context, {Club? existing}) =>
      PsSheet.show<void>(context, child: ClubEditorSheet(existing: existing));

  @override
  ConsumerState<ClubEditorSheet> createState() => _ClubEditorSheetState();
}

class _ClubEditorSheetState extends ConsumerState<ClubEditorSheet> {
  late final TextEditingController _name;
  late final TextEditingController _city;
  late final TextEditingController _address;
  late final TextEditingController _hours;
  late final TextEditingController _phone;
  late bool _enabled;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _city = TextEditingController(text: e?.city ?? '');
    _address = TextEditingController(text: e?.address ?? '');
    _hours = TextEditingController(text: e?.hoursText ?? '');
    _phone = TextEditingController(text: e?.phone ?? '');
    _enabled = e?.enabled ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    _address.dispose();
    _hours.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final repo = ref.read(clubsRepositoryProvider);
    final admin = ref.read(adminRepositoryProvider);
    final actor = ref.read(currentUserProvider).valueOrNull?.uid ?? 'admin';
    final nav = Navigator.of(context);
    final draft = Club(
      id: widget.existing?.id ?? '',
      name: _name.text.trim(),
      city: _city.text.trim(),
      address: _address.text.trim(),
      photoUrl: widget.existing?.photoUrl,
      hoursText: _hours.text.trim(),
      phone: _phone.text.trim(),
      enabled: _enabled,
    );
    if (widget.existing == null) {
      final id = await repo.createClub(draft);
      await admin.log(actorUid: actor, action: 'club.create', target: id, meta: {'name': draft.name});
    } else {
      await repo.updateClub(draft);
      await admin.log(actorUid: actor, action: 'club.update', target: draft.id, meta: {'name': draft.name});
    }
    nav.pop();
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: PsSpacing.s2, top: PsSpacing.s3),
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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.existing == null ? l10n.newClub : l10n.editClub,
              style: const TextStyle(
                  fontSize: PsType.headline, fontWeight: PsType.weightBold, color: PsColors.text)),
          _label(l10n.clubNameLabel),
          PsTextField(controller: _name, hintText: l10n.clubNameLabel),
          _label(l10n.cityLabel),
          PsTextField(controller: _city, hintText: l10n.cityLabel),
          _label(l10n.clubAddress),
          PsTextField(controller: _address, hintText: l10n.clubAddress),
          _label(l10n.clubHours),
          PsTextField(controller: _hours, hintText: l10n.clubHours),
          _label(l10n.clubPhone),
          PsTextField(controller: _phone, keyboardType: TextInputType.phone, hintText: l10n.clubPhone),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: PsSpacing.s4),
            child: PsToggle(
                value: _enabled,
                onChanged: (v) => setState(() => _enabled = v),
                label: l10n.enabledLabel.toUpperCase()),
          ),
          PsButton(
            key: const Key('saveClubBtn'),
            label: l10n.saveLabel,
            onPressed: _busy ? null : () => unawaited(_save()),
          ),
          const SizedBox(height: PsSpacing.s2),
        ],
      ),
    );
  }
}
