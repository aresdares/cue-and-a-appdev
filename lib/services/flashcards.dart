import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';
import '../databases/database.dart';
import './ui_builder.dart';

import '../main.dart';
import 'dart:math';

class Flashcard{

  static Future<void> getContents(caller) async {
    print("getcontent");
    caller.noteId = caller.widget.noteId;

    if(caller.widget.userSettings.uid == null){
      caller.setState(() => {caller.msg = "User not logged in."});
      return;
    }
    
    print("querying"+caller.widget.userSettings.uid+" "+caller.widget.noteId);
    final querySnapshot = await FirebaseFirestore.instance.collection('users').doc(caller.widget.userSettings.uid).collection('notes').doc(caller.widget.noteId).collection("contents").get().timeout(const Duration(seconds: 30));
    print("query end");

    if(querySnapshot.size > 0){
      print("qssize");
      for(var doc in querySnapshot.docs) {
        caller.noteContent!.add(ContentItem.fromMap(doc.data(), doc.id));
      }
    }

    caller.noteContent.sort((ContentItem a, ContentItem b) => a.position.compareTo(b.position));
    
    getCards(caller);
    caller.isLoading = false;
    print("getcontent_end");
  }

  static List<ContentItem> filterContent(List<ContentItem> content,{int? score}){
    List<ContentItem> filtered = [];

    for(final item in content){
      if (score != null && item.score == score){
        filtered.add(item);
      }
    }
    return filtered;
  }




  static int? getMinScore(List<ContentItem> content){
    int? min;

    for(final item in content){
      min ??= item.score;
      if(min > item.score){
        min = item.score;
      }
    }
    return min;
  }



  static void nextContent(caller, int bonus) async {
    print("nextContent");
    try{
      FirebaseFirestore.instance.collection('users').doc(caller.widget.userSettings.uid).collection('notes').doc(caller.widget.noteId).collection("contents").doc(caller.cardContent[0].id).update({"score": caller.cardContent[0].score + bonus});
      final c = await FirebaseFirestore.instance.collection('users').doc(caller.widget.userSettings.uid).collection('notes').doc(caller.widget.noteId).collection("contents").doc(caller.cardContent[0].id).get().timeout(const Duration(seconds: 10));
      caller.cardContent[0].score = ContentItem.fromMap(c.data()!,c.id).score;
      caller.previousCardContent.add(caller.cardContent[0]);
      caller.cardContent.removeAt(0);

      getCards(caller);
    }catch(e){}
  }

  static void prevContent(caller) async {
    try{
      caller.cardContent.insert(0, caller.previousCardContent.last);
      getCards(caller);
    }catch(e){}
  }



  // QUIZ FUNCTIONS

  static Widget blank(TextEditingController controller, {double width = 80}) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 2, horizontal: 4),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.blue, width: 2),
          ),
        ),
      ),
    );
  }



  static void checkBlank(caller) {
    final ans = caller.blankController.text.trim().toLowerCase();
    caller.blankController.text = "";
    if (ans == caller.blankedInfo[1]) {
      nextContent(caller,1);
    } else {
      nextContent(caller,-1);
    }
  }



  static Widget blankInfo(caller,String topic,String text){
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: caller.blankedInfo[0]),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: blank(caller.blankController, width: 90),
          ),
          TextSpan(text: caller.blankedInfo[2])
        ],
      ),
    );
  }



  static List<String> parseBERT(caller,String topic, String text){

    final wordRegex = RegExp(r'\b\w+\b');
    final matches = wordRegex.allMatches(text);
    List<RegExpMatch> words = [];

    List<String> filler = ['maybe','could','are','just','defined','by','where','do','means',':',')','(','\n','is','for','and','nor','but','or','yet','so','the','a','an','no','i','you','she','he','it','we','they','me','you','him','her','it','us','them','mine','yours','his','hers','its','ours','theirs','my','your','his','her','its','our','their','myself','yourself','himself','herself','itself','oneself','ourselves','yourselves','themselves','this','that','these','those','such','neither','who','whom','whose','which','that','whoever','whomever','whichever','whatever','who','whom','whose','what','which','whatever','another','anybody','anyone','anything','each','either','everybody','everyone','everything','much','neither','nobody','somebody','someone','somethings','in','on','at','by','for','with','about','against','between','into','through','during','before','after','above','below','about','across','during','except','since','against','for','than','along','from','through','among','in','to','around','toward','as','into','at','like','of','until','onto','via','with','by'];

    for(final match in matches){
      if(!caller.widget.userSettings.filterWords || !filler.contains(match.group(0)!.toLowerCase())){
        words.add(match);
      }

    }

    int ans = caller.widget.random.nextInt(words.length);
    
    String front = "$topic\n${text.substring(0,words[ans].start)}";
    String answer = words[ans].group(0)!;
    String back = text.substring(words[ans].end);

    List<String> parsed = [front,answer,back];
    return parsed;
  }



  static Future<void> getCards(caller) async {
    print("getcards");
    // Gets all content with the lowest score in the note
    if(caller.cardContent.isEmpty){
      if(caller.widget.userSettings.flashScoring){
        int? minScore = getMinScore(caller.noteContent);
        caller.cardContent = filterContent(caller.noteContent,score: minScore);
      }else{
        caller.cardContent = caller.noteContent.sublist(0);
      }
      if(caller.widget.userSettings.shuffle){
        caller.cardContent.shuffle();
      }
    }
    
    caller.cardText = caller.cardContent[0].information;
    caller.showtopic = false;

    String str = "";

    for (final card in caller.noteContent){
      str += "${card.topic} ${card.score}\n";
    }

    caller.blankedInfo = parseBERT(caller,caller.cardContent[0].topic, caller.cardContent[0].information);

    caller.setState(() {  
      caller.cards = str;

      caller.isLoading = false;
      print("getcards_end");
    });
  }

  static void resetScores(caller) async{
    try{
      for(final n in caller.noteContent){
        FirebaseFirestore.instance.collection('users').doc(caller.userSettings.uid).collection('notes').doc(caller.widget.noteId).collection("contents").doc(n.id).update({"score": 0});
        n.score = 0;
      }
      caller.cardContent = [];
      getCards(caller);
    }catch(e){}
  }

}