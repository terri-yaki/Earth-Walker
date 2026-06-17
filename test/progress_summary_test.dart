import 'package:flutter_test/flutter_test.dart';
import 'package:urbix/utils/progress_summary.dart';

void main() {
  group('formatProgressSummary', () {
    test('renders zeros for a fresh user', () {
      expect(
        formatProgressSummary(
          cellsVisited: 0,
          badgesUnlocked: 0,
          medalsEarned: 0,
          metersWalked: 0,
        ),
        '0 cells visited, 0 badges unlocked, 0 medals earned, 0.0 km walked.',
      );
    });

    test('renders populated stats and a one-decimal km value', () {
      expect(
        formatProgressSummary(
          cellsVisited: 12,
          badgesUnlocked: 3,
          medalsEarned: 2,
          metersWalked: 4321,
        ),
        '12 cells visited, 3 badges unlocked, 2 medals earned, 4.3 km walked.',
      );
    });
  });
}
