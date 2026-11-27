import 'package:appdev_project/services/authentication.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';
import '../databases/database.dart';
import '../services/note_editor.dart';



class UiBuilder {

  static AppBar appBarBuilder(caller, String title, {bool accessNote = false, bool disableBack = false}){
    List<Widget> titleWidgets = [Text(title)];
    if(accessNote){
      titleWidgets.add(noteTitleBuilder(caller));
    }

    List<Widget> leadingWidgets = [
      Builder(
        builder: (context) {
          return menuButton(caller,context);
        },
      )
    ];
    if(!disableBack){
      leadingWidgets.add(backButton(caller, caller.context));
    }

    return AppBar(
      title: Column(
        children: titleWidgets
      ),
      centerTitle: true,
      leadingWidth: 100,
      leading: Row(
        children: leadingWidgets,
      ),
      actions: <Widget>[
        pfpButton()
      ]
    );
  }

  static Drawer drawerBuilder(caller){
    return Drawer(
      child: ListView(
        children:[
          DrawerHeader(
            child: Text("Menu"),
          ),
          shuffleToggleButton(caller),
          filterCheckBox(caller),
          scoringMode(caller),
        ]
      )
    );
  }

  // Note Title
  static Widget noteTitleText(text){
    return Text(
      'Title: ${text}',
      style: TextStyle(
        fontSize: 15 // ADJUST FOR FRONTEND
      )
    );
  }

  // Menu Button
  static Widget menuButton(caller, context){
    return IconButton(
      icon: const Icon(Icons.menu_rounded),
      onPressed: () => caller.setState(() {
        Scaffold.of(context).openDrawer();
      })
    );
  }


  // Back button meant for appbar
  static Widget backButton(caller, context){
    return IconButton(
      icon: const Icon(Icons.arrow_back_rounded),
      onPressed: () => caller.setState(() {
        Navigator.pop(context);
      })
    );
  }

  // PFP button meant for appbar
  static Widget pfpButton(){
    return PopupMenuButton(
      onSelected: (value) {
          Authentication auth = Authentication();
          auth.signOut(); //logout();
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry>[
        const PopupMenuItem(
          child: ListTile(
            title: Text('Logout'),
          ),
        ),
      ],
      child: const CircleAvatar(
        radius: 24, // ADJUST FOR FRONTEND
        backgroundImage: NetworkImage('https://upload.wikimedia.org/wikipedia/commons/7/7c/Profile_avatar_placeholder_large.png?utm_source=commons.wikimedia.org&utm_campaign=index&utm_content=thumbnail_unscaled'), // PLACEHOLDER
        backgroundColor: Colors.grey,
      ),
    );
  }


  static Widget shuffleToggleButton(caller){
    return SizedBox(
      width:300, // ADJUST FOR FRONTEND
      child:Row(
        children: [
          Checkbox(
            value: caller.widget.userSettings.shuffle, 
            onChanged: (bool? value) => caller.setState(() {
              value ??= true;
              caller.widget.userSettings.shuffle = value!; 
            })
          ),
          Text("Shuffle flashcard/question order")
        ],
      ),
    );
  }

  
  static Widget filterCheckBox(caller){
    return SizedBox(
      width:300, // ADJUST FOR FRONTEND
      child:Row(
        children: [
          Checkbox(
            value: caller.widget.userSettings.filterWords, 
            onChanged: (bool? value) => caller.setState(() {
              value ??= true;
              caller.widget.userSettings.filterWords = value!; 
            })
          ),
          Text("Only allow key nouns/verbs as blanks")
        ],
      ),
    );
  }

  static Widget scoringMode(caller){
    String text = "Track Progress: ";
    text += caller.widget.userSettings.flashScoring?"ON":"OFF";

    return ElevatedButton(
      onPressed: () => caller.setState(() {
        caller.widget.userSettings.flashScoring = !caller.widget.userSettings.flashScoring;
      }), 
      child: Text(text));
  }







  
  // Logic function. Ignore for frontend
  static Widget noteTitleBuilder(caller){
    //  TITLE + LISTENER 
    return StreamBuilder<Note>(
      //  streamNote from my note_editor.dart
      //  
      stream: NoteEditor().streamNote(caller.widget.noteId),
      //  builder boilerplate
      builder: (context,snapshot){
        if(!snapshot.hasData){
          return noteTitleText('Loading Title...');
        }
        return noteTitleText('Title: ${snapshot.data!.title}');
      },
    );
  }
}