import 'package:flutter/material.dart';

import '../pages/note_editor_page.dart';
import '../pages/flashcard_page.dart';
import '../services/ui_builder.dart';
import '../main.dart';

class TestHomepage extends StatefulWidget {
  const new({super.key, required this.userSettings});

  final UserSettings userSettings;

  @override
  State<TestHomepage> createState() => _TestHomepageState();
}

class _TestHomepageState extends State<TestHomepage> {

  final uidController = TextEditingController();
  final noteIdController = TextEditingController();
  String noteId = "pVAR4EdsMejEHzWoqihN";

  @override
  Widget build(BuildContext context) {

    uidController.text = widget.userSettings.uid!;
    noteIdController.text = noteId;

    return Scaffold(
      appBar: UiBuilder.appBarBuilder(this, "Home", disableBack: true),
      drawer: UiBuilder.drawerBuilder(this),
      body: Center(
        child: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              spacing: 30,
              children: [
                Text("Test Directory"),
                TextField(
                  controller: uidController,
                  onChanged: (value) => {
                    widget.userSettings.uid = value
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'UID',
                  ),
                ),
                TextField(     
                  controller: noteIdController,
                  onChanged: (value) => {
                    noteId = value
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'NoteID',
                  ),
                ),
                ElevatedButton(
                  onPressed: () => {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) => NoteEditorPage(userSettings: widget.userSettings, noteId: noteId),
                      ),
                    )
                  }, 
                  child: Text("Note Editor"),
                ),ElevatedButton(
                  onPressed: () => {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) => FlashcardPage(userSettings: widget.userSettings, noteId: noteId, flashcard: true),
                      ),
                    )
                  }, 
                  child: Text("Flashcards"),
                )
              ],
            ),
          )
        )
      )
    );
  }

  @override
  void dispose(){
    uidController.dispose();
    noteIdController.dispose();
    dispose();
  }

}