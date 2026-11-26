import 'package:flutter/material.dart';
import '../databases/database.dart';
import '../services/note_editor.dart';

class NoteEditorPage extends StatefulWidget{
  //  requird to pass note
  //  kasi note editor duh
  final String noteId;
  const NoteEditorPage({super.key, required this.noteId});

  @override
  State<NoteEditorPage> createState()=> _NoteEditorPage();
}

//  note: i used StreamBuilder to always show
//    an updated version of title and content list

class _NoteEditorPage extends State<NoteEditorPage>{
  //  controller for title
  final NoteEditor editor = NoteEditor();
  final TextEditingController titleController=TextEditingController();
  
  //  controllers for note input
  final TextEditingController topicController=TextEditingController();
  final TextEditingController infoController=TextEditingController();

  //  focus nodes: control which textfield has the cursor thing
  final FocusNode topicFocus = FocusNode();
  final FocusNode infoFocus = FocusNode();

  //  flag for creating initial row upon note creation
  bool hasCreatedInitialRow = false;

  //  store id of row being typed in
  String? activeRowId;

  //  dispose
  @override
  void dispose(){
    titleController.dispose();
    topicController.dispose();
    infoController.dispose();
    topicFocus.dispose();
    infoFocus.dispose();
    super.dispose();
  }

  //  method for switching to a new topic-info  row
  Future<void> selectRowForEdit(ContentItem item)async{

    //  SAVE this row if another row was already open
    // (it wasn't the one being selected)
    if(activeRowId!=null&&activeRowId!=item.id){
      await editor.updateContentRow(
        noteId: widget.noteId, 
        contentId: activeRowId!, 
        topic: topicController.text, 
        information: infoController.text,
      );
    }

    //  by selecting a row,
    //  update controller values 
    //  + mark this row as the active one
    setState(() {
      activeRowId = item.id;
      topicController.text=item.topic;
      infoController.text=item.information;
    });

    //  wait 1 frame 
    //  then successfully switch to topic
    WidgetsBinding.instance.addPostFrameCallback((duration){
      topicFocus.requestFocus();
    });

  }

  //  method for saving currently active row
  Future<void> saveActiveRow()async{
    //  stop if no active roww to begin with
    if(activeRowId==null)return;

    await editor.updateContentRow(
      noteId: widget.noteId, 
      contentId: activeRowId!, 
      topic: topicController.text, 
      information: infoController.text
    );

    setState(() {
      activeRowId=null;
      topicController.clear();
      infoController.clear();
    });
  }

