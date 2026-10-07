import 'package:adbs_datepicker/adbs_datepicker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeBsService extends NepaliDateService {
  final day = const NepaliCalendarDay(
    bsYear: 2083,
    bsMonth: 6,
    bsDay: 14,
    adYear: 2026,
    adMonth: 10,
    adDay: 1,
    dateAd: '2026-10-01',
    weekDay: 'Thursday',
    monthName: 'असोज',
    monthNameEn: 'Ashwin',
    longFormat: '',
    today: true,
  );

  @override
  Future<NepaliCalendarDay> getToday() async => day;

  @override
  Future<NepaliCalendarMonth> getMonth({
    required int year,
    required int month,
    bool forceRefresh = false,
  }) async =>
      NepaliCalendarMonth(
        year: year,
        month: month,
        monthName: 'असोज',
        monthNameEn: 'Ashwin',
        totalDays: 1,
        startingWeekday: 1,
        endingWeekday: 1,
        nextMonth: 7,
        nextYear: year,
        previousMonth: 5,
        previousYear: year,
        dates: [day],
      );
}

class _FakeConverter extends AdToBsService {
  @override
  Future<AdToBsResult> convert(DateTime ad) async => AdToBsResult(
        bsYear: 2083,
        bsMonth: 6,
        bsDay: ad.day,
        adYear: ad.year,
        adMonth: ad.month,
        adDay: ad.day,
        weekDay: '',
        monthName: '',
        longFormat: '',
        today: false,
      );
}

BoxDecoration _decoration(WidgetTester tester, Finder text) {
  final tile =
      find.ancestor(of: text, matching: find.byType(AnimatedContainer));
  return tester.widget<AnimatedContainer>(tile.first).decoration!
      as BoxDecoration;
}

Widget _app({
  Color? themeColor,
  DateTime? initialAdDate,
  bool enableRange = false,
  bool enableTime = false,
  AdToBsService? converter,
  NepaliDateService? service,
  NepaliDateDisplayFormat displayFormat = NepaliDateDisplayFormat.ad,
}) {
  return MaterialApp(
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange).copyWith(
        primary: Colors.deepOrange,
        onPrimary: Colors.white,
      ),
    ),
    home: Scaffold(
      body: NepaliDatePicker(
        displayFormat: displayFormat,
        themeColor: themeColor,
        initialAdDate: initialAdDate,
        enableRange: enableRange,
        enableTime: enableTime,
        adService: converter,
        service: service,
        onChanged: (_) {},
      ),
    ),
  );
}

void main() {
  testWidgets('uses the app primary when no picker color is supplied',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.byIcon(Icons.calendar_month));
    await tester.pumpAndSettle();

    expect(_decoration(tester, find.text('AD')).color, Colors.deepOrange);
    final today = _decoration(tester, find.text('${DateTime.now().day}'));
    expect(today.border!.top.color, Colors.deepOrange);
  });

  testWidgets('one color styles the toggle, today, and month/year choices',
      (tester) async {
    const accent = Color(0xff256a9c);
    await tester.pumpWidget(_app(themeColor: accent));
    await tester.tap(find.byIcon(Icons.calendar_month));
    await tester.pumpAndSettle();

    expect(_decoration(tester, find.text('AD')).color, accent);
    expect(
      _decoration(tester, find.text('${DateTime.now().day}')).border!.top.color,
      accent,
    );

    // The title opens the month grid, then its year opens the year grid.
    await tester.tap(find.textContaining('${DateTime.now().year}').last);
    await tester.pumpAndSettle();
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    expect(
        _decoration(tester, find.text(months[DateTime.now().month - 1])).color,
        accent);
    await tester.tap(find.text('${DateTime.now().year}').last);
    await tester.pumpAndSettle();
    expect(
        _decoration(tester, find.text('${DateTime.now().year}')).color, accent);
  });

  testWidgets('BS selection and both sides of the toggle use the same color',
      (tester) async {
    const accent = Color(0xff256a9c);
    final service = _FakeBsService();
    addTearDown(service.dispose);
    await tester.pumpWidget(_app(
      themeColor: accent,
      service: service,
      displayFormat: NepaliDateDisplayFormat.bs,
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.calendar_month));
    await tester.pumpAndSettle();

    expect(_decoration(tester, find.text('BS')).color, accent);
    expect(_decoration(tester, find.text('१४')).color, accent);
    await tester.tap(find.text('AD'));
    await tester.pumpAndSettle();
    expect(_decoration(tester, find.text('AD')).color, accent);
  });

  testWidgets('range uses a lighter shade and endpoints use the accent',
      (tester) async {
    const accent = Color(0xffffdc80);
    final converter = _FakeConverter();
    addTearDown(converter.dispose);
    await tester.pumpWidget(_app(
      themeColor: accent,
      initialAdDate: DateTime(2026, 10, 1),
      enableRange: true,
      enableTime: true,
      converter: converter,
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.calendar_month));
    await tester.pumpAndSettle();
    await tester.tap(find.text('4'));
    await tester.pumpAndSettle();

    expect(_decoration(tester, find.text('1')).color, accent);
    expect(_decoration(tester, find.text('4')).color, accent);
    final shade = Color.alphaBlend(
      accent.withValues(alpha: 0.16),
      Theme.of(tester.element(find.byType(Dialog))).colorScheme.surface,
    );
    expect(_decoration(tester, find.text('2')).color, shade);
    expect(_decoration(tester, find.text('3')).color, shade);
    expect(tester.widget<Text>(find.text('4')).style!.color, Colors.black);

    await tester.tap(find.text('Select time').first);
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(TimePickerDialog)))
          .colorScheme
          .primary,
      accent,
    );
  });
}
