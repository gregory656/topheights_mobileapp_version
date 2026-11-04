import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:topheights/features/shell/brand_mark.dart';

void main() {
  testWidgets('Top Heights brand mark renders', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Center(child: BrandMark()))),
    );

    expect(find.byType(BrandMark), findsOneWidget);
  });
}
