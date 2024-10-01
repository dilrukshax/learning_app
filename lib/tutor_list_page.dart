// lib/tutor_list_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';

class TutorListPage extends StatelessWidget {
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
    final studentId = currentUser.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('Available Tutors'),
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
            .collection('users')
            .where('role', isEqualTo: 'Tutor')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error fetching tutors.'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final tutors = snapshot.data!.docs;

          if (tutors.isEmpty) {
            return Center(child: Text('No tutors available.'));
          }

          return ListView.builder(
            itemCount: tutors.length,
            itemBuilder: (context, index) {
              final tutor = tutors[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Icon(Icons.person),
                ),
                title: Text(tutor['name'] ?? 'Tutor'),
                subtitle: Text(tutor['email'] ?? ''),
                onTap: () {
                  final tutorId = tutor.id;
                  final tutorName = tutor['name'] ?? 'Tutor';

                  // Navigate to ChatScreen with tutor details
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        tutorId: tutorId,
                        tutorName: tutorName,
                        studentId: studentId,
                        studentName: 'Student',
                      ),
                    ),
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
