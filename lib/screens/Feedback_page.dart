import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_service.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

enum FeedbackRating { good, bad }

class _FeedbackScreenState extends State<FeedbackScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isSpeaking = false;
  bool _isRecording = false;
  String? _audioFilePath;

  FeedbackRating _rating = FeedbackRating.good;
  Timer? _ratingDebounceTimer;

  @override
  void initState() {
    super.initState();
    _initTts();
    _initRecorder();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        _speak(
          "You can rate your experience as Good or Bad. Swipe right for Good, swipe left for Bad. Double tap to start or stop recording voice feedback. Pinch with two fingers to submit your feedback and return home.",
        );
      }
    });
  }

  Future<void> _initTts() async {
    final prefs = await SharedPreferences.getInstance();
    final savedVoice = prefs.getString('voice') ?? 'female';
    final savedPitch = prefs.getDouble('pitch') ?? 1.0;
    final savedRate = prefs.getDouble('rate') ?? 0.5;

    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(savedPitch);
    await _flutterTts.setSpeechRate(savedRate);
    await _flutterTts.setVolume(1.0);

    if (savedVoice == 'male') {
      await _flutterTts.setVoice({"name": "Daniel", "locale": "en-GB"});
      debugPrint("FeedbackScreen restored male voice");
    } else {
      await _flutterTts.setVoice({"name": "Samantha", "locale": "en-US"});
      debugPrint("FeedbackScreen restored female voice");
    }

    _flutterTts.setCompletionHandler(() => _isSpeaking = false);
    _flutterTts.setErrorHandler((msg) => _isSpeaking = false);
  }

  Future<void> _initRecorder() async {
    await _recorder.openRecorder();

    final micPermission = await Permission.microphone.request();
    if (!micPermission.isGranted) {
      _speak(
        "Microphone permission denied. Voice feedback will not be available.",
      );
    }
  }

  Future<void> _speak(String text) async {
    if (_isSpeaking) await _flutterTts.stop();
    _isSpeaking = true;
    await _flutterTts.awaitSpeakCompletion(true);
    await _flutterTts.speak(text);
  }

  void _onSwipeRight() {
    if (_rating != FeedbackRating.good) {
      setState(() => _rating = FeedbackRating.good);
      _speak("You rated good.");
      _startRatingDebounce();
    }
  }

  void _onSwipeLeft() {
    if (_rating != FeedbackRating.bad) {
      setState(() => _rating = FeedbackRating.bad);
      _speak("You rated bad.");
      _startRatingDebounce();
    }
  }

  void _startRatingDebounce() {
    _ratingDebounceTimer?.cancel();
    _ratingDebounceTimer = Timer(const Duration(seconds: 5), () {
      _speak(
        "Would you like to leave a voice feedback? Double tap to start or stop recording, or pinch with two fingers to submit your feedback and return home.",
      );
    });
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _recorder.stopRecorder();
      setState(() => _isRecording = false);
      await _speak("Recording stopped.");
    } else {
      final path = '/${DateTime.now().millisecondsSinceEpoch}.aac';
      await _recorder.startRecorder(toFile: path);
      setState(() {
        _isRecording = true;
        _audioFilePath = path;
      });
      await _speak("Recording started.");
    }
  }

  bool _feedbackSubmitted = false;

  Future<void> _submitFeedback() async {
    if (_feedbackSubmitted) return; // prevent duplicate

    _feedbackSubmitted = true; // mark as submitted

    await DatabaseService.insertFeedbackWithAudio(
      text: "",
      rating: _rating == FeedbackRating.good ? "Good" : "Bad",
      audioPath: _audioFilePath,
    );
    await _speak("Thanks for your feedback.");
    if (context.mounted) {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _recorder.closeRecorder();
    _ratingDebounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! > 0) {
            _onSwipeRight();
          } else if (details.primaryVelocity! < 0) {
            _onSwipeLeft();
          }
        }
      },
      onDoubleTap: _toggleRecording,
      onScaleUpdate: (details) {
        if (details.pointerCount == 2 && details.scale < 0.8) {
          _submitFeedback();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text("Feedback"),
          backgroundColor: Colors.black,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                "Rate your experience:",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildRatingOption(FeedbackRating.good, "Good"),
                  const SizedBox(width: 40),
                  _buildRatingOption(FeedbackRating.bad, "Bad"),
                ],
              ),
              const SizedBox(height: 40),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 1.0, end: _isRecording ? 1.3 : 1.0),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                builder:
                    (_, scale, __) => Transform.scale(
                      scale: scale,
                      child: Icon(
                        Icons.mic,
                        size: 64,
                        color: _isRecording ? Colors.redAccent : Colors.white,
                      ),
                    ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Double tap the microphone to start or stop recording.",
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 10),
              const Text(
                "Pinch with two fingers to submit and return home.",
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingOption(FeedbackRating rating, String label) {
    final isSelected = _rating == rating;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(
        color: isSelected ? Colors.cyan : Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.black : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 18,
        ),
      ),
    );
  }
}
