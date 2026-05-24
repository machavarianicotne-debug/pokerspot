// One-shot Firestore seeder for demo tables under each demo club. NOT part of
// the main app. Run:
//   flutter run -t tools/seed_tables.dart -d chrome --dart-define-from-file=env-dev.json
// Idempotent: fixed doc ids (<clubId>-t<number>) mean re-runs overwrite.
// Seed the clubs first with tools/seed_clubs.dart.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:pokerspot/firebase_options.dart';

/// Two tables per demo club (one NLH, one PLO), all open, 9 seats.
const _twoTables = <Map<String, dynamic>>[
  {
    'number': 1,
    'variant': 'nlh',
    'smallBlind': 1,
    'bigBlind': 2,
    'currency': 'GEL',
    'seatCount': 9,
    'open': true,
  },
  {
    'number': 2,
    'variant': 'plo',
    'smallBlind': 2,
    'bigBlind': 5,
    'currency': 'GEL',
    'seatCount': 9,
    'open': true,
  },
];

const _tablesByClub = <String, List<Map<String, dynamic>>>{
  'demo-vake': _twoTables,
  'demo-saburtalo': _twoTables,
  'demo-aragvi': _twoTables,
  'demo-batumi-royal': _twoTables,
};

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const _SeedApp());
}

class _SeedApp extends StatelessWidget {
  const _SeedApp();
  @override
  Widget build(BuildContext context) => const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: _SeedPage(),
      );
}

class _SeedPage extends StatefulWidget {
  const _SeedPage();
  @override
  State<_SeedPage> createState() => _SeedPageState();
}

class _SeedPageState extends State<_SeedPage> {
  bool _busy = true;
  String? _error;
  int _written = 0;
  int _verified = 0;

  @override
  void initState() {
    super.initState();
    _seed();
  }

  Future<void> _seed() async {
    setState(() {
      _busy = true;
      _error = null;
      _written = 0;
      _verified = 0;
    });
    try {
      final db = FirebaseFirestore.instance;
      for (final club in _tablesByClub.entries) {
        for (final t in club.value) {
          final id = '${club.key}-t${t['number']}';
          await db.collection('clubs').doc(club.key).collection('tables').doc(id).set(t);
          debugPrint('[SEED] wrote clubs/${club.key}/tables/$id (${t['variant']})');
          _written++;
        }
      }
      debugPrint('[SEED] done. wrote $_written tables.');

      for (final club in _tablesByClub.keys) {
        final snap = await db.collection('clubs').doc(club).collection('tables').get();
        debugPrint('[VERIFY] clubs/$club/tables -> ${snap.docs.length} docs');
        _verified += snap.docs.length;
      }
      debugPrint('[VERIFY] $_verified tables total.');

      if (mounted) setState(() => _busy = false);
    } catch (e, st) {
      debugPrint('[SEED] ERROR: $e\n$st');
      if (mounted) {
        setState(() {
          _error = '$e';
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seed demo tables')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _busy
              ? const Text('Seeding...', style: TextStyle(fontSize: 20))
              : _error != null
                  ? Text('Error: $_error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.red))
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Done. Wrote $_written tables across ${_tablesByClub.length} clubs.',
                            textAlign: TextAlign.center, style: const TextStyle(fontSize: 20)),
                        const SizedBox(height: 12),
                        Text('Verified $_verified tables in clubs/*/tables'),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _busy ? null : _seed,
                          child: const Text('Re-seed'),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}
