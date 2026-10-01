import 'package:adbs_datepicker/adbs_datepicker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTestWidget({
    NepaliDateDisplayFormat displayFormat = NepaliDateDisplayFormat.bsWithAd,
    NepaliDatePickerStyle style = NepaliDatePickerStyle.standard,
    bool showModeToggle = true,
    bool showSecondaryDay = true,
    bool enableTime = false,
    DateTime? firstAdDate,
    DateTime? lastAdDate,
    NepaliDateService? service,
    AdToBsService? adService,
    NepaliDateTriggerBuilder? triggerBuilder,
    ValueChanged<NepaliDateValue>? onChanged,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: NepaliDatePicker(
          displayFormat: displayFormat,
          style: style,
          showModeToggle: showModeToggle,
          showSecondaryDay: showSecondaryDay,
          enableTime: enableTime,
          firstAdDate: firstAdDate,
          lastAdDate: lastAdDate,
          service: service,
          adService: adService,
          triggerBuilder: triggerBuilder,
          label: 'Select Date',
          hint: 'Choose a date',
          onChanged: onChanged ?? (_) {},
        ),
      ),
    );
  }

  group('NepaliDateDisplayFormat', () {
    test('BS format uses BS date', () {
      expect(
        NepaliDateDisplayFormat.bs.format(
          '2083-06-14',
          '2026-10-01',
        ),
        '2083-06-14',
      );
    });

    test('AD format uses AD date', () {
      expect(
        NepaliDateDisplayFormat.ad.format(
          '2083-06-14',
          '2026-10-01',
        ),
        '2026-10-01',
      );
    });

    test('BS with AD format contains both dates', () {
      final result = NepaliDateDisplayFormat.bsWithAd.format(
        '2083-06-14',
        '2026-10-01',
      );

      expect(result, contains('2083-06-14'));
      expect(result, contains('2026-10-01'));
    });

    test('AD with BS format contains both dates', () {
      final result = NepaliDateDisplayFormat.adWithBs.format(
        '2083-06-14',
        '2026-10-01',
      );

      expect(result, contains('2026-10-01'));
      expect(result, contains('2083-06-14'));
    });

    test('BS format uses BS calendar mode', () {
      expect(
        NepaliDateDisplayFormat.bs.calendarMode,
        CalendarMode.bs,
      );
    });

    test('BS with AD format uses BS calendar mode', () {
      expect(
        NepaliDateDisplayFormat.bsWithAd.calendarMode,
        CalendarMode.bs,
      );
    });

    test('AD format uses AD calendar mode', () {
      expect(
        NepaliDateDisplayFormat.ad.calendarMode,
        CalendarMode.ad,
      );
    });

    test('AD with BS format uses AD calendar mode', () {
      expect(
        NepaliDateDisplayFormat.adWithBs.calendarMode,
        CalendarMode.ad,
      );
    });
  });

  group('NepaliDatePicker', () {
    testWidgets('renders label and hint', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(),
      );

      expect(
        find.text('Select Date'),
        findsOneWidget,
      );

      expect(
        find.text('Choose a date'),
        findsOneWidget,
      );
    });

    testWidgets('renders standard style', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          style: NepaliDatePickerStyle.standard,
        ),
      );

      expect(
        find.text('Select Date'),
        findsOneWidget,
      );
    });

    testWidgets('renders filled style', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          style: NepaliDatePickerStyle.filled,
        ),
      );

      expect(
        find.text('Select Date'),
        findsOneWidget,
      );
    });

    testWidgets('renders outlined style', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          style: NepaliDatePickerStyle.outlined,
        ),
      );

      expect(
        find.text('Select Date'),
        findsOneWidget,
      );
    });

    testWidgets('renders compact style', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          style: NepaliDatePickerStyle.compact,
        ),
      );

      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
      );
    });
    testWidgets('renders card style', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          style: NepaliDatePickerStyle.card,
        ),
      );

      expect(
        find.text('Select Date'),
        findsOneWidget,
      );
    });

    testWidgets('renders list tile style', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          style: NepaliDatePickerStyle.listTile,
        ),
      );

      expect(
        find.text('Select Date'),
        findsOneWidget,
      );
    });

    testWidgets('renders minimal style', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          style: NepaliDatePickerStyle.minimal,
        ),
      );

      expect(
        find.text('Select Date'),
        findsOneWidget,
      );
    });

    testWidgets('supports BS display format', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          displayFormat: NepaliDateDisplayFormat.bs,
        ),
      );

      expect(
        find.text('Select Date'),
        findsOneWidget,
      );
    });

    testWidgets('supports AD display format', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          displayFormat: NepaliDateDisplayFormat.ad,
        ),
      );

      expect(
        find.text('Select Date'),
        findsOneWidget,
      );
    });

    testWidgets('supports BS with AD display format', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          displayFormat: NepaliDateDisplayFormat.bsWithAd,
        ),
      );

      expect(
        find.text('Select Date'),
        findsOneWidget,
      );
    });

    testWidgets('supports AD with BS display format', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          displayFormat: NepaliDateDisplayFormat.adWithBs,
        ),
      );

      expect(
        find.text('Select Date'),
        findsOneWidget,
      );
    });

    testWidgets('supports disabled secondary day', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          showSecondaryDay: false,
        ),
      );

      expect(
        find.text('Select Date'),
        findsOneWidget,
      );
    });

    testWidgets('supports disabled mode toggle', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          showModeToggle: false,
        ),
      );

      expect(
        find.text('Select Date'),
        findsOneWidget,
      );
    });

    testWidgets('supports time selection', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          enableTime: true,
        ),
      );

      expect(
        find.text('Select Date'),
        findsOneWidget,
      );
    });

    testWidgets('supports AD date range', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          firstAdDate: DateTime(2026, 1, 1),
          lastAdDate: DateTime(2026, 12, 31),
        ),
      );

      expect(
        find.text('Select Date'),
        findsOneWidget,
      );
    });

    testWidgets('supports custom trigger builder', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          triggerBuilder: (
            context,
            displayText,
            open,
          ) {
            return ElevatedButton(
              onPressed: open,
              child: Text(
                displayText ?? 'Custom Date Picker',
              ),
            );
          },
        ),
      );

      expect(
        find.text('Custom Date Picker'),
        findsOneWidget,
      );
    });

    testWidgets('custom trigger can be tapped', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          triggerBuilder: (
            context,
            displayText,
            open,
          ) {
            return ElevatedButton(
              onPressed: open,
              child: const Text('Open Calendar'),
            );
          },
        ),
      );

      expect(
        find.text('Open Calendar'),
        findsOneWidget,
      );

      await tester.tap(
        find.text('Open Calendar'),
      );

      await tester.pump();

      expect(
        find.text('Open Calendar'),
        findsOneWidget,
      );
    });
  });
}
