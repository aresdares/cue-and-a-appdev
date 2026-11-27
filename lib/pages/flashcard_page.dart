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
  new({super.key, required this.userSettings, required this.noteId, required this.flashcard});

  final random = Random();
  final String noteId;
  final bool flashcard;
  final UserSettings userSettings;

  @override
  State<FlashcardPage> createState() => _FlashcardPageState();
}

class _FlashcardPageState extends State<FlashcardPage> {

  // CONFIG VARS
  User? user;
  String? noteId;
  bool? flashcard;

  // DATA VARS
  String noteTitle = "";
  List<ContentItem> noteContent = [];
  List<ContentItem> cardContent = [];
  List<ContentItem> previousCardContent = [];
  List<String> blankedInfo = [];

  // LOGIC VARS
  final TextEditingController blankController = TextEditingController();
  String cardText = "";
  bool showtopic = false;
  bool isLoading = true;
  String titleText = "Flashcards";
  String msg = "";

  // DEBUG VARS
  String cards = "";

  @override
  void initState() {
    print("init");
    super.initState();
    flashcard = widget.flashcard;
    Flashcard.getContents(this);
  }



  @override
  Widget build(BuildContext context) {
    // FRONTEND WHEN LOADING OR NOTE IS EMPTY
    if(isLoading || noteContent.isEmpty){
      if(cardContent.isEmpty){msg = "This note is empty.";}
      return Scaffold(
        appBar: UiBuilder.appBarBuilder(this,titleText,accessNote: true),
        drawer: UiBuilder.drawerBuilder(this),
        body: Center(child: message())
      );
    }

    print("build_end");
    // FRONTEND
    if(flashcard??widget.flashcard){
      titleText = "Flashcards";
      return flashCards();
    } else {
      titleText = "Fill in the Blanks";
      return blanksQuiz();
    }
  }





  // PAGE BODY WHEN LOADING OR DISPLAYING ERROR MESSAGE
  Widget message(){
    if (msg.isEmpty){
    print("message");
      return const CircularProgressIndicator();
    }else{
      return Text(msg);
    }
  }







  // ========== MODES ===========

  // FLASHCARD FRONTEND
  Widget flashCards(){
    return Scaffold(
        appBar: UiBuilder.appBarBuilder(this,titleText,accessNote: true),
        drawer: UiBuilder.drawerBuilder(this),
        body: Center(
          child: Column(
              spacing: 10,
              children: [
                quizTypeToggleButton(),
                settingsButton(),
                // Text("\n$cards"), // DEBUG
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
              spacing: 10,
            children: [
              quizTypeToggleButton(),
              settingsButton(),
              // Text("\n$cards"), // DEBUG
              Flashcard.blankInfo(this,cardContent[0].topic,cardContent[0].information),
              // Text("\n[DEBUG] answer: ${blankedInfo[1]}, shuffle: ${widget.usersettings.shuffle}, filter: ${widget.usersettings.filterWords}, scoring: ${widget.usersettings.flashScoring}\n"), // DEBUG
              checkAnswerButton(),
            ],
          
        )
      )
    );
  }











  // ========== WIDGETS ==========

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
    if(widget.userSettings.flashScoring){
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
    if(widget.userSettings.flashScoring){
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