// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pesa_barbaadi/main.dart';
import 'package:pesa_barbaadi/providers/auth_provider.dart';
import 'package:pesa_barbaadi/providers/fuel_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app with ProviderScope and trigger a frame.
    // We override providers to avoid Firebase initialization during tests.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Mock auth state to be unauthenticated initially
          authStateProvider.overrideWith((ref) => Stream.value(null)),
          // Mock current user to be null
          currentUserProvider.overrideWith((ref) => null),
          // Mock trip ID to be null
          tripIdProvider.overrideWith((ref) => null),
        ],
        child: const MyApp(),
      ),
    );

    // Verify that the app starts (MaterialApp is built)
    expect(find.byType(MyApp), findsOneWidget);
  });
}
