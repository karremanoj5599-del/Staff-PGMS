import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:staff_pgms/app.dart';
import 'package:staff_pgms/providers/auth_provider.dart';
import 'package:staff_pgms/providers/theme_provider.dart';

void main() {
  testWidgets('Staff app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: const StaffApp(),
      ),
    );
  });
}
