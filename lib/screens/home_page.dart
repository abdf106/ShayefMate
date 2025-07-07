import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/camera_view.dart';
import '../screens/settings_screen.dart';
import '../screens/catalogue_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedMode = 0;
  Key _cameraKey = UniqueKey();
  final FlutterTts flutterTts = FlutterTts();
  Offset _startSwipeOffset = Offset.zero;

  final List<IconData> modeIcons = [
    Icons.text_fields,
    Icons.park,
    Icons.accessibility_new,
    Icons.attach_money,
  ];

  final List<String> modeLabels = ["Text", "Object", "Person", "Currency"];

  @override
  void initState() {
    super.initState();
    _loadTtsSettings();
    _announceWelcome();
  }

  Future<void> _loadTtsSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedVoice = prefs.getString('voice') ?? 'female';
    final savedPitch = prefs.getDouble('pitch') ?? 1.0;
    final savedRate = prefs.getDouble('rate') ?? 0.5;

    await flutterTts.setLanguage('en-US');
    await flutterTts.setSpeechRate(savedRate);
    await flutterTts.setPitch(savedPitch);
    await flutterTts.setVolume(1.0);

    if (savedVoice == 'male') {
      await flutterTts.setVoice({"name": "Daniel", "locale": "en-GB"});
    } else {
      await flutterTts.setVoice({"name": "Samantha", "locale": "en-US"});
    }
  }

  Future<void> _announceWelcome() async {
    await flutterTts.speak(
      "Text. Swipe left to scan object, swipe again to scan person, swipe once more to scan currency. "
      "Long press anywhere to learn more about the app",
    );
  }

  void _handlePanStart(DragStartDetails details) {
    _startSwipeOffset = details.localPosition;
  }

  void _handlePanEnd(DragEndDetails details) {
    final swipeThreshold = 50;
    final verticalSwipeThreshold = 50;

    final dx = details.velocity.pixelsPerSecond.dx;
    final dy = details.velocity.pixelsPerSecond.dy;

    if (dy.abs() > dx.abs()) {
      // vertical swipe
      if (dy > verticalSwipeThreshold) {
        // swipe down
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        ).then((_) {
          _loadTtsSettings();
          setState(() {
            _cameraKey = UniqueKey();
          });
        });
      }
    } else {
      // horizontal swipe
      if (dx < -swipeThreshold && selectedMode < modeIcons.length - 1) {
        _changeMode(selectedMode + 1);
      } else if (dx > swipeThreshold && selectedMode > 0) {
        _changeMode(selectedMode - 1);
      }
    }
  }

  Future<void> _changeMode(int newMode) async {
    if (newMode != selectedMode) {
      setState(() => selectedMode = newMode);
      HapticFeedback.mediumImpact();
      await flutterTts.stop();
      await flutterTts.speak(modeLabels[newMode]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _handlePanStart,
      onPanEnd: _handlePanEnd,
      onLongPress: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CatalogueScreen()),
        ).then((_) {
          _loadTtsSettings();
          setState(() {
            _cameraKey = UniqueKey();
          });
          flutterTts.speak("Text, double tap to capture");
        });
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            CameraView(key: _cameraKey, mode: selectedMode),
            Column(
              children: [
                const SizedBox(height: 40),
                AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: Padding(
                    padding: const EdgeInsets.only(left: 8.0, top: 8.0),
                    child: IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        ).then((_) {
                          _loadTtsSettings();
                          setState(() {
                            _cameraKey = UniqueKey();
                          });
                        });
                      },
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.help_outline, color: Colors.white),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CatalogueScreen(),
                          ),
                        ).then((_) {
                          _loadTtsSettings();
                          setState(() {
                            _cameraKey = UniqueKey();
                          });
                          flutterTts.speak("Text, double tap to capture");
                        });
                      },
                    ),
                    const SizedBox(width: 16),
                  ],
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(modeIcons.length, (index) {
                      return GestureDetector(
                        onTap: () => _changeMode(index),
                        child: Column(
                          children: [
                            Icon(
                              modeIcons[index],
                              color:
                                  selectedMode == index
                                      ? Colors.cyan
                                      : Colors.white,
                              size: 28,
                            ),
                            if (selectedMode == index)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.cyan,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }
}
