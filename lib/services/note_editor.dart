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

  //  listen to live changes being done on a single note
  //  USE THIS FOR THE NOTION-STYLE TITLE CHANGE THING
  Stream<Note> streamNote(String noteId){
    return getNotesCollection().doc(noteId).snapshots().map(
      //  get doc that firestore gave
      (doc){
        //  1. get the data from the doc
        //  2. treat as Map object but return null if the doc doesn't exist
        Map<String,dynamic> data=doc.data() as Map<String, dynamic>? ?? {};
        //  3. return the extracted data that spits out a Note object
        return Note.fromMap(data,doc.id);
      }
    );
  }

  //  saves new title if user edits the header
  Future<void> updateNoteTitle(String noteId, String newTitle) async {
    try{
      //  get title
      //  return Unnamed Note if it wasn't given a name
      String finalTitle = newTitle.trim();
      if(finalTitle.isEmpty){
        finalTitle = 'Unnamed Note';
      }

      //  update otherwise 
      await getNotesCollection().doc(noteId).update({
        'title':finalTitle,
        'dateModified':Timestamp.now(),
      });

    }catch(e){
      print('Error updating title: $e');
    }
  }

  //  listener for EVERY SINGLE CORNELL ROW
  //  every topic + definition
  Stream<List<ContentItem>> streamContentItems(String noteId){
    return getContentsCollection(noteId).orderBy('createdAt',descending: false)
      .snapshots()
      .map((snapshot){
        return snapshot.docs.map((doc){
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            return ContentItem.fromMap(data,doc.id);
        }).toList();
      }
    );
  }

  //  CRUD METHOD: CREATE content
  Future<String> addContentRow({
    required String noteId,
    String topic='',
    String information='',
  }) async {
    try{

      //  create ContentItem object for use
      ContentItem newItem = ContentItem(
        id: '',
        noteId: noteId,
        topic: topic,
        information: information,
        position: 0,
        score: 0,
      );

      //  convert into Map via toMap() and add createdAt
      Map<String, dynamic> data=newItem.toMap();
      data['createdAt']=FieldValue.serverTimestamp();

      //  save to firebasee
      DocumentReference docRef=await getContentsCollection(noteId).add(data);
      await updateLastModified(noteId);

      //  return it
      return docRef.id;

    }catch(e){
      print('Error adding row: $e');
      return '';
    }
  }

  //  CRUD METHOD: UPDATE content 
  Future<void> updateContentRow({
    required String noteId,
    required String contentId,
    required String topic,
    required String information,
  }) async {
    try{

      //  get document and update with parameters
      await getContentsCollection(noteId).doc(contentId).update({
        'topic': topic,
        'information': information,
      });

      await updateLastModified(noteId);
    }catch(e){
      print('Error updating row: $e');
    }
  }

  //  CRUD METHOD: delete row
  Future<void> deleteContentRow({
    required String noteId,
    required String contentId,
  }) async {
    try{
      await getContentsCollection(noteId).doc(contentId).delete();
      await updateLastModified(noteId);
    }catch(e){
      print('Error deleting row: $e');
    }
  }

}