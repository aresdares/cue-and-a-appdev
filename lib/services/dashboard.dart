import "package:appdev_project/main.dart";
import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";

import "../databases/database.dart";
import "../services/ui_builder.dart";

class DashboardUtil {
  String? get userID => FirebaseAuth.instance.currentUser?.uid;

  Future<String> createNotebook(String name, String color) async{
    Notebook notebook=Notebook(id: "", name: name, color: color, dateCreated: DateTime.now(), dateModified: DateTime.now());
    
    DocumentReference referenceObj= await FirebaseFirestore.instance.collection('users').doc(userID).collection('notebooks').add(notebook.toMap());

    return referenceObj.id;
  }

  Future<String> createNote(String title, {String? notebookId,}) async{
    Note note=Note(id: "", title: title, notebookId: notebookId, dateCreated: DateTime.now(), dateModified: DateTime.now());
    
    DocumentReference referenceObj= await FirebaseFirestore.instance.collection('users').doc(userID).collection('notes').add(note.toMap());

    return referenceObj.id;
  }

  Future<String> createContent(String topic, String information, String noteId,) async{
    ContentItem content=ContentItem(id: "", noteId: noteId, topic: topic, information: information);
    
    DocumentReference referenceObj= await FirebaseFirestore.instance.collection('users').doc(userID).collection('notes').doc(noteId).collection('contents').add(content.toMap());

    return referenceObj.id;
  }
  
  Future<Notebook> getNotebook(String id) async{
    DocumentSnapshot<Map<String,dynamic>> map= await FirebaseFirestore.instance.collection('users').doc(userID).collection('notebooks').doc(id).get();

    return Notebook.fromMap(map.data() as Map<String,dynamic>, id);
  }

  Future<Note> getNote(String id) async{
    DocumentSnapshot<Map<String,dynamic>> map= await FirebaseFirestore.instance.collection('users').doc(userID).collection('notes').doc(id).get();

    return Note.fromMap(map.data() as Map<String,dynamic>, id);
  }

  Future<void> updateNote(String noteId, String title, String? notebookId) async{
    await FirebaseFirestore.instance.collection('users').doc(userID).collection('notes').doc(noteId).update({
      'notebookId':notebookId,
      'title':title,
      'dateModified':DateTime.now()
    });
  }

  Future<void> copyNotebook(Notebook notebook) async{
    String newNotebookId= await createNotebook("Copy of "+notebook.name, notebook.color);
    QuerySnapshot<Map<String, dynamic>> notes= await FirebaseFirestore.instance.collection('users').doc(userID).collection('notes').where('notebookId', isEqualTo: notebook.id).get();
    for (var note in notes.docs){
      final data=note.data();
      await copyNote(
        Note(id: note.id,notebookId: newNotebookId, title: data['title'], dateCreated: DateTime.now(), dateModified: DateTime.now())
      );
    }
  }

  Future<void> copyNote(Note note) async{
    String newNoteId=await createNote(note.title,notebookId: note.notebookId);
    QuerySnapshot<Map<String, dynamic>> contents= await FirebaseFirestore.instance.collection('users').doc(userID).collection('notes').doc(note.id).collection('contents').where('noteId', isEqualTo: note.id).get();
    for (var content in contents.docs){
      final data=content.data();
      await createContent(data['topic'], data['information'], newNoteId);
    }
  }

  Future<void> updateNotebook(String id, String name, String color) async{
    await FirebaseFirestore.instance.collection('users').doc(userID).collection('notebooks').doc(id).update({
      'name':name,
      'color':color,
      'dateModified':DateTime.now()
    });

  }
}

class Dashboard extends StatefulWidget {
  const new({super.key, required this.userSettings});

  final UserSettings userSettings;

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  String? get userID => FirebaseAuth.instance.currentUser?.uid;
  List<Note> noteList=[];
  List<Notebook> notebookList=[];
  DashboardUtil dashboardUtil=DashboardUtil();


  @override
  void initState() {
    super.initState();
    generateNoteList();
    generateNotebookList();
  }

  Future<void> generateNoteList() async{
    noteList.clear();
    List<Note> loadedNotes = [];
    QuerySnapshot<Map<String, dynamic>> querySnapshot= await FirebaseFirestore.instance.collection('users').doc(userID).collection('notes').where('notebookId', isNull: true).get();
    for (var doc in querySnapshot.docs){
      final data=doc.data();
      loadedNotes.add(
        Note(id: doc.id, title: data['title'], dateCreated: (data['dateCreated']as Timestamp).toDate(), dateModified: (data['dateModified']as Timestamp).toDate())
      );
    }
    setState(() {
      noteList=loadedNotes;
    });
  }

  Future<void> generateNotebookList() async{
    notebookList.clear();
    QuerySnapshot<Map<String, dynamic>> querySnapshot= await FirebaseFirestore.instance.collection('users').doc(userID).collection('notebooks').get();
    List<Notebook> loadedNotebooks=[];
    for (var doc in querySnapshot.docs){
      final data=doc.data();
      loadedNotebooks.add(
       Notebook(id: doc.id, name: data['name'], color: data['color'], dateCreated: (data['dateCreated']as Timestamp).toDate(), dateModified: (data['dateModified']as Timestamp).toDate())
      );
    }
    setState(() {
      notebookList=loadedNotebooks;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UiBuilder.appBarBuilder(this,"Dashboard",accessNote: false,disableBack: true),
      drawer: UiBuilder.drawerBuilder(this),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 20,
        children: [
          Text("Notebooks"),
          Row(
            spacing: 10,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (Notebook item in notebookList) notebookWidget(item),
            ],
          ),
          Text("Notes (Untagged)"),
          for (Note item in noteList) noteWidget(item)
        ],
      ),
    );
  }
}

Widget notebookWidget(Notebook notebook){
  return Column(
    spacing: 5,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 2,
        children: [
          ElevatedButton(
            onPressed: ()=>{}, 
            child: Text("Icon for notebook")
          ),
          notebookOptions(notebook)
        ],
      ),
      
      Text(notebook.name),
    ],
  );
}

Widget noteWidget(Note note){
  return Column(
    spacing: 5,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 2,
        children: [
          ElevatedButton(
            onPressed: ()=>{}, 
            child: Text("Icon for note")
          ),
          ElevatedButton(
            onPressed: ()=>{}, 
            child: Text("options")
          ),
        ],
      ),
      Text(note.title),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: ()=>{}, 
            child: Text("Icon for fc")
          ),
          ElevatedButton(
            onPressed: ()=>{}, 
            child: Text("Icon for quiz")
          )
        ],
      )
    ],
  );
}



Widget notebookOptions(Notebook notebook) {
    DashboardUtil dbUtil=DashboardUtil();

    return PopupMenuButton(
      icon: const Icon(Icons.more_vert),
      itemBuilder: (BuildContext context)=><PopupMenuEntry>[
        PopupMenuItem(
          onTap: (){
            
          },
          child: Text("Edit")
        ),
        PopupMenuItem(
          onTap: (){
            dbUtil.copyNotebook(notebook);
            final parentState = context.findAncestorStateOfType<_DashboardState>();
            parentState!.generateNotebookList();
          },
          child: Text("Copy")
        ),
        PopupMenuItem(
          onTap: (){

          },
          child: Text("Details")
        ),
        PopupMenuItem(
          onTap: (){

          },
          child: Text("Delete")
        ),
      ]
    );
  }