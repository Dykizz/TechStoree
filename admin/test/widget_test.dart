import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:techstore_admin/main.dart';
import 'package:techstore_admin/core/providers/auth_provider.dart';
import 'package:techstore_admin/core/providers/theme_provider.dart';
import 'package:techstore_admin/core/providers/navigation_provider.dart';
import 'package:techstore_admin/core/services/api_service.dart';

void main() {
  testWidgets('TechStoreAdminApp smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => NavigationProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => ApiService()),
        ],
        child: const TechStoreAdminApp(),
      ),
    );

    await tester.pump();
    expect(find.byType(TechStoreAdminApp), findsOneWidget);
  });
}
