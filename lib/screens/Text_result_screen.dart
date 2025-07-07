import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'feedback_page.dart';
import 'home_page.dart';

class TextResultScreen extends StatefulWidget {
  final String recognizedText;

  const TextResultScreen({super.key, required this.recognizedText});

  @override
  State<TextResultScreen> createState() => _TextResultScreenState();
}

class _TextResultScreenState extends State<TextResultScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  bool _hasPromptedFeedback = false;

  @override
  void initState() {
    super.initState();
    _speakRecognizedText();
  }

  Future<void> _speakRecognizedText() async {
    final prefs = await SharedPreferences.getInstance();
    final savedVoice = prefs.getString('voice') ?? 'female';
    final savedPitch = prefs.getDouble('pitch') ?? 1.0;
    final savedRate = prefs.getDouble('rate') ?? 0.5;

    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(savedRate);
    await _flutterTts.setPitch(savedPitch);
    await _flutterTts.setVolume(1.0);

    if (savedVoice == 'male') {
      await _flutterTts.setVoice({"name": "Daniel", "locale": "en-GB"});
      debugPrint("TextResultScreen restored male voice");
    } else {
      await _flutterTts.setVoice({"name": "Samantha", "locale": "en-US"});
      debugPrint("TextResultScreen restored female voice");
    }

    await _flutterTts.awaitSpeakCompletion(true);

    if (widget.recognizedText.trim().isNotEmpty) {
      await _flutterTts.speak(widget.recognizedText);
    } else {
      await _flutterTts.speak("No readable text detected.");
    }

    // Delay before feedback prompt
    await Future.delayed(const Duration(seconds: 1));
    await _promptFeedback();
  }

  Future<void> _promptFeedback() async {
    if (_hasPromptedFeedback) return;
    _hasPromptedFeedback = true;

    await _flutterTts.awaitSpeakCompletion(true);
    await _flutterTts.speak(
      "Now, would you like to provide feedback about this scan? Double tap anywhere to proceed, or pinch with two fingers to cancel.",
    );
  }

  void _goToFeedback() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const FeedbackScreen()),
    );
  }

  void _cancelAndGoHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // disable back gesture
      child: GestureDetector(
        onDoubleTap: _goToFeedback,
        onScaleUpdate: (details) {
          if (details.pointerCount == 2 && details.scale < 0.8) {
            _cancelAndGoHome();
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Scanned Text'),
            backgroundColor: Colors.black,
            automaticallyImplyLeading: false, // hides back icon
          ),
          backgroundColor: Colors.black,
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                child: Text(
                  widget.recognizedText.isNotEmpty
                      ? widget.recognizedText
                      : 'No readable text detected.',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
