import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advanced_field_app/main.dart';

void main() {
  testWidgets('renders guided sync flow example', (WidgetTester tester) async {
    final pageScrollView = find.byType(Scrollable).first;

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Understand the offline sync flow'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Queue Draft Update'),
      300,
      scrollable: pageScrollView,
    );
    await tester.pumpAndSettle();

    expect(find.text('Queue Draft Update'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('3. Run The Sync Cycle'),
      300,
      scrollable: pageScrollView,
    );
    await tester.pumpAndSettle();

    expect(find.text('3. Run The Sync Cycle'), findsOneWidget);
    expect(find.text('Sync Now'), findsOneWidget);
  });
}
