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

class _NoteEditorPage() extends State<NoteEditorPage>{
  final NoteEditor editor = NoteEditor();

  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(

      ),
      body: Center(

      ),
    );
  }
}