import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';
import '../databases/database.dart';

class FlashcardPage extends StatefulWidget {
  const new({super.key});

  @override
  State<FlashcardPage> createState() => _FlashcardPageState();
}

class _FlashcardPageState extends State<FlashcardPage> {
  
  // FOR TESTING PURPOSES placeholder content item.
  // I need to replace this with getting contentitems from Firebase.
  final content = [
    ContentItem(id:"1",noteId:"A",topic:"topic1",information:"info1"),
    ContentItem(id:"2",noteId:"A",topic:"topic2",information:"info2"),
    ContentItem(id:"3",noteId:"B",topic:"topic3",information:"info3"),
    ContentItem(id:"4",noteId:"B",topic:"topic4",information:"info4"),
    ContentItem(id:"5",noteId:"A",topic:"topic5",information:"info5"),
    ContentItem(id:"6",noteId:"B",topic:"topic6",information:"info6"),
    ContentItem(id:"7",noteId:"A",topic:"topic7",information:"info7"),
    ContentItem(id:"8",noteId:"B",topic:"topic8",information:"info8"),
    ContentItem(id:"9",noteId:"A",topic:"topic9",information:"info9"),
  ];
  
  String currentNote = "A"; // Will get this noteId String from button in dashboard page or note page when merged
  List<ContentItem> noteContent = [];
  List<ContentItem> cardContent = [];

  @override
  Widget build(BuildContext context) {

    // Gets all content under the note being viewed
    noteContent = filterContent(content, note:currentNote);

    // Gets all content with the lowest score in the note
    if(cardContent.isEmpty){
      int? minScore = getMinScore(noteContent);
      cardContent = filterContent(noteContent,score: minScore);
      cardContent.shuffle();
    }

    // DEBUG text to see what's in cardContent
    String cards = "";
    for(final card in cardContent){
      cards += card.topic + " " + card.score.toString() + "\n";
    }

    return Center(
      child:Column(children: [
        Text(cards),
        Text(cardContent[0].topic),
        Text(cardContent[0].information),
        Text(cardContent[0].score.toString()),
        ElevatedButton(
          onPressed: () => nextContent(-1), 
          child: Text("Got it wrong")
        ),
        ElevatedButton(
          onPressed: () => nextContent(1), 
          child: Text("Got it right")
        )
      ],)

    );
  }



  List<ContentItem> filterContent(List<ContentItem> content,{String? note, int? score}){
    List<ContentItem> filtered = [];

    for(final item in content){
      if((note != null && item.noteId == note) || (note==null && item.score == score)){
        filtered.add(item);
      }
    }
    return filtered;
  }


  int? getMinScore(List<ContentItem> content){
    int? min;

    for(final item in content){
      min ??= item.score;
      if(min > item.score){
        min = item.score;
      }
    }
    return min;
  }


  void nextContent(int bonus){
    try{
      // FOR TESTING PURPOSES I made the score not final and I change it directly. 
      // This should be changed when I implement the firebase stuff.
      cardContent[0].score += bonus;
      cardContent.removeAt(0);

      setState(() {

      });
    }catch(e){}
  }

}