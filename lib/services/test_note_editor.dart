import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';
import '../databases/database.dart';
import '../pages/note_editor_page.dart'; // <-- Change to your actual file path/name

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

