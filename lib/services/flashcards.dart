import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';
import '../databases/database.dart';

import 'dart:math';

class FlashcardPage extends StatefulWidget {
  const new({super.key, required this.noteid});

  final String noteid;

  @override
  State<FlashcardPage> createState() => _FlashcardPageState();
}

class _FlashcardPageState extends State<FlashcardPage> {

  String titleText = "Flashcards";
  String msg = "Loading...";

  final random = Random();

  //String uid = "ARLMJ9M6YKUD6HgqY29mN0bSIbD2"; 
  User? user;
  String? uid, noteid;

  bool flashcard = false; // Will get this bool from dashboard or note page
  bool shuffle = true;
  //String noteid = "pVAR4EdsMejEHzWoqihN"; // Will get this noteId String from button in dashboard page or note page when merged
  
  List<ContentItem> noteContent = [];
  List<ContentItem> cardContent = [];
  List<ContentItem> previousCardContent = [];
  List<String> blankedInfo = [];
  bool filterWords = true;
  final TextEditingController blankController = TextEditingController();
  String cardText = "";
  bool showtopic = false;

  // DEBUG text to see what's in cardContent
  String cards = "";


  Future<void> getContents() async {
    user = FirebaseAuth.instance.currentUser;
    uid = user?.uid;
    noteid = widget.noteid;

    // DEBUG UID FOR TESTING PURPOSES. DELETE TO TEST REAL AUTH
    uid = "ARLMJ9M6YKUD6HgqY29mN0bSIbD2";

    if(uid == null){
      setState(() => {msg = "User not logged in."});
      return;
    }
    
    final querySnapshot = await FirebaseFirestore.instance.collection('users').doc(uid).collection('notes').doc(widget.noteid).collection("contents").get().timeout(const Duration(seconds: 10));

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
    getCards();
  }




  @override
  void initState() {
    super.initState();
    getContents();
  }

  @override
  Widget build(BuildContext context) {
    if(noteContent.isEmpty || cards.isEmpty){
      return Scaffold(
        body: Center(child: Text(msg),)
      );
    }


    if(cardContent.isEmpty){
      return Scaffold(
        body: Center(child: Text("Note is empty."),)
      );
    }

    if(flashcard){
      return flashCards();
    } else {
      return blanksQuiz();
    }
  }


  // FLASHCARD FRONTEND
  Widget flashCards(){
    return Scaffold( 
      body:Center(
      child:Column(
        children: [
          menuButton(),
          backButton(),
          pfpButton(),
          quizTypeToggleButton(),
          shuffleToggleButton(),
          // Text("\n$cards"), // DEBUG
          flashCardWidget(),
          // Text("\n[DEBUG] score: ${cardContent[0].score}\n"), // DEBUG
          wrongFlashCardButton(),
          correctFlashCardButton(),
        ],
      )
    ));
  }


  // QUIZ FRONTEND
  Widget blanksQuiz(){
    return Scaffold( body:Center(
      child:Column(
        children: [
          menuButton(),
          backButton(),
          Text("Fill in the Blanks"),
          pfpButton(),
          quizTypeToggleButton(),
          // Text("\n$cards"), // DEBUG
          blankInfo(cardContent[0].topic,cardContent[0].information),
          Text("\n[DEBUG] answer: ${blankedInfo[1]}\n"), // DEBUG
          checkAnswerButton(),
          filterCheckBox()
        ],
      )
    ));
  }

  Appbar appBarBuilder(){
    return Appbar(
      title: titleText,
    );
  }


  // Menu Button
  Widget menuButton(){
    return IconButton(
      icon: const Icon(Icons.menu_rounded),
      onPressed: () => setState(() {
        // menu function
      })
    );
  }


  // Back button meant for appbar
  Widget backButton(){
    return IconButton(
      icon: const Icon(Icons.arrow_back_rounded),
      onPressed: () => setState(() {
        Navigator.pop(context);
      })
    );
  }

