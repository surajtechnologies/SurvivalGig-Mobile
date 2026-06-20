import 'package:flutter_test/flutter_test.dart';
import 'package:trade_app/config/di/service_locator.dart';
import 'package:trade_app/main.dart';

void main() {
  setUp(() async {
    await sl.reset();
    setupServiceLocator();
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('starts at login landing when unauthenticated', (tester) async {
    await tester.pumpWidget(MyApp(bootstrapFuture: Future<void>.value()));
    await tester.pump();

    expect(find.text('Sign Up'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
    expect(find.text('Map'), findsNothing);
  });
}
