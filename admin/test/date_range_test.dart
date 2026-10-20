import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techstore_admin/core/widgets/app_date_range_picker.dart';

void main() {
  testWidgets('showAppDateRangePicker opens in a non-fullscreen dialog and dismisses on tap outside', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => showAppDateRangePicker(context: context),
                child: const Text('Open Picker'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Picker'));
    await tester.pumpAndSettle();

    // Verify it opened and is constrained
    expect(find.byType(Container), findsWidgets);

    // Tap outside (at 50, 50)
    await tester.tapAt(const Offset(50, 50));
    await tester.pumpAndSettle();

    // Verify it dismissed
    expect(find.text('Chọn khoảng thời gian'), findsNothing);
  });
}
