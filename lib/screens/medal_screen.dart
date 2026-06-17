import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/medal_provider.dart';

class MedalScreen extends StatelessWidget {
  const MedalScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final medals = context.watch<MedalProvider>().medals;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medals'),
      ),
      body: ListView.builder(
        itemCount: medals.length,
        itemBuilder: (context, index) {
          final medal = medals[index];
          final awarded = context.read<MedalProvider>().isMedalAwarded(medal.id);
          return ListTile(
            leading: Icon(
              Icons.emoji_events,
              color: awarded ? Colors.amber : Colors.grey,
            ),
            title: Text(medal.name),
            subtitle: Text('${medal.condition}% explored'),
          );
        },
      ),
    );
  }
}
