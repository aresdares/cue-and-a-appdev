import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../databases/database.dart';
import '../services/note_editor.dart'; // <-- Change if your file has a different name

class NoteEditorTestScreen extends StatefulWidget {
  const NoteEditorTestScreen({super.key});

  @override
  State<NoteEditorTestScreen> createState() => _NoteEditorTestScreenState();
}

class _NoteEditorTestScreenState extends State<NoteEditorTestScreen> {
  final NoteEditor _editor = NoteEditor();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _infoController = TextEditingController();

  String? _testNoteId;
  String _status = 'Logging in test user and creating a dummy note...';

  @override
  void initState() {
    super.initState();
    _setupTestEnvironment();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _topicController.dispose();
    _infoController.dispose();
    super.dispose();
  }

  // Ensures a user is logged in AND a fresh parent Note document exists in Firestore
  Future<void> _setupTestEnvironment() async {
    try {
      // 1. Log in (or auto-register) a test account so currentUser! is never null
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        try {
          UserCredential cred =
              await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: 'stephen_test@group4.com',
            password: 'password123',
          );
          user = cred.user;
        } catch (_) {
          UserCredential cred =
              await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: 'stephen_test@group4.com',
            password: 'password123',
          );
          user = cred.user;
        }
      }

      // 2. Create 1 fresh dummy Note document so updateLastModified() has a doc to update
      Note dummyNote = Note(
        id: '',
        notebookId: null,
        title: 'Test Cornell Note',
        dateCreated: DateTime.now(),
        dateModified: DateTime.now(),
      );

      DocumentReference noteRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('notes')
          .add(dummyNote.toMap());

      setState(() {
        _testNoteId = noteRef.id;
        _status = 'Ready! Testing Note ID: ${noteRef.id}';
      });
    } catch (e) {
      setState(() {
        _status = 'Setup Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test NoteEditor Backend')),
      body: _testNoteId == null
          ? Center(child: Text(_status, textAlign: TextAlign.center))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status Banner
                  Text(_status, style: const TextStyle(color: Colors.green)),
                  const SizedBox(height: 12),

                  // ---------------------------------------------------
                  // TEST 1: streamNote() + updateNoteTitle()
                  // ---------------------------------------------------
                  StreamBuilder<Note>(
                    stream: _editor.streamNote(_testNoteId!),
                    builder: (context, snapshot) {
                      String currentTitle =
                          snapshot.data?.title ?? 'Loading title...';
                      return Text(
                        'Live Title: $currentTitle',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            hintText: 'New title (leave empty = Unnamed Note)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          await _editor.updateNoteTitle(
                            _testNoteId!,
                            _titleController.text,
                          );
                          _titleController.clear();
                        },
                        child: const Text('Save Title'),
                      ),
                    ],
                  ),
                  const Divider(height: 28),

                  // ---------------------------------------------------
                  // TEST 2: addContentRow() — Append to Bottom (position: null)
                  // ---------------------------------------------------
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _topicController,
                          decoration: const InputDecoration(
                            hintText: 'Topic (Left)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _infoController,
                          decoration: const InputDecoration(
                            hintText: 'Info (Right)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          await _editor.addContentRow(
                            noteId: _testNoteId!,
                            topic: _topicController.text,
                            information: _infoController.text,
                          );
                          _topicController.clear();
                          _infoController.clear();
                        },
                        child: const Text('+ Append'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Live Cornell Rows (Ordered by Position):',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  // ---------------------------------------------------
                  // TEST 3: streamContentItems() + Insert Above + Edit + Delete
                  // ---------------------------------------------------
                  Expanded(
                    child: StreamBuilder<List<ContentItem>>(
                      stream: _editor.streamContentItems(_testNoteId!),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        }
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        List<ContentItem> rows = snapshot.data!;
                        if (rows.isEmpty) {
                          return const Center(
                            child: Text('No rows yet. Add one above!'),
                          );
                        }

                        return ListView.builder(
                          itemCount: rows.length,
                          itemBuilder: (context, index) {
                            ContentItem item = rows[index];
                            return Card(
                              child: ListTile(
                                // Displays the Firestore 'position' field live
                                leading: CircleAvatar(
                                  backgroundColor: Colors.indigo.shade100,
                                  child: Text(
                                    '#${item.position}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                title: Text('Topic: ${item.topic}'),
                                subtitle: Text('Info: ${item.information}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Test inserting in the middle (shifts this row +1)
                                    IconButton(
                                      tooltip: 'Insert row above #${item.position}',
                                      icon: const Icon(
                                        Icons.add_circle_outline,
                                        color: Colors.green,
                                      ),
                                      onPressed: () async {
                                        await _editor.addContentRow(
                                          noteId: _testNoteId!,
                                          topic:
                                              'Inserted @ pos ${item.position}',
                                          information:
                                              'Pushed old #${item.position} down',
                                          position: item.position,
                                        );
                                      },
                                    ),
                                    // Test updateContentRow()
                                    IconButton(
                                      tooltip: 'Edit row',
                                      icon: const Icon(Icons.edit,
                                          color: Colors.blue),
                                      onPressed: () async {
                                        await _editor.updateContentRow(
                                          noteId: _testNoteId!,
                                          contentId: item.id,
                                          topic: '${item.topic} (edited)',
                                          information:
                                              '${item.information} (edited)',
                                        );
                                      },
                                    ),
                                    // Test deleteContentRow() (shifts rows below -1)
                                    IconButton(
                                      tooltip: 'Delete row',
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () async {
                                        await _editor.deleteContentRow(
                                          noteId: _testNoteId!,
                                          contentId: item.id,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}