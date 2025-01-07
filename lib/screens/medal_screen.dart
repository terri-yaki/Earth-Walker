import 'package:flutter/material.dart';

class MedalScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Dummy data, replace with actual data from provider
    final medals = [
      {'title': 'Walker', 'description': '10% explored'},
      {'title': 'Pioneer', 'description': '20% explored'},
      // Add more medals as needed
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Medals'),
      ),
      body: ListView.builder(
        itemCount: medals.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Icon(Icons.emoji_events, color: Colors.amber),
            title: Text(medals[index]['title']!),
            subtitle: Text(medals[index]['description']!),
          );
        },
      ),
    );
  }
}
