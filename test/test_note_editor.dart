import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../lib/firebase_options.dart';
import '../lib/databases/database.dart';
import '../lib/pages/note_editor_page.dart'; // <-- Change to your actual file path/name
import '../lib/main.dart';

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

  UserSettings usersettings = UserSettings(uid: "");
  DocumentReference noteRef = await FirebaseFirestore.instance
      .collection('users')
      .doc(user!.uid)
      .collection('notes')
      .add(dummyNote.toMap());

  // 5. Launch the app directly into NoteEditorPage with that new noteId
  runApp(TempTestApp(testNoteId: noteRef.id, usersettings: usersettings));
}

class TempTestApp extends StatelessWidget {
  final String testNoteId;
  final UserSettings usersettings;

  const TempTestApp({super.key, required this.testNoteId, required this.usersettings});


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: NoteEditorPage(noteId: testNoteId, userSettings: usersettings),
    );
  }
}

