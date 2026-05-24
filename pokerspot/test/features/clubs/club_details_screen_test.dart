import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pokerspot/l10n/app_localizations.dart';
import 'package:pokerspot/features/clubs/data/fake_clubs_repository.dart';
import 'package:pokerspot/features/clubs/domain/club.dart';
import 'package:pokerspot/features/clubs/presentation/club_details_screen.dart';
import 'package:pokerspot/features/clubs/presentation/providers.dart';

const _vake = Club(
  id: 'vake',
  name: 'PokerSpot Vake',
  city: 'Tbilisi',
  address: 'Chavchavadze Ave 47',
  photoUrl: null,
  hoursText: 'Daily 14:00–04:00',
  phone: '+995 32 200 0000',
  enabled: true,
);

Widget _wrap(String clubId, FakeClubsRepository repo) => ProviderScope(
      overrides: [clubsRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: ClubDetailsScreen(clubId: clubId),
      ),
    );

void main() {
  testWidgets('renders the club fields', (tester) async {
    await tester.pumpWidget(_wrap('vake', FakeClubsRepository(seed: const [_vake])));
    await tester.pumpAndSettle();

    expect(find.text('PokerSpot Vake'), findsOneWidget);
    expect(find.text('Tbilisi'), findsOneWidget);
    expect(find.text('Chavchavadze Ave 47'), findsOneWidget);
    expect(find.text('Daily 14:00–04:00'), findsOneWidget);
    expect(find.text('+995 32 200 0000'), findsOneWidget);
    expect(find.byKey(const Key('phoneTile')), findsOneWidget);
  });

  testWidgets('shows the "tables coming soon" placeholder', (tester) async {
    await tester.pumpWidget(_wrap('vake', FakeClubsRepository(seed: const [_vake])));
    await tester.pumpAndSettle();
    expect(find.text('Tables — coming in the next release'), findsOneWidget);
  });

  testWidgets('unknown club id shows the empty/not-found state', (tester) async {
    await tester.pumpWidget(_wrap('missing', FakeClubsRepository(seed: const [_vake])));
    await tester.pumpAndSettle();
    expect(find.text('No clubs yet'), findsOneWidget);
    expect(find.text('PokerSpot Vake'), findsNothing);
  });
}
