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

class _NoteEditorPage() extends State<NoteEditorPage>{
  final NoteEditor editor = NoteEditor();

  final TextEditingController titleController=TextEditingController();
  final TextEditingController topicController=TextEditingController();
  final TextEditingController infoController=TextEditingController();

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

            //  INPUT TOPIC
            TextField(
              controller: topicController,
              decoration: InputDecoration(
                hintText: 'Topic'
              ),
            ),

            //  INPUT DEFINITION
            TextField(
              controller: infoController,
              decoration: InputDecoration(
                hintText: 'Information'
              ),
            ),
  
            Divider(
              height: 32,
            ),

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
            ),
  
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
          
                  List<ContentItem> rows=snapshot.data!;
                  if(rows.isEmpty){
                    return Text('No rows yet.');
                  }

                  //  creates scrollable list for rows
                  return ListView.builder(
                    itemCount: rows.length,
                    itemBuilder: (context,index){
                      ContentItem item=rows[index];

                      return Column(
                        //crossAxisAlignment: .start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          //  placing as one text for now but just
                          //  use them when separating the topics from infos
                          Text('[${item.position}] ${item.topic} | ${item.information}'),
                          Row(
                            children: [

                              //  BUTTON FOR INSERTING ABOVE THE NOTE
                              ElevatedButton(
                                onPressed: () async {
                                  await editor.addContentRow(
                                    noteId: widget.noteId,
                                    topic: 'New topic',
                                    information: 'New info',
                                    position: item.position
                                  );
                                }, 
                                child: Text('Insert Above')
                              ),

                              //  BUTTON FOR EDITING
                              ElevatedButton(
                                onPressed: () async {
                                  await editor.updateContentRow(
                                    noteId: widget.noteId,
                                    contentId: item.id,
                                    topic: '${topicController.text}',
                                    information: '${infoController.text}'
                                  );
                                }, 
                                child: Text('Edit')
                              ),

                              //  BUTTON FOR DELETING
                              ElevatedButton(
                                onPressed: () async {
                                  await editor.deleteContentRow(
                                    noteId: widget.noteId,
                                    contentId: item.id
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