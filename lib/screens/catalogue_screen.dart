import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CatalogueScreen extends StatefulWidget {
  const CatalogueScreen({super.key});

  @override
  State<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends State<CatalogueScreen> {
  final FlutterTts flutterTts = FlutterTts();

  final List<String> cataloguePoints = [
    "Welcome to ShayefMate. This app helps you recognize text, objects, people, and currency using your camera.",
    "In text mode, double tap anywhere to capture and hear the text.",
    "In object mode, the app automatically speaks detected objects continuously.",
    "You can swipe between recognition modes.",
    "Swipe down to open the settings screen, where you can adjust the voice or speed.",
    "You're back on the home page.",
    "Thank you for using ShayefMate.",
  ];

  @override
  void initState() {
    super.initState();
    _speakCatalogue();
  }

  Future<void> _speakCatalogue() async {
    final prefs = await SharedPreferences.getInstance();
    final savedVoice = prefs.getString('voice') ?? 'female';
    final savedPitch = prefs.getDouble('pitch') ?? 1.0;
    final savedRate = prefs.getDouble('rate') ?? 0.5;

    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(savedRate);
    await flutterTts.setPitch(savedPitch);
    await flutterTts.setVolume(1.0);

    if (savedVoice == 'male') {
      await flutterTts.setVoice({"name": "Daniel", "locale": "en-GB"});
      debugPrint("CatalogueScreen using male voice");
    } else {
      await flutterTts.setVoice({"name": "Samantha", "locale": "en-US"});
      debugPrint("CatalogueScreen using female voice");
    }

    final combinedText = cataloguePoints.join(" ");
    await flutterTts.speak(combinedText);

    flutterTts.setCompletionHandler(() async {
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (context.mounted) {
          Navigator.of(context).maybePop();
        }
      }
    });

    // fallback in case TTS completion fails
    Future.delayed(const Duration(seconds: 32), () {
      if (mounted) {
        Navigator.of(context).maybePop();
      }
    });
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Catalogue", style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.separated(
          itemCount: cataloguePoints.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder:
              (context, index) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "• ",
                    style: TextStyle(color: Colors.cyan, fontSize: 20),
                  ),
                  Expanded(
                    child: Text(
                      cataloguePoints[index],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
        ),
      ),
    );
  }
}
