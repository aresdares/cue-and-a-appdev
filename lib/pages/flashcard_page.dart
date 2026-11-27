import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';
import '../databases/database.dart';

import '../services/flashcards.dart';
import '../services/ui_builder.dart';

import '../main.dart';
import 'dart:math';

class FlashcardPage extends StatefulWidget {
  new({super.key, required this.usersettings, required this.noteid, required this.flashcard});

  final random = Random();
  final String noteid;
  final bool flashcard;
  final UserSettings usersettings;

  @override
  State<FlashcardPage> createState() => _FlashcardPageState();
}

class _FlashcardPageState extends State<FlashcardPage> {

  bool isLoading = true;
  String titleText = "Flashcards";
  String msg = "";

  //String uid = "ARLMJ9M6YKUD6HgqY29mN0bSIbD2"; 
  User? user;
  String? uid, noteid;
  
  bool? flashcard;
  //String noteid = "pVAR4EdsMejEHzWoqihN"; // Will get this noteId String from button in dashboard page or note page when merged
  
  String noteTitle = "";
  List<ContentItem> noteContent = [];
  List<ContentItem> cardContent = [];
  List<ContentItem> previousCardContent = [];
  List<String> blankedInfo = [];
  final TextEditingController blankController = TextEditingController();
  String cardText = "";
  bool showtopic = false;

  // DEBUG text to see what's in cardContent
  String cards = "";


  Future<void> getContents() async {
    user = FirebaseAuth.instance.currentUser;
    uid = user?.uid;
    noteid = widget.noteid;

    //final doc = await FirebaseFirestore.instance.collection('users').doc(uid).collection('notes').doc(noteid!).get();
    //Note note = Note.fromMap(doc.data()!, doc.id);
    //noteTitle = noteid!;

    // DEBUG UID FOR TESTING PURPOSES. DELETE TO TEST REAL AUTH
    uid = "ARLMJ9M6YKUD6HgqY29mN0bSIbD2";

    if(uid == null){
      setState(() => {msg = "User not logged in."});
      return;
    }
    
    final querySnapshot = await FirebaseFirestore.instance.collection('users').doc(uid).collection('notes').doc(noteid).collection("contents").get().timeout(const Duration(seconds: 10));

    if(querySnapshot.size > 0){
      for(var doc in querySnapshot.docs) {
        noteContent!.add(ContentItem.fromMap(doc.data(), doc.id));
      }
    }

    if(noteContent!.isEmpty){
      setState(() => {msg = "Note not found."});
      return;
    }
    
    noteContent.sort((a, b) => a.position.compareTo(b.position));
    Flashcard.getCards(this);
    isLoading = false;
  }




  @override
  void initState() {
    super.initState();
    flashcard = widget.flashcard;
    getContents();
  }

  @override
  Widget build(BuildContext context) {
    if(isLoading){
      return Scaffold(
        appBar: UiBuilder.appBarBuilder(this,titleText),
        drawer: UiBuilder.drawerBuilder(this),
        body: Center(child: message())
      );
    }

    if(cardContent.isEmpty){
      msg = "This note is empty.";
      return Scaffold(
        appBar: UiBuilder.appBarBuilder(this,titleText),
        drawer: UiBuilder.drawerBuilder(this),
        body: Center(child: message())
      );
    }

    if(flashcard??widget.flashcard){
      titleText = "Flashcards";
      return flashCards();
    } else {
      titleText = "Fill in the Blanks";
      return blanksQuiz();
    }
  }

  Widget message(){
    if (msg.isEmpty){
      return const CircularProgressIndicator();
    }else{
      return Text(msg);
    }
  }

  // FLASHCARD FRONTEND
  Widget flashCards(){
    return Scaffold(
        appBar: UiBuilder.appBarBuilder(this,titleText),
        drawer: UiBuilder.drawerBuilder(this),
        body: Center(
          child: Column(
              children: [
                quizTypeToggleButton(),
                settingsButton(),
                Text("\n$cards"), // DEBUG
                flashCardWidget(),
                // Text("\n[DEBUG] score: ${cardContent[0].score}\n"), // DEBUG
                wrongFlashCardButton(),
                correctFlashCardButton(),
              ],
            )
          )
        
      );
  }


  // QUIZ FRONTEND
  Widget blanksQuiz(){
    return Scaffold(
        appBar: UiBuilder.appBarBuilder(this,titleText),
        drawer: UiBuilder.drawerBuilder(this),
        body: Center(
        child:Column(
            children: [
              quizTypeToggleButton(),
              settingsButton(),
              // Text("\n$cards"), // DEBUG
              Flashcard.blankInfo(this,cardContent[0].topic,cardContent[0].information),
              Text("\n[DEBUG] answer: ${blankedInfo[1]}, shuffle: ${widget.usersettings.shuffle}, filter: ${widget.usersettings.filterWords}, scoring: ${widget.usersettings.flashScoring}\n"), // DEBUG
              checkAnswerButton(),
            ],
          
        )
      )
    );
  }

  // TOGGLE BUTTON
  Widget quizTypeToggleButton(){
    String buttonText = "F | [B]";
    if(flashcard??widget.flashcard){
      buttonText = "[F] | B";
    }

    return ElevatedButton(
      onPressed: () => setState(() {
        flashcard = !(flashcard??widget.flashcard);
      }), 
      child: Text(buttonText)
    );
  }

  // NOTE SETTINGS
  Widget settingsButton(){
    return PopupMenuButton(
      onSelected: (value) {
          Flashcard.resetScores(this);
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry>[
        const PopupMenuItem(
          value: 0,
          child: ListTile(
            title: Text('Reset Progress Tracking'),
          ),
        ),
      ],
    );
  }


  // The Flashcard itself
  Widget flashCardWidget(){
    return ElevatedButton(
      onPressed: () => setState(() {
        if(!showtopic){
          cardText = cardContent[0].topic;
          showtopic = true;
        } else {
          cardText = cardContent[0].information;
          showtopic = false;
        }
      }), 
      child: Text(cardText)
    );
  }


  // Button for getting a flashcard wrong
  Widget wrongFlashCardButton(){
    if(widget.usersettings.flashScoring){
      return IconButton(
        onPressed: () => Flashcard.nextContent(this,-1), 
        icon: Icon(Icons.close_rounded)
      );
    }else{
      return IconButton(
        onPressed: () => Flashcard.prevContent(this), 
        icon: Icon(Icons.arrow_back_rounded)
      );
    }
  }

  // Button for getting a flashcard correct
  Widget correctFlashCardButton(){
    if(widget.usersettings.flashScoring){
      return IconButton(
        onPressed: () => Flashcard.nextContent(this,1), 
        icon: Icon(Icons.check_rounded)
      );
    }else{
      return IconButton(
        onPressed: () => Flashcard.nextContent(this,0), 
        icon: Icon(Icons.arrow_forward_rounded)
      );
    }
  }

  // Button to check answer in blank
  Widget checkAnswerButton(){
    return ElevatedButton(
      onPressed: () => Flashcard.checkBlank(this), 
      child: Text("Check Answer")
    );
  }

  @override
  void dispose() {
    blankController.dispose();
    super.dispose();
  }
}