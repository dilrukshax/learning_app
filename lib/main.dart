import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:learning_app/bottom_nav.dart';
import 'package:learning_app/text_chat_page.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'tutor_home_page.dart';
import 'student_home_page.dart';
import 'tutor_list_page.dart';
import 'chat_screen.dart';
import 'notes_list_page.dart'; // Import the Notes List Page
import 'add_edit_note_page.dart'; // Import the Add/Edit Note Page
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Firebase initialization
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voice Chat & Notes App',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        textTheme: GoogleFonts.poppinsTextTheme(
          ThemeData.light().textTheme,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.indigo,
            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
            textStyle: TextStyle(fontSize: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: AuthStateListener(),
      routes: {
        '/login': (context) => LoginPage(),
        '/signup': (context) => SignUpPage(),
        '/tutorHome': (context) => TutorHomePage(),
        '/studentHome': (context) => StudentHomePage(),
        '/tutorList': (context) => TutorListPage(),
        '/chatScreen': (context) => ChatScreen(
              tutorId: '',
              tutorName: '',
              studentId: '',
              studentName: '',
            ),
        '/notesList': (context) => NotesListPage(), // Add Notes List Route
        '/addEditNote': (context) => AddEditNotePage(), // Add Add/Edit Note Route
      },
    );
  }
}

class AuthStateListener extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(snapshot.data!.uid)
                .get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                String role = userSnapshot.data!['role'];
                if (role == 'Tutor') {
                  return TutorHomePage();
                } else {
                  return MainNavigation(role: 'Student');
                }
              } else {
                return LoginPage();
              }
            },
          );
        } else {
          return LoginPage();
        }
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  final String role;
  MainNavigation({required this.role});

  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0; // Default to Notes page

  List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    if (widget.role == 'Tutor') {
      _pages = [
        PlaceholderWidget('Notes'), // Placeholder for future notes page
        PlaceholderWidget('Voice Chat'),
        PlaceholderWidget('Object Detection'),
      ];
    } else {
      _pages = [
        NotesListPage(), // Student Notes page
        TutorListPage(), // Student's voice chat list
        PlaceholderWidget('Object Detection'),
      ];
    }
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  final List<BottomNavigationBarItem> _navItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.note),
      label: 'Notes',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.mic),
      label: 'Voice Chat',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.camera),
      home: const BottomNav(),
      label: 'Object Detection',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: _navItems,
        currentIndex: _currentIndex,
        selectedItemColor: Colors.indigo,
        onTap: onTabTapped,
      ),
    );
  }
}

class PlaceholderWidget extends StatelessWidget {
  final String text;
  PlaceholderWidget(this.text);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(text),
      ),
      body: Center(
        child: Text(
          'This feature is under development.',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
