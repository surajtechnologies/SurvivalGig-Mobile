# Login Screen Unit Test Case

Target screen: `lib/features/auth/presentation/screens/login_screen.dart`

Suggested test file: `test/features/auth/presentation/screens/login_screen_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trade_app/config/di/service_locator.dart';
import 'package:trade_app/features/auth/presentation/screens/login_screen.dart';

void main() {
  setUp(() async {
    await sl.reset();
    setupServiceLocator();
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets(
    'shows email and password validation when Log In is tapped with empty fields',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreenNew(),
        ),
      );

      final emailField = find.byWidgetPredicate(
        (widget) =>
            widget is TextFormField &&
            widget.keyboardType == TextInputType.emailAddress &&
            widget.decoration?.hintText == 'Enter Email Address',
      );

      final passwordField = find.byWidgetPredicate(
        (widget) =>
            widget is TextFormField &&
            widget.obscureText &&
            widget.decoration?.hintText == 'Enter Password',
      );

      expect(find.text('Log In to SurvivalGig'), findsOneWidget);
      expect(emailField, findsOneWidget);
      expect(passwordField, findsOneWidget);

      await tester.tap(find.text('Log In'));
      await tester.pump();

      expect(find.text('Email address is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    },
  );
}
```

Note: This test case was written only as documentation and was not executed.
