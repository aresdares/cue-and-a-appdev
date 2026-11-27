import 'package:appdev_project/pages/note_editor_page.dart';
import 'package:appdev_project/pages/test_home_page.dart';
import 'package:appdev_project/services/authentication.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';


import './pages/note_editor_page.dart';
import './pages/flashcard_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
  
    print(user!.uid); // DEBUG

  final UserSettings userSettings = UserSettings(user: user);
  runApp(CueAndA(userSettings: userSettings));
}




class CueAndA extends StatelessWidget {
  const CueAndA({super.key, required this.userSettings});

  final UserSettings userSettings;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Cue and A",
      initialRoute: "/",
      routes: {
        "/": (context) => TestHomepage(userSettings: userSettings,),
        "/login": (context) => DummyLogin(userSettings: userSettings),
        "/dashboard": (context) => Scaffold(), // DASHBOARD
        "/editor": (context) => NoteEditorPage(userSettings: userSettings, noteId: "pVAR4EdsMejEHzWoqihN"), // NOTE EDITOR
        "/flashcards": (context) => FlashcardPage(userSettings: userSettings, noteId: "pVAR4EdsMejEHzWoqihN", flashcard: true), // FLASHCARDS
      }
    );
  }
}

class UserSettings{
  User user;
  String? uid;
  bool shuffle = true;
  bool filterWords = true;
  bool flashScoring = true;

  UserSettings({required this.user}){
    this.uid = user.uid;
  }
}