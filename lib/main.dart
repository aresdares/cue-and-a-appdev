import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'databases/database.dart';
import 'pages/note_editor_page.dart'; // <-- Change to your actual file path/name

void main() async {
  // 1. Required before calling any async Firebase setup inside main()
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Connects the app to your Firebase project
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Log in (or create) your test account so currentUser! is never null
  User? user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    try {
      UserCredential cred =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: 'stephen_test@group4.com',
        password: 'password123',
      );
      user = cred.user;
    } catch (_) {
      UserCredential cred =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: 'stephen_test@group4.com',
        password: 'password123',
      );
      user = cred.user;
    }
  }

  // 4. Create 1 fresh dummy Note in Firestore so we have a real noteId to pass in
  Note dummyNote = Note(
    id: '',
    notebookId: null,
    title: 'Test Cornell Note',
    dateCreated: DateTime.now(),
    dateModified: DateTime.now(),
  );

  DocumentReference noteRef = await FirebaseFirestore.instance
      .collection('users')
      .doc(user!.uid)
      .collection('notes')
      .add(dummyNote.toMap());

  // 5. Launch the app directly into NoteEditorPage with that new noteId
  runApp(TempTestApp(testNoteId: noteRef.id));
}

class TempTestApp extends StatelessWidget {
  final String testNoteId;

  const TempTestApp({super.key, required this.testNoteId});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: NoteEditorPage(noteId: testNoteId),
    );
  }
}


/*
import 'package:appdev_project/services/flashcards.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

import '../pages/note_editor_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const FirebaseTestApp());
}

class FirebaseTestApp extends StatelessWidget {
  const FirebaseTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      //  change to home: const NoteEditorTestScreen(),
      //  to test note_editor (assuming test_note_editor is still there)
      home: const NoteEditorPage(),
    );
  }
}

class ConnectionTestScreen extends StatefulWidget {
  const ConnectionTestScreen({super.key});

  @override
  State<ConnectionTestScreen> createState() => _ConnectionTestScreenState();
}

class _ConnectionTestScreenState extends State<ConnectionTestScreen> {
  final TextEditingController _nameController = TextEditingController();
  String _statusMessage = 'Firebase Core initialized! Ready to test.';

  // 1. Test Firebase Auth (creates a dummy user in Authentication)
  Future<void> _testAuth() async {
    try {
      final fakeEmail =
          'user_${DateTime.now().millisecondsSinceEpoch}@group4.com';
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: fakeEmail,
        password: 'password123',
      );
      setState(() {
        _statusMessage = 'AUTH WORKS! Created UID: ${cred.user?.uid}';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'AUTH ERROR: $e';
      });
    }
  }

  // 2. Test Firestore Write (sends your name to the cloud database)
  Future<void> _sendPing() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('connection_test').add({
        'name': name,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _nameController.clear();
      setState(() {
        _statusMessage = 'FIRESTORE WORKS! Sent ping from $name';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'FIRESTORE ERROR: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Group 4 Firebase Tester')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Box
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.blue.shade50,
              child: Text(
                _statusMessage,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),

            // Test Auth Button
            ElevatedButton(
              onPressed: _testAuth,
              child: const Text('1. Test Auth (Create Dummy User)'),
            ),
            const SizedBox(height: 16),

            // Test Firestore Input + Button
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Enter your name (e.g. Stephen)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _sendPing,
                  child: const Text('2. Send'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Live Firestore Pings (Everyone sees this):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Divider(),

            // Live Firestore Reader
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('connection_test')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Stream Error: ${snapshot.error}');
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Text('No pings yet. Type your name above!');
                  }
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      return ListTile(
                        leading: const Icon(Icons.check_circle, color: Colors.green),
                        title: Text('${data['name']} is connected!'),
                        subtitle: Text('Doc ID: ${docs[index].id}'),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
*/