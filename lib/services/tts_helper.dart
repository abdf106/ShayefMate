import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TtsHelper {
  static final FlutterTts tts = FlutterTts();

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final voice = prefs.getString('selectedVoice') ?? 'female';
    final pitch = prefs.getDouble('pitch') ?? 1.0;
    final rate = prefs.getDouble('rate') ?? 0.5;

    if (voice == 'male') {
      await tts.setVoice({"name": "Daniel", "locale": "en-GB"});
    } else {
      await tts.setVoice({"name": "Samantha", "locale": "en-US"});
    }

    await tts.setPitch(pitch);
    await tts.setSpeechRate(rate);
    await tts.setVolume(1.0);

    tts.setCompletionHandler(() {});
    tts.setErrorHandler((msg) {});
  }
}
