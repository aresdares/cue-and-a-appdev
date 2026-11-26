//  imports firestore
import 'package:cloud_firestore/cloud_firestore.dart';
//  imports fire_auth to get user id -> their notes
import 'package:firebase_auth/firebase_auth.dart';

import '../databases/database.dart';

//  users / { userId } / notebooks
//  users / { userId } / notes / { noteId } / contents / { contentsId }

//  for future reference
//    CollectionReference - an address that points to a collection in firestore
//      - can use .get() to take from the collection that the address points to
//      - can use .add() to add to the collection

class NoteEditor {
  //  create reference to firestore database
  final FirebaseFirestore _db = FirebaseFirestore.instance;


  //  method for getting get current user
  String getCurrentUserId() {
    //  get id of user, taken directly from firebase auth
    return FirebaseAuth.instance.currentUser!.uid;
  }

  //  get user's notes
  CollectionReference getNotesCollection(){
    String uid=getCurrentUserId();
    //  from firestore connection, 
    //  then open up 'users' via collection() 
    //  and fetch specifcially the user we want
    //  then check HIS 'notes' via collection()  
    return FirebaseFirestore.instance.collection('users').doc(uid).collection('notes');
  }

  //  get contents of a notes
  CollectionReference getContentsCollection(String noteId){
    //  pass note id and get contents
    return getNotesCollection().doc(noteId).collection('contents');
  }
  
  //  updates  the last modified date
  Future <void> updateLastModified(String noteId) async{
    //  pass note id and update in there the dateModified field
    await getNotesCollection().doc(noteId).update({
      'dateModified': Timestamp.now(),
    });
  }

  //  listen to live changes being done on a single note
  //  USE THIS FOR THE NOTION-STYLE TITLE CHANGE THING
  Stream<Note> streamNote(String noteId){
    //  snapshots() keeps an open connection to the note
    //  for every change, push DocumentSnapshot
    return getNotesCollection().doc(noteId).snapshots()
    //  for every docsnap pushed, catch in map to do stuff
    .map(
      //  get each doc that firestore gives
      (doc){
        //  1. get the data from the doc
        //  2. treat as Map object but return null if the doc doesn't exist
        Map<String,dynamic> data=doc.data() as Map<String, dynamic>? ??{};
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
    //  snapshsot on getContentsCollection itself instead of .doc
    return getContentsCollection(noteId).orderBy('position',descending: false)
      .snapshots()
      //  go thru EACH
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
    int? position
  }) async {
    try{

      QuerySnapshot snapshot=await getContentsCollection(noteId).get();
      
      List<ContentItem>contentList=snapshot.docs.map((doc){
        Map<String,dynamic> docData=doc.data() as Map<String,dynamic>;
        return ContentItem.fromMap(docData,doc.id);
      }).toList();

      //  create ContentItem object for use
      ContentItem newItem = ContentItem(
        id: '',
        noteId: noteId,
        topic: topic,
        information: information,
        score: 0,
      );

      for(var content in contentList) {
      if (content.position >= newItem.position)
        {
          await getContentsCollection(noteId).
          doc(content.id).
          update({
            'position': content.position+1,
          });
        }
      }

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
      
      DocumentSnapshot targetDoc=await getContentsCollection(noteId)
      .doc(contentId).get();
      Map<String,dynamic>targetData=targetDoc.data()as Map<String,dynamic>? ?? {};
      int deletedPos=targetData['position']??0;

      await getContentsCollection(noteId).doc(contentId).delete();

      QuerySnapshot snapshot=await getContentsCollection(noteId).get();

      //  
      for(var doc in snapshot.docs){
        Map<String,dynamic>docData=doc.data() as Map<String,dynamic>;

        int currentPos=docData['position']??0;
        
        if (currentPos > deletedPos){
          await getContentsCollection(noteId).doc(doc.id).update({
            'position': currentPos-1,
          });
        }
      }

      await updateLastModified(noteId);
    }catch(e){
      print('Error deleting row: $e');
    }
  }

}