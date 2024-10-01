// lib/notes_list_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_edit_note_page.dart';
import 'package:intl/intl.dart'; // For formatting timestamps

class NotesListPage extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Logout function
  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login'); // Navigate to login page
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      // Redirect to login if not authenticated
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return Scaffold();
    }
    final userId = currentUser.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('My Notes'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              _logout(context); // Call logout function
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('notes')
            .where('userId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error fetching notes.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final notes = snapshot.data!.docs;

          if (notes.isEmpty) {
            return Center(child: Text('No notes available. Click the + button to add a note.'));
          }

          return ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              final content = note['content'] ?? '';
              final timestamp = note['timestamp'] as Timestamp?;
              final formattedTime = timestamp != null
                  ? DateFormat('yyyy-MM-dd – kk:mm').format(timestamp.toDate())
                  : 'No Date';

              return ListTile(
                title: Text(
                  content.length > 50 ? '${content.substring(0, 50)}...' : content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(formattedTime),
                onTap: () {
                  // Navigate to Edit Note Page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddEditNotePage(
                        noteId: note.id,
                        existingContent: content,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to Add Note Page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddEditNotePage(),
            ),
          );
        },
        child: Icon(Icons.add),
        tooltip: 'Add Note',
      ),
    );
  }
}
