import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TTSTestPage extends StatefulWidget {
  const TTSTestPage({super.key});

  @override
  _TTSTestPageState createState() => _TTSTestPageState();
}

class _TTSTestPageState extends State<TTSTestPage> {
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _speak() async {
    await _flutterTts.speak("Hello, this is a test for text to speech!");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TTS Test')),
      body: Center(
        child: ElevatedButton(
          onPressed: _speak,
          child: const Text("Press to Speak"),
        ),
      ),
    );
  }
}
