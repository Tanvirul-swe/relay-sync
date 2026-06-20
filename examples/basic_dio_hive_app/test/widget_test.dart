import 'package:flutter_test/flutter_test.dart';

import 'package:basic_dio_hive_app/main.dart';

void main() {
  testWidgets('renders monorepo smoke test screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Monorepo wiring ready'), findsOneWidget);
    expect(find.text('Client: DioSyncClient'), findsOneWidget);
    expect(find.text('Storage: HiveSyncStorage'), findsOneWidget);
    expect(find.text('Flutter package: RelaySyncFlutter'), findsOneWidget);
  });
}
