import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/clubs/domain/club.dart';
import 'package:pokerspot/features/clubs/presentation/providers.dart';

class ClubDetailsScreen extends ConsumerWidget {
  const ClubDetailsScreen({super.key, required this.clubId});
  final String clubId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final clubAsync = ref.watch(clubProvider(clubId));
    return Scaffold(
      backgroundColor: PsColors.bg0,
      appBar: AppBar(
        backgroundColor: PsColors.bg1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: PsColors.accentPrimary),
          tooltip: l10n.backToClubs,
          onPressed: () => context.go('/home'),
        ),
      ),
      body: clubAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('$e', style: const TextStyle(color: PsColors.statusLive)),
        ),
        data: (club) => club == null
            ? Center(
                child: Text(l10n.noClubsYet,
                    style: TextStyle(color: PsColors.textMuted)))
            : _Details(club: club),
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
        _Hero(photoUrl: club.photoUrl),
        const SizedBox(height: PsSpacing.s4),
        Text(club.name,
            style: const TextStyle(
                color: PsColors.text,
                fontSize: PsType.title,
                fontWeight: FontWeight.w900)),
        const SizedBox(height: PsSpacing.s1),
        Text(club.city,
            style: TextStyle(color: PsColors.textMuted, fontSize: PsType.body)),
        const SizedBox(height: PsSpacing.s5),
        _InfoRow(icon: Icons.place, label: l10n.clubAddress, value: club.address),
        _InfoRow(icon: Icons.schedule, label: l10n.clubHours, value: club.hoursText),
        ListTile(
          key: const Key('phoneTile'),
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.call, color: PsColors.accentSecondary),
          title: Text(l10n.clubPhone,
              style: TextStyle(color: PsColors.textMuted, fontSize: PsType.subhead)),
          subtitle: Text(club.phone,
              style: const TextStyle(color: PsColors.text, fontSize: PsType.body)),
          // Normalize to digits + a single leading '+' — the tel: URI spec
          // forbids spaces (the seeded numbers contain them), which made some
          // browsers ignore the link entirely.
          onTap: () {
            final tel = club.phone.replaceAll(RegExp(r'[^\d+]'), '');
            unawaited(launchUrl(Uri.parse('tel:$tel')));
          },
          trailing: IconButton(
            key: const Key('copyPhoneBtn'),
            icon: Icon(Icons.copy, color: PsColors.textMuted),
            onPressed: () {
              // Copy the display-formatted number (with spaces) — easier to read.
              unawaited(Clipboard.setData(ClipboardData(text: club.phone)));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.phoneCopied)),
              );
            },
          ),
        ),
        const SizedBox(height: PsSpacing.s5),
        Card(
          color: PsColors.bg1,
          child: Padding(
            padding: const EdgeInsets.all(PsSpacing.s4),
            child: Text(l10n.tablesComingSoon,
                style: TextStyle(color: PsColors.textMuted, fontSize: PsType.body)),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: PsSpacing.s2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: PsColors.accentSecondary),
          const SizedBox(width: PsSpacing.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(color: PsColors.textMuted, fontSize: PsType.subhead)),
                Text(value,
                    style: const TextStyle(color: PsColors.text, fontSize: PsType.body)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.photoUrl});
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(PsRadii.lg),
      child: SizedBox(
        height: 180,
        width: double.infinity,
        child: (url != null && url.isNotEmpty)
            ? Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallback())
            : _fallback(),
      ),
    );
  }

  Widget _fallback() => Container(
        color: PsColors.bg1,
        child: const Center(
          child: Icon(Icons.casino, color: PsColors.accentPrimary, size: 64),
        ),
      );
}
