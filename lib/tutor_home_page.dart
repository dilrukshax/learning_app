// lib/tutor_home_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';

class TutorHomePage extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _logout(BuildContext context) async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final User? tutor = _auth.currentUser;
    if (tutor == null) {
      // If not logged in, navigate to login page
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return Scaffold();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Tutor Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: tutor.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error loading chats'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data!.docs;

          if (chats.isEmpty) {
            return Center(child: Text('No chats available'));
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final participants = List<String>.from(chat['participants']);
              // Remove the tutor's UID to get the student's UID
              participants.remove(tutor.uid);
              final studentId = participants.isNotEmpty ? participants[0] : null;

              if (studentId == null) {
                return ListTile(
                  title: Text('Unknown Student'),
                  subtitle: Text('No student information available'),
                );
              }

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(studentId)
                    .get(),
                builder: (context, studentSnapshot) {
                  if (studentSnapshot.hasError) {
                    return ListTile(
                      title: Text('Error loading student'),
                      subtitle: Text(studentId),
                    );
                  }

                  if (studentSnapshot.connectionState == ConnectionState.waiting) {
                    return ListTile(
                      title: Text('Loading student...'),
                    );
                  }

                  final studentData =
                      studentSnapshot.data?.data() as Map<String, dynamic>?;
                  final studentName =
                      studentData != null ? studentData['name'] ?? 'Student' : 'Student';

                  return ListTile(
                    leading: CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text(studentName),
                    onTap: () {
                      // Navigate to ChatScreen with student details
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            tutorId: tutor.uid,
                            tutorName: 'Tutor',
                            studentId: studentId,
                            studentName: studentName,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
