// lib/add_edit_note_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:intl/intl.dart'; // For formatting timestamps

class AddEditNotePage extends StatefulWidget {
  final String? noteId; // If null, it's a new note
  final String? existingContent;

  AddEditNotePage({this.noteId, this.existingContent});

  @override
  _AddEditNotePageState createState() => _AddEditNotePageState();
}

class _AddEditNotePageState extends State<AddEditNotePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _noteController = TextEditingController();
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _transcribedText = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    if (widget.existingContent != null) {
      _noteController.text = widget.existingContent!;
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (val) {
        if (val == 'done') {
          setState(() => _isListening = false);
        }
      },
      onError: (val) {
        setState(() => _isListening = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${val.errorMsg}')),
        );
      },
    );
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (val) {
          setState(() {
            _transcribedText = val.recognizedWords;
            _noteController.text = _transcribedText;
          });
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Speech recognition unavailable')),
      );
    }
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> _saveNote() async {
    final user = _auth.currentUser;
    if (user == null) {
      // User not authenticated
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You must be logged in to save notes.')),
      );
      return;
    }

    final content = _noteController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Note cannot be empty.')),
      );
      return;
    }

    try {
      if (widget.noteId == null) {
        // Create a new note
        await _firestore.collection('notes').add({
          'userId': user.uid,
          'content': content,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        // Update existing note
        await _firestore.collection('notes').doc(widget.noteId).update({
          'content': content,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      Navigator.pop(context); // Go back to notes list
    } catch (e) {
      print('Error saving note: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save note.')),
      );
    }
  }

  Future<void> _deleteNote() async {
    if (widget.noteId == null) return;

    try {
      await _firestore.collection('notes').doc(widget.noteId).delete();
      Navigator.pop(context); // Go back to notes list
    } catch (e) {
      print('Error deleting note: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete note.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.noteId != null;
    final formattedTime = isEditing
        ? _noteController.text.isNotEmpty
            ? DateFormat('yyyy-MM-dd – kk:mm').format(DateTime.now())
            : ''
        : '';

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Note' : 'Add Note'),
        actions: isEditing
            ? [
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    // Confirm deletion
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Delete Note'),
                        content: Text('Are you sure you want to delete this note?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context), // Cancel
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context); // Close dialog
                              _deleteNote();
                            },
                            child: Text('Delete', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ]
            : [],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _noteController,
                maxLines: null,
                expands: true,
                decoration: InputDecoration(
                  hintText: 'Start speaking to take a note...',
                  border: OutlineInputBorder(),
                ),
                readOnly: false, // Allow editing
              ),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic_off : Icons.mic,
                    color: _isListening ? Colors.red : Colors.indigo,
                  ),
                  onPressed: () {
                    if (_isListening) {
                      _stopListening();
                    } else {
                      _startListening();
                    }
                  },
                ),
                SizedBox(width: 10),
                Spacer(),
                ElevatedButton(
                  onPressed: _saveNote,
                  child: Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
