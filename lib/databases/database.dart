import 'package:cloud_firestore/cloud_firestore.dart';

//  note: 
//      toMap - get Dart object -> turn into Map -> save into FireBase
//      fromMap - get FireBase map + doc.Id -> turn into Dart object
//  
//      toMap is used when adding TO the firebase
//      fromMap is used when adding TO your code
//  
//      "factory" sa fromMap apparemtly means 
//      - ignore the fact that there is no constructor (cz dart strictly enforces constructors)
//      - "trust me bro may return statement to, i'll handle it. don't error" type of thing

//  NOTEBOOK class
class Notebook {
    final String id;
    final String name;
    final String color; // e.g., '#FF5733' or 'red' like the builtin Colors.red
    final DateTime dateCreated;
    final DateTime dateModified;

    //  constructor
    Notebook({
        required this.id,
        required this.name,
        required this.color,
        required this.dateCreated,
        required this.dateModified,
    });

    //  toMap method
    Map<String, dynamic> toMap() {
        //  returns a dictionary/map
        return
        {
            'name': name,
            'color': color,
            'dateCreated': Timestamp.fromDate(dateCreated),
            'dateModified': Timestamp.fromDate(dateModified),
        };
    }

    //  fromMap method
    factory Notebook.fromMap(Map<String, dynamic>map,String docId) {
        return Notebook(
        id: docId,
        name: map['name'] ?? 'Untitled Notebook',
        color: map['color'] ?? '#2196F3',
        dateCreated: (map['dateCreated'] as Timestamp?)?.toDate() ?? DateTime.now(),
        dateModified: (map['dateModified'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
    }
}

class Note {
    final String id; 
    final String? notebookId; // NOTE: nullable! null = untagged ("None")
    final String title;
    final DateTime dateCreated;
    final DateTime dateModified;

    //  constructor
    Note({
        required this.id,
        this.notebookId,
        required this.title,
        required this.dateCreated,
        required this.dateModified,
    });

    //  toMap method
    Map<String, dynamic> toMap() {
        return {
        'notebookId': notebookId,
        'title': title,
        'dateCreated': Timestamp.fromDate(dateCreated),
        'dateModified': Timestamp.fromDate(dateModified),
        };
    }

    //  fromMap method
    factory Note.fromMap(Map<String, dynamic> map, String docId) {
        return Note(
        //  docID to identify ID of data you got from firebase
        id: docId,
        notebookId: map['notebookId'], // stays null if untagged
        title: map['title']??'Unnamed Note',
        dateCreated: (map['dateCreated'] as Timestamp?)?.toDate()??DateTime.now(),
        dateModified: (map['dateModified'] as Timestamp?)?.toDate()??DateTime.now(),
        );
    }
}

class ContentItem{
    final String id; 
    final String noteId;
    final String topic; // LEFT column (cue/topic)
    final String information; // RIGHT column (info/definition)
    final int position;
    int score; // mastery score for Flashcard / Recall mode

    ContentItem({
        required this.id,
        required this.noteId,
        required this.topic,
        required this.information,
        required this.position,
        this.score = 0,
    });

    Map<String,dynamic> toMap() {
        return{
            'noteId': noteId,
            'topic': topic,
            'information': information,
            'position' : position,
            'score': score,
        };
    }

    factory ContentItem.fromMap(Map<String,dynamic>map,String docId){
        return ContentItem(
            //  yeah yeah docID
            id: docId,
            noteId: map['noteId']??'',
            topic: map['topic']??'',
            information: map['information']??'',
            position: map['position']??'',
            score: map['score']??0,
        );
    }
}