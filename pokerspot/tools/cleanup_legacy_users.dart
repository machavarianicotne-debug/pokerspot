// One-shot cleanup: delete legacy `users` docs that still have an empty phone
// (onboardings from before the Plan-4 phone backfill). NOT part of the main app.
// Run:
//   flutter run -t tools/cleanup_legacy_users.dart -d chrome --dart-define-from-file=env-dev.json
//
// Only deletes Firestore docs where phone == "" — never docs with a phone, and
// never Firebase Auth users. The auth UIDs stay valid; signing in again triggers
// a fresh onboarding that recreates the doc with the phone backfilled.
// Idempotent: re-running finds 0 once everyone is cleaned up.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:pokerspot/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const _CleanupApp());
}

class _CleanupApp extends StatelessWidget {
  const _CleanupApp();
  @override
  Widget build(BuildContext context) => const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: _CleanupPage(),
      );
}

class _LegacyDoc {
  const _LegacyDoc(this.uid, this.name, this.role);
  final String uid;
  final String name;
  final String role;
}

class _CleanupPage extends StatefulWidget {
  const _CleanupPage();
  @override
  State<_CleanupPage> createState() => _CleanupPageState();
}

class _CleanupPageState extends State<_CleanupPage> {
  bool _scanning = true;
  bool _deleting = false;
  bool _done = false;
  String? _error;
  final List<_LegacyDoc> _docs = [];
  int _deleted = 0;

  @override
  void initState() {
    super.initState();
    _scan();
  }

  Future<void> _scan() async {
    setState(() {
      _scanning = true;
      _error = null;
      _done = false;
      _docs.clear();
      _deleted = 0;
    });
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: '')
          .get();
      for (final d in snap.docs) {
        final m = d.data();
        final name = '${m['firstName'] ?? ''} ${m['lastName'] ?? ''}'.trim();
        final role = (m['role'] ?? 'player') as String;
        _docs.add(_LegacyDoc(d.id, name, role));
        debugPrint('[CLEANUP] legacy doc uid=${d.id} name="$name" role=$role');
      }
      debugPrint('[CLEANUP] scan done. found ${_docs.length} legacy docs (phone == "").');
      if (mounted) setState(() => _scanning = false);
    } catch (e, st) {
      debugPrint('[CLEANUP] ERROR: $e\n$st');
      if (mounted) {
        setState(() {
          _error = '$e';
          _scanning = false;
        });
      }
    }
  }

  Future<void> _deleteAll() async {
    setState(() => _deleting = true);
    try {
      final users = FirebaseFirestore.instance.collection('users');
      for (final doc in _docs) {
        await users.doc(doc.uid).delete();
        _deleted++;
        debugPrint('[CLEANUP] deleted users/${doc.uid}');
      }
      debugPrint('[CLEANUP] done. deleted $_deleted legacy users.');
      if (mounted) {
        setState(() {
          _deleting = false;
          _done = true;
        });
      }
    } catch (e, st) {
      debugPrint('[CLEANUP] DELETE ERROR: $e\n$st');
      if (mounted) {
        setState(() {
          _error = '$e';
          _deleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cleanup legacy users')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _build(),
        ),
      ),
    );
  }

  Widget _build() {
    if (_scanning) return const Text('Scanning...', style: TextStyle(fontSize: 20));
    if (_error != null) {
      return Text('Error: $_error',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Colors.red));
    }
    if (_done) {
      return Text(
          'Done. Deleted $_deleted legacy users.\nThey will re-onboard fresh on next sign-in.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20));
    }
    if (_deleting) {
      return Text('Deleting... ($_deleted/${_docs.length})',
          style: const TextStyle(fontSize: 20));
    }
    if (_docs.isEmpty) {
      return const Text('No legacy docs — nothing to clean up.',
          style: TextStyle(fontSize: 20));
    }
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Found ${_docs.length} legacy user docs (no phone backfill):',
              style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 12),
          for (final d in _docs)
            Text('•  ${d.uid}  —  "${d.name}"  (${d.role})'),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('deleteAllBtn'),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: _deleteAll,
            child: Text('Delete all ${_docs.length}'),
          ),
        ],
      ),
    );
  }
}
