import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thryve/data/models/models.dart';

import '../../support/harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('only one Wall item can be pinned', () async {
    final Harness h = await Harness.onboarded();
    h.wall.addItem(title: 'A', category: 'Home', image: 'https://a.test/a.jpg');
    h.wall.addItem(title: 'B', category: 'Home', image: 'https://a.test/b.jpg');
    final String a = h.wall.items.last.id;
    final String b = h.wall.items.first.id;

    h.wall.togglePinned(a);
    expect(h.wall.sortedItems.first.id, a);
    expect(h.wall.hasPinned, isTrue);

    h.wall.togglePinned(b);
    expect(h.wall.items.where((WallItem item) => item.isPinned), hasLength(1));
    expect(h.wall.sortedItems.first.id, b);

    h.wall.removeItem(b);
    expect(h.wall.itemById(b), isNull);
    expect(h.wall.sortedItems.first.id, a);
  });

  test('items are trimmed, editable and persisted', () async {
    final Harness h = await Harness.onboarded();
    h.wall.addItem(
      title: '  Lakehouse ',
      category: ' Home ',
      image: 'https://a.test/a.jpg',
      note: ' calm ',
    );
    final String id = h.wall.items.single.id;
    h.wall.updateItem(
      id,
      title: 'Lake cabin',
      category: 'Home',
      image: 'https://a.test/a.jpg',
      note: 'calm',
      nextStep: 'Save for the deposit',
    );

    final Harness restored = await h.restart();
    final WallItem item = restored.wall.itemById(id)!;
    expect(item.title, 'Lake cabin');
    expect(item.category, 'Home');
    expect(item.nextStep, 'Save for the deposit');
  });
}
