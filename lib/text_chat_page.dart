// lib/text_chat_page.dart

import 'package:flutter/material.dart';

class TextChatPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Text Chat'),
      ),
      body: Center(
        child: Text(
          'Text chat functionality goes here.',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
