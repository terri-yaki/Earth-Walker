// lib/screens/achievement_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/achievement_provider.dart';
import '../utils/constants.dart';

class AchievementScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final achievementProvider = Provider.of<AchievementProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Achievements',
          style: AppTextStyles.appBarTitle,
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildPercentageRow(
                'Country', achievementProvider.countryExplored, context),
            SizedBox(height: 10),
            _buildPercentageRow(
                'Continent', achievementProvider.continentExplored, context),
            SizedBox(height: 10),
            _buildPercentageRow(
                'World', achievementProvider.worldExplored, context),
          ],
        ),
      ),
    );
  }

  Widget _buildPercentageRow(
      String title, int percentage, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$title Exploration:',
          style: AppTextStyles.achievementTitle,
        ),
        Text(
          '$percentage%',
          style: AppTextStyles.achievementPercentage,
        ),
      ],
    );
  }
}
