/// Smoke test — verifies the app mounts without crashing.
/// Counter test removed: the generated counter widget no longer exists.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noor_companion/main.dart';

void main() {
  testWidgets('App mounts without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: NoorApp()));
    expect(find.byType(ProviderScope), findsOneWidget);
  });
}
