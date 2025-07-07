import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import '../services/database_service.dart';

class FeedbackReviewScreen extends StatefulWidget {
  const FeedbackReviewScreen({super.key});

  @override
  State<FeedbackReviewScreen> createState() => _FeedbackReviewScreenState();
}

class _FeedbackReviewScreenState extends State<FeedbackReviewScreen> {
  List<Map<String, dynamic>> _feedbackList = [];
  final FlutterSoundPlayer _player = FlutterSoundPlayer();

  @override
  void initState() {
    super.initState();
    _loadFeedback();
    _player.openPlayer();
  }

  Future<void> _loadFeedback() async {
    final feedback = await DatabaseService.getAllFeedback();
    setState(() {
      _feedbackList = feedback;
    });
  }

  Future<void> _playAudio(String path) async {
    if (_player.isPlaying) {
      await _player.stopPlayer();
    }
    await _player.startPlayer(fromURI: path);
  }

  @override
  void dispose() {
    _player.closePlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Submitted Feedback'),
        backgroundColor: Colors.black,
      ),
      body:
          _feedbackList.isEmpty
              ? const Center(
                child: Text(
                  'No feedback yet.',
                  style: TextStyle(color: Colors.white),
                ),
              )
              : ListView.builder(
                itemCount: _feedbackList.length,
                itemBuilder: (context, index) {
                  final item = _feedbackList[index];
                  return Card(
                    color: Colors.white10,
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      title: Text(
                        item['rating'] == 1 ? 'Good' : 'Bad',
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if ((item['text'] ?? '').isNotEmpty)
                            Text(
                              "Text: ${item['text']}",
                              style: const TextStyle(color: Colors.white70),
                            ),
                          Text(
                            "Time: ${item['timestamp']}",
                            style: const TextStyle(color: Colors.white38),
                          ),
                          if (item['audioPath'] != null &&
                              item['audioPath'].toString().isNotEmpty)
                            TextButton.icon(
                              onPressed: () => _playAudio(item['audioPath']),
                              icon: const Icon(
                                Icons.play_arrow,
                                color: Colors.cyan,
                              ),
                              label: const Text(
                                'Play Voice',
                                style: TextStyle(color: Colors.cyan),
                              ),
                            )
                          else
                            const Text(
                              'No voice feedback',
                              style: TextStyle(color: Colors.grey),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
