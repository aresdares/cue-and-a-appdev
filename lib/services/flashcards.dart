import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';
import '../databases/database.dart';

import 'dart:math';

class FlashcardPage extends StatefulWidget {
  const new({super.key});

  @override
  State<FlashcardPage> createState() => _FlashcardPageState();
}

class _FlashcardPageState extends State<FlashcardPage> {
  
  final random = Random();

  // FOR TESTING PURPOSES placeholder content item.
  // I need to replace this with getting contentitems from Firebase.
  final content = [
    ContentItem(id:"1",noteId:"A",topic:"Grid World",information:"A maze-like problem"),
    ContentItem(id:"2",noteId:"A",topic:"Grid World",information:"Noisy movement: actions do not always go as planned"),
    ContentItem(id:"3",noteId:"A",topic:"Grid World",information:"The agent receives rewards each time step"),
    ContentItem(id:"4",noteId:"A",topic:"Grid World",information:"Goal: maximize sum of rewards"),
    ContentItem(id:"5",noteId:"A",topic:"Markov Decision Process",information:"An MDP is defined by: \n- A set of states s\n- A set of actions a\n- A transition function T(s, a, s')\n- A reward function R(s, a, s')\n- A start state s_0\n- Maybe a terminal state"),
    ContentItem(id:"6",noteId:"A",topic:"Markov Decision Process",information:"are non-deterministic search problems"),
    ContentItem(id:"7",noteId:"A",topic:"Markov",information:"generally means that given the present state, the future and the past are independent"),
    ContentItem(id:"8",noteId:"A",topic:"Markov",information:"for Markov decision processes, means an action outcoms depend only on the current state"),
    ContentItem(id:"9",noteId:"A",topic:"Markov",information:"This is just like search where the successor function could only depend on the current state (not the history)"),
  ];
  
  bool flashcard = false; // Will get this bool from dashboard or note page
  String currentNote = "A"; // Will get this noteId String from button in dashboard page or note page when merged
  List<ContentItem> noteContent = [];
  List<ContentItem> cardContent = [];
  List<String> blankedInfo = [];
  bool filterWords = true;























































































































































































































































































































































































































































































































  final TextEditingController blankController = TextEditingController();

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
    for(final card in noteContent){
      cards += "${card.topic} ${card.score}\n";
    }

    if(flashcard){

      // FLASHCARD FRONTEND
      return Scaffold( body:Center(
        child:Column(
          children: [
            ElevatedButton(
              onPressed: () => setState(() {
                flashcard = !flashcard;
              }), 
              child: Text("[F] | B")
            ),
            Text("\n$cards"),
            Text(cardContent[0].topic),
            Text(cardContent[0].information),
            Text("\n[DEBUG] score: ${cardContent[0].score}\n"),
            ElevatedButton(
              onPressed: () => nextContent(-1), 
              child: Text("Got it wrong")
            ),
            ElevatedButton(
              onPressed: () => nextContent(1), 
              child: Text("Got it right")
            )
          ],
        )
      ));
    } else {

      // QUIZ FRONTEND
      return Scaffold( body:Center(
        child:Column(
          children: [
            ElevatedButton(
              onPressed: () => setState(() {
                flashcard = !flashcard;
              }), 
              child: Text("F | [B]")
            ),
            Text("\n$cards"),
            blankInfo(cardContent[0].topic,cardContent[0].information),
            Text("\n[DEBUG] answer: ${blankedInfo[1]}"),
            Text(""),
            ElevatedButton(
              onPressed: () => checkBlank(), 
              child: Text("Check Answer")
            ),
            SizedBox(
              width:300,
              child:Row(
                children: [
                  Checkbox(
                    value: filterWords, 
                    onChanged: (bool? value) => setState(() {
                      value ??= true;
                      filterWords = value!; 
                    })
                  ),
                  Text("Only allow key nouns/verbs as blanks")
                ],
              ),
            ),
          ],
        )
      ));
    }

    
  }


  @override
  void dispose() {
    blankController.dispose();
    super.dispose();
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

  // QUIZ FUNCTIONS

  Widget blank(TextEditingController controller, {double width = 80}) {
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

  void checkBlank() {
    final ans = blankController.text.trim().toLowerCase();
    blankController.text = "";
    setState(() {
      if (ans == blankedInfo[1]) {
        nextContent(1);
      } else {
        nextContent(-1);
      }
    });
  }

  Widget blankInfo(String topic,String text){
    blankedInfo = parseBERT(topic, text);

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: blankedInfo[0]),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: blank(blankController, width: 90),
          ),
          TextSpan(text: blankedInfo[2])
        ],
      ),
    );
  }

  List<String> parseBERT(String topic, String text){

    final wordRegex = RegExp(r'\b\w+\b');
    final matches = wordRegex.allMatches(text);
    List<RegExpMatch> words = [];

    List<String> filler = ['maybe','could','are','just','defined','by','where','do','means',':',')','(','\n','is','for','and','nor','but','or','yet','so','the','a','an','no','i','you','she','he','it','we','they','me','you','him','her','it','us','them','mine','yours','his','hers','its','ours','theirs','my','your','his','her','its','our','their','myself','yourself','himself','herself','itself','oneself','ourselves','yourselves','themselves','this','that','these','those','such','neither','who','whom','whose','which','that','whoever','whomever','whichever','whatever','who','whom','whose','what','which','whatever','another','anybody','anyone','anything','each','either','everybody','everyone','everything','much','neither','nobody','somebody','someone','somethings','in','on','at','by','for','with','about','against','between','into','through','during','before','after','above','below','about','across','during','exept','since','against','for','than','along','from','through','among','in','to','around','toward','as','into','at','like','of','until','onto','via','with','by'];

    for(final match in matches){
      if(!filterWords || !filler.contains(match.group(0)!.toLowerCase())){
        words.add(match);
      }

    }

    int ans = random.nextInt(words.length);
    
    String front = "$topic\n${text.substring(0,words[ans].start)}";
    String answer = words[ans].group(0)!;
    String back = text.substring(words[ans].end);

    List<String> parsed = [front,answer,back];
    return parsed;
  }

}