  // PFP button meant for appbar
  Widget pfpButton(){
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: () {
        // profile picture function
      },
    child: const CircleAvatar(
      radius: 24, // ADJUST FOR FRONTEND
      backgroundImage: NetworkImage('https://upload.wikimedia.org/wikipedia/commons/7/7c/Profile_avatar_placeholder_large.png?utm_source=commons.wikimedia.org&utm_campaign=index&utm_content=thumbnail_unscaled'), // PLACEHOLDER
      backgroundColor: Colors.grey,
    ),
  );
  }



  // TOGGLE BUTTON
  Widget quizTypeToggleButton(){
    String buttonText = "F | [B]";
    if(flashcard){
      buttonText = "[F] | B";
    }

    return ElevatedButton(
      onPressed: () => setState(() {
        flashcard = !flashcard;
      }), 
      child: Text(buttonText)
    );
  }


  Widget shuffleToggleButton(){
    return ElevatedButton(
      onPressed: () => setState(() {
        shuffle = !shuffle;
      }), 
      child: Text("Shuffle${shuffle?" ON":" OFF"}") // add shuffle icon
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
    return ElevatedButton(
      onPressed: () => nextContent(-1), 
      child: Text("Got it wrong")
    );
  }

  // Button for getting a flashcard correct
  Widget correctFlashCardButton(){
    return ElevatedButton(
      onPressed: () => nextContent(1), 
      child: Text("Got it right")
    );
  }

  // Button to check answer in blank
  Widget checkAnswerButton(){
    return ElevatedButton(
      onPressed: () => checkBlank(), 
      child: Text("Check Answer")
    );
  }

  Widget filterCheckBox(){
    return SizedBox(
      width:300, // ADJUST FOR FRONTEND
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
    );
  }



















  @override
  void dispose() {
    blankController.dispose();
    super.dispose();
  }




  List<ContentItem> filterContent(List<ContentItem> content,{int? score}){
    List<ContentItem> filtered = [];

    for(final item in content){
      if (score != null && item.score == score){
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




  void nextContent(int bonus) async {
    try{
      FirebaseFirestore.instance.collection('users').doc(uid).collection('notes').doc(widget.noteid).collection("contents").doc(cardContent[0].id).update({"score": cardContent[0].score + bonus});
      
      final c = await FirebaseFirestore.instance.collection('users').doc(uid).collection('notes').doc(widget.noteid).collection("contents").doc(cardContent[0].id).get().timeout(const Duration(seconds: 10));
      cardContent[0].score = ContentItem.fromMap(c.data()!,c.id).score;
      previousCardContent.add(cardContent[0]);
      cardContent.removeAt(0);

      getCards();
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
    if (ans == blankedInfo[1]) {
      nextContent(1);
    } else {
      nextContent(-1);
    }
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

    List<String> filler = ['maybe','could','are','just','defined','by','where','do','means',':',')','(','\n','is','for','and','nor','but','or','yet','so','the','a','an','no','i','you','she','he','it','we','they','me','you','him','her','it','us','them','mine','yours','his','hers','its','ours','theirs','my','your','his','her','its','our','their','myself','yourself','himself','herself','itself','oneself','ourselves','yourselves','themselves','this','that','these','those','such','neither','who','whom','whose','which','that','whoever','whomever','whichever','whatever','who','whom','whose','what','which','whatever','another','anybody','anyone','anything','each','either','everybody','everyone','everything','much','neither','nobody','somebody','someone','somethings','in','on','at','by','for','with','about','against','between','into','through','during','before','after','above','below','about','across','during','except','since','against','for','than','along','from','through','among','in','to','around','toward','as','into','at','like','of','until','onto','via','with','by'];

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



  Future<void> getCards() async {

    
    // Gets all content under the note being viewed
    noteContent;

    // Gets all content with the lowest score in the note
    if(cardContent.isEmpty){
      int? minScore = getMinScore(noteContent);
      cardContent = filterContent(noteContent,score: minScore);
      if(shuffle){
        cardContent.shuffle();
      }
    }
    
    cardText = cardContent[0].information;
    showtopic = false;

    String str = "";

    for (final card in noteContent){
      str += "${card.topic} ${card.score}\n";
    }

    cards = str;
    setState(() {
    });
  }

}