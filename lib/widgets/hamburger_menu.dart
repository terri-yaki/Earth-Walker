// lib/widgets/hamburger_menu.dart

import 'package:flutter/material.dart';
import '../screens/achievement_screen.dart';
import '../screens/medal_screen.dart';
// Import other screens as needed

class HamburgerMenu extends StatelessWidget {
  const HamburgerMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const DrawerHeader(
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
          ListTile(
            leading: const Icon(Icons.emoji_events),
            title: const Text('Achievements'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AchievementScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.star),
            title: const Text('Medals'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MedalScreen()),
              );
            },
          ),
          // Add more menu items like Settings, Offline Downloads
        ],
      ),
    );
  }
}
