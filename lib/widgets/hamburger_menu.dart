// lib/widgets/hamburger_menu.dart

import 'package:flutter/material.dart';
import '../screens/achievement_screen.dart';
import '../screens/medal_screen.dart';
// Import other screens as needed

class HamburgerMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.green,
            ),
            child: Text(
              'Earth Walker',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontFamily: 'PixelFont',
              ),
            ),
          ),
          SwitchListTile(
            title: Text('Toggle Exploration Log'),
            value: true, // Replace with actual value from provider
            onChanged: (bool value) {
              // Implement toggle functionality
              // For example:
              // Provider.of<MapProvider>(context, listen: false).toggleExplorationLog(value);
            },
          ),
          ListTile(
            leading: Icon(Icons.emoji_events),
            title: Text('Achievements'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AchievementScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.star),
            title: Text('Medals'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MedalScreen()),
              );
            },
          ),
          // Add more menu items like Settings, Offline Downloads
        ],
      ),
    );
  }
}
