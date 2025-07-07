import 'package:tflite/tflite.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

class ObjectRecognitionService {
  bool _modelLoaded = false;

  Future<void> loadModel() async {
    if (_modelLoaded) return;
    try {
      await Tflite.loadModel(
        model: "assets/detect.tflite",
        labels: "assets/labelmap.txt",
      );
      _modelLoaded = true;
    } catch (e) {
      print("Error loading TFLite model: $e");
    }
  }

  Future<List<String>> recognizeObjectsFromImage(InputImage image) async {
    await loadModel();

    final bytes = image.bytes;
    final metadata = image.metadata;

    if (bytes == null || metadata == null) return [];

    final recognitions = await Tflite.detectObjectOnFrame(
      bytesList: [bytes],
      model: "SSDMobileNet",
      imageHeight: metadata.size.height.toInt(),
      imageWidth: metadata.size.width.toInt(),
      imageMean: 127.5,
      imageStd: 127.5,
      threshold: 0.4,
      asynch: true,
    );

    if (recognitions == null || recognitions.isEmpty) return [];

    final results =
        recognitions
            .where((e) => e["confidenceInClass"] > 0.6)
            .map<String>((e) => e["detectedClass"] as String)
            .toSet()
            .toList();

    return results;
  }
}
