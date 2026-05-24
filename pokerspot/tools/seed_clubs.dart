// One-shot Firestore seeder for the 4 demo clubs. NOT part of the main app.
// Run: flutter run -t tools/seed_clubs.dart -d chrome --dart-define-from-file=env-dev.json
// Idempotent: fixed doc ids mean re-runs overwrite the same docs.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:pokerspot/firebase_options.dart';

/// Demo clubs keyed by fixed Firestore doc id. Mirrors README "Demo clubs to
/// seed". photoUrl omitted -> the app shows the icon fallback.
const _clubs = <String, Map<String, dynamic>>{
  'demo-vake': {
    'name': 'PokerSpot Vake',
    'city': 'Tbilisi',
    'address': 'Chavchavadze Ave 47',
    'hoursText': 'Daily 14:00–04:00',
    'phone': '+995 32 200 0001',
    'enabled': true,
  },
  'demo-saburtalo': {
    'name': 'PokerSpot Saburtalo',
    'city': 'Tbilisi',
    'address': 'Vazha-Pshavela Ave 76',
    'hoursText': 'Daily 14:00–04:00',
    'phone': '+995 32 200 0002',
    'enabled': true,
  },
  'demo-aragvi': {
    'name': 'Aragvi Club',
    'city': 'Tbilisi',
    'address': 'Rustaveli Ave 12',
    'hoursText': 'Daily 14:00–04:00',
    'phone': '+995 32 200 0003',
    'enabled': true,
  },
  'demo-batumi-royal': {
    'name': 'Batumi Royal',
    'city': 'Batumi',
    'address': 'Memed Abashidze Ave 25',
    'hoursText': 'Daily 14:00–04:00',
    'phone': '+995 32 200 0004',
    'enabled': true,
  },
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
  final List<String> _written = [];
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
      _written.clear();
      _verified = 0;
    });
    try {
      final db = FirebaseFirestore.instance;
      for (final entry in _clubs.entries) {
        await db.collection('clubs').doc(entry.key).set(entry.value);
        debugPrint('[SEED] wrote clubs/${entry.key} -> ${entry.value['name']}');
        _written.add(entry.value['name'] as String);
      }
      debugPrint('[SEED] done. wrote ${_written.length} clubs.');

      // Read back to verify.
      for (final id in _clubs.keys) {
        final snap = await db.collection('clubs').doc(id).get();
        debugPrint(
            '[VERIFY] clubs/$id exists=${snap.exists} name=${snap.data()?['name']}');
        if (snap.exists) _verified++;
      }
      debugPrint('[VERIFY] $_verified/${_clubs.length} docs confirmed.');

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
      appBar: AppBar(title: const Text('Seed demo clubs')),
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text('Done. Wrote ${_written.length} clubs:',
                            style: const TextStyle(fontSize: 20)),
                        const SizedBox(height: 12),
                        for (final n in _written) Text('•  $n'),
                        const SizedBox(height: 12),
                        Text('Verified $_verified/${_clubs.length} docs in clubs/'),
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
