import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentHomePage extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _logout(BuildContext context) async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<String> _getUserEmail() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      return userDoc['email'] ?? 'Student';
    }
    return 'Student';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Student Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: FutureBuilder<String>(
        future: _getUserEmail(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          String email = snapshot.data ?? 'Student';

          return Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $email!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                Text(
                  'Available Features:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 10),
                ListTile(
                  leading: Icon(Icons.chat),
                  title: Text('Join a Voice Chat'),
                  onTap: () {
                    // Navigate to voice chat feature
                  },
                ),
                ListTile(
                  leading: Icon(Icons.schedule),
                  title: Text('View Schedule'),
                  onTap: () {
                    // Navigate to schedule viewing
                    Navigator.pushNamed(context, '/tutorList');
                  },
                ),
                // Add more features as needed
              ],
            ),
          );
        },
      ),
    );
  }
}
