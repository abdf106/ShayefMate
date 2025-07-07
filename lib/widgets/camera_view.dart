import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter/foundation.dart';

import '../services/text_recognition_service.dart';
import '../services/object_detection_service.dart';
import '../screens/text_result_screen.dart';

List<String> _detectedObjects = [];

class CameraView extends StatefulWidget {
  final int mode;
  const CameraView({super.key, required this.mode});

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  final FlutterTts _flutterTts = FlutterTts();

  bool _isSpeaking = false;
  DateTime _lastSpeakTime = DateTime.now().subtract(const Duration(seconds: 5));
  DateTime? _lastLowLightAlertTime;

  bool _isProcessingFrame = false;

  int _textDetectedFrames = 0;
  int _textNotDetectedFrames = 0;
  bool _isTextDetected = false;

  final int debounceThresholdForDetection = 2;
  final int debounceThresholdForNoDetection = 2;

  final TextRecognitionService _textRecognitionService =
      TextRecognitionService();
  final ObjectRecognitionService _objectRecognitionService =
      ObjectRecognitionService();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _setupTts();
  }

  Future<void> _setupTts() async {
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
      debugPrint("CameraView restored male voice");
    } else {
      await _flutterTts.setVoice({"name": "Samantha", "locale": "en-US"});
      debugPrint("CameraView restored female voice");
    }

    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
    });
    _flutterTts.setErrorHandler((msg) {
      _isSpeaking = false;
    });

    await _flutterTts.speak("Camera ready. Double tap to capture.");
  }

  InputImageFormat _getInputImageFormat(int rawFormat) {
    switch (rawFormat) {
      case 35:
        return InputImageFormat.yuv420;
      case 17:
        return InputImageFormat.nv21;
      default:
        return InputImageFormat.yuv420;
    }
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (!mounted) return;
    if (cameras.isNotEmpty) {
      _controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      try {
        await _controller!.initialize();
        if (!mounted) return;
        setState(() => _isCameraInitialized = true);
        _startImageStream();
      } catch (e) {
        debugPrint("Camera initialize failed: $e");
      }
    }
  }

  void _startImageStream() {
    if (_controller == null) return;

    _controller!.startImageStream((CameraImage image) async {
      if (!mounted || _controller == null) return;
      if (_isProcessingFrame) return;
      _isProcessingFrame = true;

      try {
        final avgBrightness =
            image.planes[0].bytes.fold<int>(0, (sum, b) => sum + b) /
            image.planes[0].bytes.length;

        if (avgBrightness < 40) {
          final now = DateTime.now();
          if (_lastLowLightAlertTime == null ||
              now.difference(_lastLowLightAlertTime!) >
                  const Duration(seconds: 4)) {
            _lastLowLightAlertTime = now;
            await _flutterTts.speak(
              "Too dark. Please move to a brighter area.",
            );
          }
          _isProcessingFrame = false;
          return;
        }

        final WriteBuffer allBytes = WriteBuffer();
        for (final plane in image.planes) {
          allBytes.putUint8List(plane.bytes);
        }
        final bytes = allBytes.done().buffer.asUint8List();

        final imageSize = Size(image.width.toDouble(), image.height.toDouble());
        final inputImageFormat = _getInputImageFormat(image.format.raw);

        final inputImageData = InputImageMetadata(
          size: imageSize,
          rotation: InputImageRotation.rotation0deg,
          format: inputImageFormat,
          bytesPerRow: image.planes[0].bytesPerRow,
        );

        final inputImage = InputImage.fromBytes(
          bytes: bytes,
          metadata: inputImageData,
        );

        if (widget.mode == 0) {
          final text = await _textRecognitionService.recognizeTextFromImage(
            inputImage,
          );
          final hasText = text.trim().isNotEmpty;

          if (hasText) {
            _textDetectedFrames++;
            _textNotDetectedFrames = 0;
          } else {
            _textNotDetectedFrames++;
            _textDetectedFrames = 0;
          }

          final now = DateTime.now();
          if (!_isTextDetected &&
              _textDetectedFrames >= debounceThresholdForDetection) {
            _isTextDetected = true;
            if (!_isSpeaking && now.difference(_lastSpeakTime).inSeconds > 1) {
              _speak("Text detected.");
            }
          } else if (_isTextDetected &&
              _textNotDetectedFrames >= debounceThresholdForNoDetection) {
            _isTextDetected = false;
            if (!_isSpeaking && now.difference(_lastSpeakTime).inSeconds > 1) {
              _speak("No text to scan.");
            }
          }
        }
        if (widget.mode == 1) {
          final objects = await _objectRecognitionService
              .recognizeObjectsFromImage(inputImage);
          final now = DateTime.now();
          setState(() {
            _detectedObjects = objects;
          });
          if (!_isSpeaking && now.difference(_lastSpeakTime).inSeconds > 2) {
            if (objects.isEmpty) {
              _speak("No objects detected.");
            } else {
              for (final obj in objects.take(2)) {
                await _speak(obj);
                await Future.delayed(const Duration(seconds: 1));
              }
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error processing camera image: $e');
        }
      } finally {
        _isProcessingFrame = false;
      }
    });
  }

  Future<void> _speak(String message) async {
    if (_isSpeaking) return;
    _isSpeaking = true;
    _lastSpeakTime = DateTime.now();
    await _flutterTts.speak(message);
  }

  Future<void> _captureImage() async {
    if (_controller != null && !_controller!.value.isTakingPicture) {
      final image = await _controller!.takePicture();
      final file = File(image.path);

      if (widget.mode == 0) {
        final result = await _textRecognitionService.recognizeText(file);
        if (mounted) {
          if (result.trim().isNotEmpty) {
            await _flutterTts.speak("Captured.");
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TextResultScreen(recognizedText: result),
              ),
            );
          } else {
            await _flutterTts.speak(
              "No readable text detected. Please try again.",
            );
          }
        }
      }
      // no capture for object mode
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onDoubleTap: () {
          if (widget.mode == 0) {
            _captureImage();
          }
        },
        child: Stack(
          children: [
            if (_isCameraInitialized)
              CameraPreview(_controller!)
            else
              const Center(child: CircularProgressIndicator()),
            // THIS is what you add:
            if (widget.mode == 1 && _detectedObjects.isNotEmpty)
              Positioned(
                top: 40,
                left: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      _detectedObjects
                          .map(
                            (obj) => Text(
                              obj,
                              style: const TextStyle(
                                color: Colors.cyan,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                          .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (_controller != null && _controller!.value.isInitialized) {
      _controller!.pausePreview(); // instead of dispose to keep camera alive
    }
    _flutterTts.stop();
    super.dispose();
  }
}
