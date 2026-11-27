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
    caller.user = FirebaseAuth.instance.currentUser;
    caller.uid = caller.user?.uid;
    caller.noteid = caller.widget.noteid;

    //final doc = await FirebaseFirestore.instance.collection('users').doc(uid).collection('notes').doc(noteid!).get();
    //Note note = Note.fromMap(doc.data()!, doc.id);
    //noteTitle = noteid!;

    // DEBUG UID FOR TESTING PURPOSES. DELETE TO TEST REAL AUTH
    caller.uid = "ARLMJ9M6YKUD6HgqY29mN0bSIbD2";

    if(caller.uid == null){
      caller.setState(() => {caller.msg = "User not logged in."});
      return;
    }
    
    final querySnapshot = await FirebaseFirestore.instance.collection('users').doc(caller.uid).collection('notes').doc(caller.noteid).collection("contents").get().timeout(const Duration(seconds: 10));

    if(querySnapshot.size > 0){
      for(var doc in querySnapshot.docs) {
        caller.noteContent!.add(ContentItem.fromMap(doc.data(), doc.id));
      }
    }

    if(caller.noteContent!.isEmpty){
      caller.setState(() => {caller.msg = "Note not found."});
      return;
    }
    
    caller.noteContent.sort((a, b) => a.position.compareTo(b.position));
    getCards(caller);
    caller.isLoading = false;
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
    try{
      FirebaseFirestore.instance.collection('users').doc(caller.uid).collection('notes').doc(caller.widget.noteid).collection("contents").doc(caller.cardContent[0].id).update({"score": caller.cardContent[0].score + bonus});
      final c = await FirebaseFirestore.instance.collection('users').doc(caller.uid).collection('notes').doc(caller.widget.noteid).collection("contents").doc(caller.cardContent[0].id).get().timeout(const Duration(seconds: 10));
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
      if(!caller.widget.usersettings.filterWords || !filler.contains(match.group(0)!.toLowerCase())){
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

    // Gets all content with the lowest score in the note
    if(caller.cardContent.isEmpty){
      if(caller.widget.usersettings.flashScoring){
        int? minScore = getMinScore(caller.noteContent);
        caller.cardContent = filterContent(caller.noteContent,score: minScore);
      }else{
        caller.cardContent = caller.noteContent.sublist(0);
      }
      if(caller.widget.usersettings.shuffle){
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
    });
  }

  static void resetScores(caller) async{
    try{
      for(final n in caller.noteContent){
        FirebaseFirestore.instance.collection('users').doc(caller.uid).collection('notes').doc(caller.widget.noteid).collection("contents").doc(n.id).update({"score": 0});
        n.score = 0;
      }
      caller.cardContent = [];
      getCards(caller);
    }catch(e){}
  }

}