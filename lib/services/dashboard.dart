import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";

import "../databases/database.dart";

class DashboardUtil {
  String? get userID => FirebaseAuth.instance.currentUser?.uid;

  Future<String> createNotebook(String name, String color) async{
    Notebook notebook=Notebook(id: "", name: name, color: color, dateCreated: DateTime.now(), dateModified: DateTime.now());
    
    DocumentReference referenceObj= await FirebaseFirestore.instance.collection('users').doc(userID).collection('notebooks').add(notebook.toMap());

    return referenceObj.id;
  }

  Future<String> createNote(String title, {String? notebookId}) async{
    Note note=Note(id: "", title: title, notebookId: notebookId, dateCreated: DateTime.now(), dateModified: DateTime.now());
    
    DocumentReference referenceObj= await FirebaseFirestore.instance.collection('users').doc(userID).collection('notes').add(note.toMap());

    return referenceObj.id;
  }
}