  //  BUILD METHOD
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text('Note Editor')
      ),
      body: Center(
        child: Column(
          children: [

            //  TITLE + LISTENER 
            StreamBuilder<Note>(
                //  streamNote from my note_editor.dart
                //  
              stream: editor.streamNote(widget.noteId),
              //  builder boilerplate
              builder: (context,snapshot){
                if(!snapshot.hasData){
                  return Text('Loading Title...');
                }
                return Text('Title: ${snapshot.data!.title}');
              },
            ),

            //  TITLE INPUT
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                hintText: 'Edit Title'
              ),
            ),

            Divider(
              height: 32,
            ),

            //  SAVE TITLE
            ElevatedButton(
              onPressed: () async {
                //  updateNoteTitle from my note_editor.dart
                await editor.updateNoteTitle(
                  //  get noteId passed in stateful widget 
                  widget.noteId, 
                  //  then update title
                  titleController.text
                );
                titleController.text='';
              }, 
              
              child: Text('Save Title')
            ),
            Divider(
              height: 32,
            ),

            Divider(
              height: 32,
            ),

            /*
            ElevatedButton(
              onPressed: () async{
                //  addContentRow from my note_editor.dart
                await editor.addContentRow(
                  noteId: widget.noteId,
                  topic: topicController.text,
                  information: infoController.text,
                  //  position is ommitted, bc it's optional param
                  //  autoplace at the end, which is wtvr count is plus one
                );
                topicController.text='';
                infoController.text='';
              }, 
              child: Text('Add Row'),
            ),*/
  
            Divider(
              height: 32,
            ),

            //  LIVE LIST of ALL ROWS (TOPIC + INFO)
            Expanded(
              child: StreamBuilder(
                //  streamContentItems from my dart
                //  gets all the Content
                stream: editor.streamContentItems(widget.noteId), 
                builder: ((context, snapshot) {
                  //  check for errors
                  if(snapshot.hasError){
                    return Text('Something went wrong: ${snapshot.error}');
                  }

                  //  
                  if(!snapshot.hasData){
                    return Text('Loading rows...');
                  }
                  
                  //  start with an initial row
                  List<ContentItem>rows=snapshot.data!;
                  if(rows.isEmpty){
                    if(!hasCreatedInitialRow){
                      hasCreatedInitialRow=true;

                      //  create initial row + set its id as the active id
                      editor.addContentRow(
                        noteId: widget.noteId
                      ).then((newRowId){
                        hasCreatedInitialRow=false;

                        //  set this as the currently active row
                        setState(() {
                          activeRowId=newRowId;
                          topicController.clear();
                          infoController.clear();
                        });
                        
                        //  same thing as while ago: wait + change focus
                        //  
                        WidgetsBinding.instance.addPostFrameCallback((_){
                          topicFocus.requestFocus();
                        });
                      });
                    }
                    return Text('Creating first row...');
                  }

                  //  creates scrollable list for rows
                  return ListView.builder(
                    itemCount: rows.length,
                    //  itemBuilder is like a forloop
                    // 
                    //  but instead of iterating thru smth
                    //  you create a bunch of smth
                    itemBuilder: (context,index){
                      //  get current item being drawn
                      ContentItem item=rows[index];

                      //  this is true if this specific row is active (currently being edited/used)
                      bool isActive=(item.id==activeRowId);

                      return Column(
                        //crossAxisAlignment: .start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          //  placing as one text for now but just
                          //  use them when separating the topics from infos

                          if(isActive)
                            //  IF being used, then show TextFields
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: topicController,
                                    focusNode: topicFocus,
                                    decoration: InputDecoration(
                                      hintText: 'Topic',
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: infoController,
                                    focusNode: infoFocus,
                                    decoration: InputDecoration(
                                      hintText: 'Information',
                                    ),
                                  ),
                                ),
                              ],
                            )
                          else
                            //  OHTERWISE, show text that can detect gestures
                            GestureDetector(
                              onTap: ()=>selectRowForEdit(item),
                              child: Text('[${item.position}] ${item.topic} | ${item.information}'),
                            ),

                          Row(
                            children: [

                              //  BUTTON FOR INSERTING ABOVE THE NOTE
                              ElevatedButton(
                                onPressed: () async {
                                  if(activeRowId!=null){
                                    await saveActiveRow();
                                  }
                                  
                                  //  create id of new roww
                                  //  (same as this one being pressed cz it's above)
                                  //  and everything below it gets updated by +1
                                  String newId=await editor.addContentRow(
                                    noteId: widget.noteId,
                                    topic: '',
                                    information: '',
                                    position: item.position
                                  );

                                  setState(() {
                                    activeRowId=newId;
                                    topicController.clear();
                                    infoController.clear();
                                  });

                                  //  yeah same thing: change focus after waiting a bit
                                  WidgetsBinding.instance.addPostFrameCallback((_){
                                    topicFocus.requestFocus();
                                  });
                                }, 
                                child: Text('Insert Above')
                              ),

                              //  BUTTON FOR EDITING
                              //  if this row is active, save it.
                              //  otherwise, open for editing and showw 'Edit'
                              ElevatedButton(
                                onPressed: () async {
                                  if(isActive){
                                    await saveActiveRow();
                                  }else{
                                    await selectRowForEdit(item);
                                  }
                                }, 
                                child: Text(isActive?'Save':'Edit')
                              ),

                              //  BUTTON FOR DELETING
                              ElevatedButton(
                                onPressed: () async {
                                  //  if deleting active row then clear activeid first
                                  //  then gaur
                                  if(activeRowId==item.id){
                                    setState(() {
                                      activeRowId=null;
                                      topicController.clear();
                                      infoController.clear();
                                    });
                                  }
                                  //  then gaur (1)
                                  await editor.deleteContentRow(
                                    noteId: widget.noteId, 
                                    contentId: item.id,
                                  );
                                }, 
                                child: Text('Delete')
                              ),
                            ],
                          ),
                        ],

                      );
                    },
                  );







                }),
              ),
            ),

          ],
        ),
      )
    );
  }
}