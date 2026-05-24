import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/core/theme/tokens.dart';
import 'package:pokerspot/features/clubs/domain/club.dart';
import 'package:pokerspot/features/clubs/presentation/providers.dart';
import 'package:pokerspot/shared/widgets/centered_pane.dart';

/// The Player's club list, embedded in PlayerHome's body.
class ClubsListScreen extends ConsumerWidget {
  const ClubsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppL10n.of(context);
    final clubsAsync = ref.watch(clubsListProvider);
    return CenteredPane(
      child: clubsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(PsSpacing.s5),
            child: Text('$e',
                textAlign: TextAlign.center,
                style: const TextStyle(color: PsColors.statusLive)),
          ),
        ),
        data: (clubs) {
          if (clubs.isEmpty) {
            return Center(
              child: Text(l10n.noClubsYet,
                  style: TextStyle(color: PsColors.textMuted, fontSize: PsType.body)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(PsSpacing.s4),
            itemCount: clubs.length,
            itemBuilder: (context, i) => _ClubCard(club: clubs[i]),
          );
        },
      ),
    );
  }
}

class _ClubCard extends StatelessWidget {
  const _ClubCard({required this.club});
  final Club club;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: PsColors.bg1,
      margin: const EdgeInsets.only(bottom: PsSpacing.s3),
      child: ListTile(
        key: Key('clubCard_${club.id}'),
        onTap: () => context.go('/home/club/${club.id}'),
        leading: _Thumb(photoUrl: club.photoUrl),
        title: Text(club.name,
            style: const TextStyle(color: PsColors.text, fontWeight: FontWeight.w700)),
        subtitle: Text(club.city, style: TextStyle(color: PsColors.textMuted)),
        trailing: Icon(Icons.chevron_right, color: PsColors.textMuted),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.photoUrl});
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(PsRadii.sm),
      child: SizedBox(
        width: 48,
        height: 48,
        child: (url != null && url.isNotEmpty)
            ? Image.network(url,
                fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallback())
            : _fallback(),
      ),
    );
  }

  Widget _fallback() => Container(
        color: PsColors.bg0,
        child: const Icon(Icons.casino, color: PsColors.accentPrimary),
      );
}
