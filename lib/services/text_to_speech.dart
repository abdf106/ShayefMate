import 'package:flutter_tts/flutter_tts.dart';

class TextToSpeechService {
  final FlutterTts _flutterTts = FlutterTts();

  TextToSpeechService() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US"); // Set language
    await _flutterTts.setSpeechRate(0.5); // Adjust speech rate
    await _flutterTts.setPitch(1.0); // Adjust pitch
  }

  Future<void> speak(String text) async {
    if (text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }
}
