import 'package:flutter/material.dart';

class ObjectResultScreen extends StatelessWidget {
  final List<String> recognizedObjects;

  const ObjectResultScreen({super.key, required this.recognizedObjects});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Object Detection Result')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            recognizedObjects.isEmpty
                ? const Center(
                  child: Text(
                    'No objects detected.',
                    style: TextStyle(fontSize: 20),
                  ),
                )
                : ListView.builder(
                  itemCount: recognizedObjects.length,
                  itemBuilder: (context, index) {
                    final object = recognizedObjects[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.image_search),
                        title: Text(
                          object,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
