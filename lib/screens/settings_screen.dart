import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FlutterTts flutterTts = FlutterTts();

  double _pitch = 1.0;
  double _rate = 0.5;
  String _selectedVoice = 'female';
  double _swipeStartX = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialSettings();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      flutterTts.speak(
        "Settings screen. Swipe left for female voice, right for male voice. Adjust pitch and rate with the sliders below. Pinch to apply and return home.",
      );
    });
  }

  Future<void> _loadInitialSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pitch = prefs.getDouble('pitch') ?? 1.0;
      _rate = prefs.getDouble('rate') ?? 0.5;
      _selectedVoice = prefs.getString('voice') ?? 'female';
    });
  }

  Future<void> _applySettings() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('voice', _selectedVoice);
    prefs.setDouble('pitch', _pitch);
    prefs.setDouble('rate', _rate);

    if (_selectedVoice == 'male') {
      await flutterTts.setVoice({"name": "Daniel", "locale": "en-GB"});
    } else {
      await flutterTts.setVoice({"name": "Samantha", "locale": "en-US"});
    }
    await flutterTts.setPitch(_pitch);
    await flutterTts.setSpeechRate(_rate);

    // set completion only for the apply
    flutterTts.setCompletionHandler(() {
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    });

    await flutterTts.speak("Settings applied. Returning home.");
  }

  void _handleSwipe(double delta) async {
    const swipeSensitivity = 30;

    if (delta > swipeSensitivity && _selectedVoice != 'male') {
      setState(() {
        _selectedVoice = 'male';
      });
      await flutterTts.setVoice({"name": "Daniel", "locale": "en-GB"});
      await flutterTts.speak("Male voice selected. Pinch to apply.");
    } else if (delta < -swipeSensitivity && _selectedVoice != 'female') {
      setState(() {
        _selectedVoice = 'female';
      });
      await flutterTts.setVoice({"name": "Samantha", "locale": "en-US"});
      await flutterTts.speak("Female voice selected. Pinch to apply.");
    }
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: (details) {
        _swipeStartX = details.globalPosition.dx;
      },
      onHorizontalDragUpdate: (details) {
        final delta = details.globalPosition.dx - _swipeStartX;
        _handleSwipe(delta);
      },
      onScaleUpdate: (details) {
        if (details.pointerCount == 2 && details.scale < 0.8) {
          _applySettings();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text("Settings", style: TextStyle(color: Colors.white)),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text(
                    "Select Voice:",
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  ChoiceChip(
                    label: const Text("Female"),
                    selected: _selectedVoice == 'female',
                    onSelected: (selected) async {
                      setState(() {
                        _selectedVoice = 'female';
                      });
                      await flutterTts.setVoice({
                        "name": "Samantha",
                        "locale": "en-US",
                      });
                      await flutterTts.speak(
                        "Female voice selected. Pinch to apply.",
                      );
                    },
                    selectedColor: Colors.cyan,
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text("Male"),
                    selected: _selectedVoice == 'male',
                    onSelected: (selected) async {
                      setState(() {
                        _selectedVoice = 'male';
                      });
                      await flutterTts.setVoice({
                        "name": "Daniel",
                        "locale": "en-GB",
                      });
                      await flutterTts.speak(
                        "Male voice selected. Pinch to apply.",
                      );
                    },
                    selectedColor: Colors.cyan,
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Text("Pitch", style: TextStyle(color: Colors.white)),
                  Expanded(
                    child: Slider(
                      value: _pitch,
                      min: 0.5,
                      max: 2.0,
                      divisions: 6,
                      label: _pitch.toStringAsFixed(1),
                      onChanged: (value) {
                        setState(() {
                          _pitch = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text("Rate", style: TextStyle(color: Colors.white)),
                  Expanded(
                    child: Slider(
                      value: _rate,
                      min: 0.1,
                      max: 1.0,
                      divisions: 9,
                      label: _rate.toStringAsFixed(1),
                      onChanged: (value) {
                        setState(() {
                          _rate = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
