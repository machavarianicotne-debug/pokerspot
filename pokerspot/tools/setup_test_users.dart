// One-shot helper: wire test phones to roles/clubs in the `users` collection.
// NOT part of the main app. Run:
//   flutter run -t tools/setup_test_users.dart -d chrome --dart-define-from-file=env-dev.json
// Idempotent: re-running sets the same role + clubId.
//
// Matches users by their `phone` field (backfilled at onboarding). A user must
// have signed in + onboarded AFTER the phone-write change for their doc to be
// matchable; legacy docs with phone='' won't be found and must re-onboard.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:pokerspot/firebase_options.dart';

/// phone (E.164) -> { role, clubId? }. clubId null = clear it (plain player).
const _bindings = <String, Map<String, dynamic>>{
  '+995555111111': {'role': 'pitboss', 'clubId': 'demo-vake'},
  '+995555222222': {'role': 'player', 'clubId': null},
  '+995555333333': {'role': 'pitboss', 'clubId': 'demo-saburtalo'},
};

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const _SetupApp());
}

class _SetupApp extends StatelessWidget {
  const _SetupApp();
  @override
  Widget build(BuildContext context) => const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: _SetupPage(),
      );
}

class _SetupPage extends StatefulWidget {
  const _SetupPage();
  @override
  State<_SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<_SetupPage> {
  bool _busy = true;
  String? _error;
  final List<String> _updated = [];
  final List<String> _skipped = [];
  int _legacyEmptyPhone = 0;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    setState(() {
      _busy = true;
      _error = null;
      _updated.clear();
      _skipped.clear();
      _legacyEmptyPhone = 0;
    });
    try {
      final users = FirebaseFirestore.instance.collection('users');
      for (final entry in _bindings.entries) {
        final phone = entry.key;
        final role = entry.value['role'] as String;
        final clubId = entry.value['clubId'] as String?;
        final q = await users.where('phone', isEqualTo: phone).get();
        if (q.docs.isEmpty) {
          debugPrint('[SETUP] skipped $phone — no user doc with this phone yet '
              '(owner must (re-)onboard after the phone-write change)');
          _skipped.add('$phone — not signed in / re-onboard');
          continue;
        }
        for (final doc in q.docs) {
          await doc.reference.update({'role': role, 'clubId': clubId});
          debugPrint('[SETUP] updated $phone (uid=${doc.id}) -> role=$role clubId=$clubId');
          _updated.add('$phone -> $role${clubId == null ? '' : ' @ $clubId'}');
        }
      }

      // General warning: legacy docs that can't be matched by phone yet.
      final legacy = await users.where('phone', isEqualTo: '').get();
      _legacyEmptyPhone = legacy.docs.length;
      if (_legacyEmptyPhone > 0) {
        debugPrint('[SETUP] note: $_legacyEmptyPhone legacy user doc(s) have an '
            'empty phone — their owners must re-onboard to be matchable.');
      }
      debugPrint('[SETUP] done. updated ${_updated.length}, skipped ${_skipped.length}.');

      if (mounted) setState(() => _busy = false);
    } catch (e, st) {
      debugPrint('[SETUP] ERROR: $e\n$st');
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
      appBar: AppBar(title: const Text('Setup test users')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _busy
              ? const Text('Setting up test users...', style: TextStyle(fontSize: 20))
              : _error != null
                  ? Text('Error: $_error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.red))
                  : SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Done. Updated ${_updated.length} user(s):',
                              style: const TextStyle(fontSize: 20)),
                          const SizedBox(height: 8),
                          for (final u in _updated) Text('•  $u'),
                          if (_skipped.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text('Skipped ${_skipped.length}:',
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            for (final s in _skipped) Text('•  $s'),
                          ],
                          if (_legacyEmptyPhone > 0) ...[
                            const SizedBox(height: 16),
                            Text('$_legacyEmptyPhone legacy doc(s) with empty phone '
                                '(owners must re-onboard).'),
                          ],
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _busy ? null : _run,
                            child: const Text('Re-run'),
                          ),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }
}
