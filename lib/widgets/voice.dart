import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechButton extends StatefulWidget {
  final Function(int) onNavigateCommand;

  const SpeechButton({super.key, required this.onNavigateCommand});

  @override
  State<SpeechButton> createState() => _SpeechButtonState();
}

class _SpeechButtonState extends State<SpeechButton> {
  SpeechToText _speechToText = SpeechToText();
  FlutterTts _flutterTts = FlutterTts();
  bool _speechEnabled = false;
  bool _isListning = false;
  String _command = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void _startListening() async {
    await _speechToText.listen(onResult: (result) {
      setState(() {
        _command = result.recognizedWords;
        _navigateBasedOnCommand(_command.toLowerCase());
      });
    });
    setState(() {
      _speechEnabled = true;
      _isListning = true;
    });

    _timer = Timer(Duration(seconds: 10), _stopListening);
  }

  void _stopListening() async {
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
    }
    await _speechToText.stop();
    setState(() {
      _speechEnabled = false;
      _isListning = false;
    });
  }

  void _navigateBasedOnCommand(String command) async {
    if (command.contains('math')) {
      await widget.onNavigateCommand(0); // Update the index
      _speak("Navigating to Maths page.");
    } else if (command.contains('science')) {
      await widget.onNavigateCommand(1); // Update the index
      _speak("Navigating to Science page.");
    } else if (command.contains('currency')) {
      await widget.onNavigateCommand(2); // Update the index
      _speak("Navigating to Currency page.");
    } else if (command.contains('save')) {
      await widget.onNavigateCommand(3); // Update the index
      _speak("Navigating to Save page.");
    }
  }

  void _speak(String text) async {
    if (text.isNotEmpty) {
      // Stop any previous speech
      await _flutterTts.stop();

      // Optionally set other properties before speaking
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5); // Speed control
      await _flutterTts.setVolume(1.0); // Volume control
      await _flutterTts.setPitch(1.0); // Pitch control

      // Speak the text
      int result = await _flutterTts.speak(text);

      if (result == 1) {
        print("Speech started");
      } else {
        print("Speech failed");
      }
    } else {
      print("No text to speak");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: FloatingActionButton(
                    elevation: 0,
                    onPressed: _startListening,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Icon(
                      _speechToText.isListening ? Icons.mic : Icons.mic_none,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (_isListning)
                  Padding(
                    padding: const EdgeInsets.all(25.0),
                    child: FloatingActionButton(
                      elevation: 0,
                      onPressed: _stopListening,
                      backgroundColor: Colors.red,
                      child: Icon(
                        Icons.stop,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
