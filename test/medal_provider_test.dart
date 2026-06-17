import 'package:flutter_test/flutter_test.dart';
import 'package:urbix/providers/medal_provider.dart';

void main() {
  test('MedalProvider exposes the 7 medals in order', () {
    final p = MedalProvider();
    final medals = p.medals;
    expect(medals, hasLength(7));
    expect(medals.first.name, 'Walker Medal');
    expect(medals.first.condition, 10);
    expect(medals.last.condition, 99);
    expect(p.isMedalAwarded(medals.first.id), isFalse);
  });

  test('checkAndAwardMedals awards medals at and above progress', () {
    final p = MedalProvider();
    p.checkAndAwardMedals(40);
    // Conditions 10, 20, 30, 40 are all met -> 4 medals.
    expect(p.awardedMedals, hasLength(4));
  });

  test('resetMedals clears all awarded medals', () {
    final p = MedalProvider();
    p.checkAndAwardMedals(99);
    expect(p.awardedMedals, isNotEmpty);
    p.resetMedals();
    expect(p.awardedMedals, isEmpty);
  });

  test('resetMedals on empty state is a no-op (no notify needed)', () {
    final p = MedalProvider();
    var notifyCount = 0;
    p.addListener(() => notifyCount++);
    p.resetMedals();
    expect(notifyCount, 0);
  });
}