import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final UserSettings usersettings = UserSettings();
  runApp(CueAndA(usersettings: usersettings));
}

class CueAndA extends StatelessWidget {
  const CueAndA({super.key, required this.usersettings});

  final UserSettings usersettings;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Cue and A",
      initialRoute: "/flashcards",
      routes: {
        "/": (context) => Scaffold(), // AUTHENTICATION
        "/dashboard": (context) => Scaffold(), // DASHBOARD
        "/editor": (context) => Scaffold(), // NOTE EDITOR
        "/flashcards": (context) => FlashcardPage(usersettings: usersettings, noteid: "pVAR4EdsMejEHzWoqihN", flashcard: true), // FLASHCARDS
      }
    );
  }
}

class UserSettings{
  bool shuffle = true;
  bool filterWords = true;
  bool flashScoring = true;
}