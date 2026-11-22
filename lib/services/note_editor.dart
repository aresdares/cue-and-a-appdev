import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../databases/database.dart';

class NoteEditor {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  //  method for getting get current user
  String getCurrentUserId() {
    return FirebaseAuth.instance.currentUser!.uid;
  }

  //  get user's notes
  CollectionReference getNotesCollection(){
    String uid=getCurrentUserId();
    return FirebaseFirestore.instance.collection('users').doc(uid).collection('notes');
  }

  //  get contents of a notes
  CollectionReference getContentsCollection(String noteId){
    return getNotesCollection().doc(noteId).collection('contents');
  }
  
  //  updates  the last modified date
  Future <void> updateLastModified(String noteId) async{
    await getNotesCollection().doc(noteId).update({
      'dateModified': Timestamp.now(),
    });
  }

}