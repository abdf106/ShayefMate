import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite/tflite.dart';
import 'package:flutter_tts/flutter_tts.dart';

class ObjectDetectionScreen extends StatefulWidget {
  const ObjectDetectionScreen({super.key});

  @override
  _ObjectDetectionScreenState createState() => _ObjectDetectionScreenState();
}

class _ObjectDetectionScreenState extends State<ObjectDetectionScreen> {
  CameraController? _cameraController;
  final FlutterTts _flutterTts = FlutterTts();
  bool _isDetecting = false;
  DateTime? _lastDetectionTime;
  DateTime? _lastLowLightAlertTime;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _loadModel();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    _cameraController = CameraController(cameras[0], ResolutionPreset.high);
    await _cameraController!.initialize();
    _cameraController!.startImageStream((CameraImage img) async {
      if (_isDetecting) return;

      final now = DateTime.now();
      if (_lastDetectionTime != null &&
          now.difference(_lastDetectionTime!) < Duration(milliseconds: 500)) {
        return;
      }

      _isDetecting = true;
      _lastDetectionTime = now;

      // Calculate average brightness from Y plane
      final avgBrightness =
          img.planes[0].bytes.fold<int>(0, (sum, b) => sum + b) /
          img.planes[0].bytes.length;

      // If too dark
      if (avgBrightness < 40) {
        // Speak warning no more than once every 4 seconds
        if (_lastLowLightAlertTime == null ||
            now.difference(_lastLowLightAlertTime!) > Duration(seconds: 4)) {
          _lastLowLightAlertTime = now;
          await _flutterTts.speak("Too dark. Please move to a brighter area.");
        }
      } else {
        await _runModelOnFrame(img);
      }

      _isDetecting = false;
    });

    setState(() {});
  }

  Future<void> _loadModel() async {
    await Tflite.loadModel(
      model: "assets/detect.tflite",
      labels: "assets/labelmap.txt",
    );
  }

  Future<void> _runModelOnFrame(CameraImage image) async {
    var recognitions = await Tflite.detectObjectOnFrame(
      bytesList: image.planes.map((plane) => plane.bytes).toList(),
      model: "SSDMobileNet",
      imageHeight: image.height,
      imageWidth: image.width,
      imageMean: 127.5,
      imageStd: 127.5,
      threshold: 0.3,
      asynch: true,
    );

    if (recognitions != null && recognitions.isNotEmpty) {
      final filtered =
          recognitions.where((e) => e["confidenceInClass"] >= 0.6).toList()
            ..sort(
              (a, b) =>
                  b["confidenceInClass"].compareTo(a["confidenceInClass"]),
            );

      final objectNames = filtered
          .map((e) => e["detectedClass"])
          .toSet()
          .take(2);

      for (var name in objectNames) {
        await _flutterTts.speak(name);
        await Future.delayed(Duration(seconds: 2));
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    Tflite.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _cameraController != null && _cameraController!.value.isInitialized
              ? CameraPreview(_cameraController!)
              : Center(child: CircularProgressIndicator()),
    );
  }
}
