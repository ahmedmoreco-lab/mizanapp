import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soulping_care/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'locale': 'en'});
  });

  testWidgets('Mizan opens on the Today dashboard', (tester) async {
    await tester.pumpWidget(const MizanApp());
    await tester.pumpAndSettle();

    expect(find.text('Mizan'), findsOneWidget);
    expect(find.textContaining('Ahmed'), findsOneWidget);
    expect(find.text('Today’s main goal'), findsOneWidget);
    expect(find.text('Start Work Mode'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('bottom navigation opens the Tasks screen', (tester) async {
    await tester.pumpWidget(const MizanApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tasks'));
    await tester.pumpAndSettle();

    expect(find.text('Today’s priorities'), findsOneWidget);
  });
}
