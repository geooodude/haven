import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:havennyc/app.dart';
import 'package:havennyc/core/constants/app_flavor.dart';

void main() {
  testWidgets('HavenApp shows flavor label', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: HavenApp(flavor: AppFlavor.development),
      ),
    );

    expect(find.text('development flavor'), findsOneWidget);
    expect(find.text('Haven NYC Dev'), findsOneWidget);
  });
}
