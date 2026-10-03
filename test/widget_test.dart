// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:gavthan_bar_restro/main.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  testWidgets('shows the Gavthan splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const GavthanApp());

    expect(find.text('Gavthan Bar and Restro'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image == const AssetImage('assets/images/gavthan_logo.jpeg'),
      ),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 6));
  });
}
