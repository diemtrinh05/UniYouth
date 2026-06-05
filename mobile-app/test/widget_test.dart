import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ProviderScope smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: Text('Smoke'))),
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Smoke'), findsOneWidget);
  });
}
