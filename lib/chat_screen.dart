// lib/chat_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';

class ChatScreen extends StatefulWidget {
  final String tutorId;
  final String tutorName;
  final String studentId;
  final String studentName;

  ChatScreen({
    required this.tutorId,
    required this.tutorName,
    required this.studentId,
    required this.studentName,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  FlutterSoundRecorder? _recorder;
  final AudioPlayer _audioPlayer = AudioPlayer();

  String? _chatId;
  bool _isRecording = false;
  bool _isRecorderInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
    _initializeChat();
  }

  Future<void> _initializeRecorder() async {
    _recorder = FlutterSoundRecorder();

    await _recorder!.openRecorder();
    _isRecorderInitialized = true;

    // Request microphone permission
    var status = await Permission.microphone.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Microphone permission denied')),
      );
      return;
    }

    setState(() {});
  }

  Future<void> _initializeChat() async {
    final tutorId = widget.tutorId;
    final studentId = widget.studentId;

    // Generate a consistent chat ID
    _chatId = studentId.compareTo(tutorId) < 0
        ? '$studentId\_$tutorId'
        : '$tutorId\_$studentId';

    // Create chat document if it doesn't exist
    final chatDoc = _firestore.collection('chats').doc(_chatId);
    final chatSnapshot = await chatDoc.get();

    if (!chatSnapshot.exists) {
      await chatDoc.set({
        'participants': [studentId, tutorId],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    setState(() {});
  }

  Future<void> _startRecording() async {
    try {
      if (!_isRecorderInitialized) return;

      // Prepare file path
      final directory = await getApplicationDocumentsDirectory();
      String filePath = '${directory.path}/${Uuid().v4()}.aac'; // Unique file name

      await _recorder!.startRecorder(
        toFile: filePath,
        codec: Codec.aacADTS,
      );

      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      if (!_isRecorderInitialized) return;

      String? path = await _recorder!.stopRecorder();

      setState(() {
        _isRecording = false;
      });

      if (path != null) {
        File audioFile = File(path);
        await _uploadVoiceMessage(audioFile);
      }
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  Future<void> _uploadVoiceMessage(File file) async {
    try {
      String fileName = Uuid().v4();
      Reference ref = _storage
          .ref()
          .child('voice_messages')
          .child(_chatId!)
          .child('$fileName.aac');

      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;

      String downloadUrl = await snapshot.ref.getDownloadURL();

      // Save message to Firestore
      await _firestore
          .collection('chats')
          .doc(_chatId)
          .collection('messages')
          .add({
        'senderId': FirebaseAuth.instance.currentUser!.uid,
        'voiceUrl': downloadUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error uploading voice message: $e');
    }
  }

  Future<void> _playVoiceMessage(String url) async {
    try {
      await _audioPlayer.play(UrlSource(url));
    } catch (e) {
      print('Error playing voice message: $e');
    }
  }

  @override
  void dispose() {
    _recorder?.closeRecorder();
    _audioPlayer.dispose();
    super.dispose();
  }

  Widget _buildMessageItem(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final isMe = data['senderId'] == FirebaseAuth.instance.currentUser!.uid;
    final voiceUrl = data['voiceUrl'];

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isMe ? Colors.indigo[100] : Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        child: GestureDetector(
          onTap: () {
            _playVoiceMessage(voiceUrl);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.play_arrow),
              SizedBox(width: 5),
              Text('Voice Message'),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isTutor = currentUser != null && currentUser.uid == widget.tutorId;
    final chatPartnerName = isTutor ? widget.studentName : widget.tutorName;

    if (_chatId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(chatPartnerName),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(chatPartnerName),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(_chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading messages.'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessageItem(messages[index]);
                  },
                );
              },
            ),
          ),
          Divider(height: 1),
          Container(
            padding: EdgeInsets.all(10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: IconButton(
                    icon: Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      color: _isRecording ? Colors.red : Colors.indigo,
                    ),
                    onPressed: () {
                      if (_isRecording) {
                        _stopRecording();
                      } else {
                        _startRecording();
                      }
                    },
                  ),
                ),
                // You can add additional UI elements here (e.g., send button, text input)
              ],
            ),
          ),
        ],
      ),
    );
  }
}
