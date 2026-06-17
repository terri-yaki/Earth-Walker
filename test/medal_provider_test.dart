import 'package:flutter_test/flutter_test.dart';
import 'package:earthwalker/providers/medal_provider.dart';

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
}