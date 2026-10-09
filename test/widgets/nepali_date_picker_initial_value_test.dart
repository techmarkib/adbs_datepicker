import 'dart:convert';

import 'package:adbs_datepicker/adbs_datepicker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// BS 2083-06-01 … 2083-06-30 maps to AD 2026-09-18 … 2026-10-17.
/// In particular 2083-06-14 ↔ 2026-10-01 and 2083-06-20 ↔ 2026-10-07.
Map<String, dynamic> _dayJson(
  int bsD,
  DateTime ad, {
  bool today = false,
}) {
  return {
    'bs_y': 2083,
    'bs_m': 6,
    'bs_d': bsD,
    'ad_y': ad.year,
    'ad_m': ad.month,
    'ad_d': ad.day,
    'date_ad':
        '${ad.year}-${ad.month.toString().padLeft(2, '0')}-${ad.day.toString().padLeft(2, '0')}',
    'week_day': 'Thursday',
    'month_name': 'असोज',
    'month_name_en': 'Ashwin',
    'long_format': '$bsD Ashwin 2083',
    'today': today,
    'events': [],
  };
}

Map<String, dynamic> _month208306Json() {
  final firstAd = DateTime(2026, 9, 18);

  return {
    'year': 2083,
    'month': 6,
    'month_name': 'असोज',
    'month_name_en': 'Ashwin',
    'month_info': {
      'total_days': 30,
      'starting_weekday': {'number': 4, 'name': 'बिहिबार'},
      'ending_weekday': {'number': 5, 'name': 'शुक्रबार'},
      'next_month': 7,
      'next_year': 2083,
      'prev_month': 5,
      'prev_year': 2083,
    },
    'dates': [
      for (var d = 1; d <= 30; d++)
        _dayJson(d, firstAd.add(Duration(days: d - 1))),
    ],
  };
}

Map<String, dynamic> _todayJson() => _dayJson(14, DateTime(2026, 10, 1), today: true);

Map<String, dynamic> _convertJson(int bsD, int adD) {
  return {
    'bs_y': 2083,
    'bs_m': 6,
    'bs_d': bsD,
    'ad_y': 2026,
    'ad_m': 10,
    'ad_d': adD,
    'week_day': 'Thursday',
    'month_name': 'Ashwin',
    'long_format': '$bsD Ashwin 2083',
    'today': false,
  };
}

/// A picker wired to a fake BS calendar / AD→BS API.
Widget _picker({
  String? initialBsDate,
  DateTime? initialAdDate,
  String? initialBsEndDate,
  DateTime? initialAdEndDate,
  TimeOfDay? initialTime,
  TimeOfDay? initialEndTime,
  NepaliDateDisplayFormat displayFormat = NepaliDateDisplayFormat.bsWithAd,
  bool enableRange = false,
  bool enableTime = false,
  void Function(NepaliDateValue)? onChanged,
}) {
  final client = MockClient((request) async {
    final url = request.url;
    final path = url.path;

    http.Response ok(Map<String, dynamic> json) => http.Response(
          // The body contains Nepali text, so the charset must
          // be declared — otherwise the http package falls back
          // to ASCII and rejects the body.
          jsonEncode(json),
          200,
          headers: const {
            'content-type': 'application/json; charset=utf-8',
          },
        );

    if (path.endsWith('/today')) return ok(_todayJson());

    if (path.endsWith('/dates')) {
      final year = int.parse(url.queryParameters['year']!);
      final month = int.parse(url.queryParameters['month']!);
      if (year == 2083 && month == 6) return ok(_month208306Json());
      throw Exception('Unexpected month $year-$month');
    }

    // AD → BS conversion: /ad/{yyyy}/{mm}/{dd}/json
    final match = RegExp(r'/ad/(\d{4})/(\d{2})/(\d{2})/json$')
        .firstMatch(path);
    if (match != null) {
      final ad = DateTime(
        int.parse(match.group(1)!),
        int.parse(match.group(2)!),
        int.parse(match.group(3)!),
      );
      if (ad == DateTime(2026, 10, 1)) {
        return ok(_convertJson(14, 1));
      }
      if (ad == DateTime(2026, 10, 7)) {
        return ok(_convertJson(20, 7));
      }
      throw Exception('Unexpected AD date $ad');
    }

    throw Exception('Unexpected request ${request.url}');
  });

  return MaterialApp(
    home: Scaffold(
      body: NepaliDatePicker(
        initialBsDate: initialBsDate,
        initialAdDate: initialAdDate,
        initialBsEndDate: initialBsEndDate,
        initialAdEndDate: initialAdEndDate,
        initialTime: initialTime,
        initialEndTime: initialEndTime,
        displayFormat: displayFormat,
        enableRange: enableRange,
        enableTime: enableTime,
        service: NepaliDateService(client: client),
        adService: AdToBsService(client: client),
        onChanged: onChanged ?? (_) {},
      ),
    ),
  );
}

Future<void> _settle(WidgetTester tester, Widget widget) async {
  await tester.pumpWidget(widget);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows an existing BS value in BS format', (tester) async {
    await _settle(
      tester,
      _picker(
        displayFormat: NepaliDateDisplayFormat.bs,
        initialBsDate: '2083-06-14',
      ),
    );

    expect(find.text('2083-06-14'), findsOneWidget);
  });

  testWidgets('accepts compact (unpadded) BS input', (tester) async {
    await _settle(
      tester,
      _picker(initialBsDate: '2083-6-14'),
    );

    expect(find.text('2083-06-14 (2026-10-01)'), findsOneWidget);
  });

  testWidgets(
    'converts a stored AD value when a BS format is used',
    (tester) async {
      await _settle(
        tester,
        _picker(
          displayFormat: NepaliDateDisplayFormat.bsWithAd,
          initialAdDate: DateTime(2026, 10, 1),
        ),
      );

      expect(find.text('2083-06-14 (2026-10-01)'), findsOneWidget);
    },
  );

  testWidgets('shows an existing AD value in AD format', (tester) async {
    await _settle(
      tester,
      _picker(
        displayFormat: NepaliDateDisplayFormat.ad,
        initialAdDate: DateTime(2026, 10, 1),
      ),
    );

    expect(find.text('2026-10-01'), findsOneWidget);
  });

  testWidgets('shows an existing AD value in AD-with-BS format',
      (tester) async {
    await _settle(
      tester,
      _picker(
        displayFormat: NepaliDateDisplayFormat.adWithBs,
        initialAdDate: DateTime(2026, 10, 1),
      ),
    );

    expect(find.text('2026-10-01 (2083-06-14)'), findsOneWidget);
  });

  testWidgets('selects today when no initial value is given',
      (tester) async {
    await _settle(
      tester,
      _picker(displayFormat: NepaliDateDisplayFormat.bs),
    );

    expect(find.text('2083-06-14'), findsOneWidget);
  });

  testWidgets('shows the hint when nothing is selected (AD format)',
      (tester) async {
    await _settle(
      tester,
      _picker(displayFormat: NepaliDateDisplayFormat.ad),
    );

    expect(find.text('Select date'), findsOneWidget);
  });

  testWidgets('restores an existing range from BS values',
      (tester) async {
    await _settle(
      tester,
      _picker(
        enableRange: true,
        initialBsDate: '2083-06-14',
        initialBsEndDate: '2083-06-20',
      ),
    );

    expect(
      find.text('2083-06-14 (2026-10-01)  →  2083-06-20 (2026-10-07)'),
      findsOneWidget,
    );
  });

  testWidgets('restores an existing range from AD values',
      (tester) async {
    await _settle(
      tester,
      _picker(
        displayFormat: NepaliDateDisplayFormat.adWithBs,
        enableRange: true,
        initialAdDate: DateTime(2026, 10, 1),
        initialAdEndDate: DateTime(2026, 10, 7),
      ),
    );

    expect(
      find.text('2026-10-01 (2083-06-14)  →  2026-10-07 (2083-06-20)'),
      findsOneWidget,
    );
  });

  testWidgets('restores an existing time', (tester) async {
    await _settle(
      tester,
      _picker(
        enableTime: true,
        initialBsDate: '2083-06-14',
        initialTime: const TimeOfDay(hour: 10, minute: 30),
      ),
    );

    expect(
      find.text('2083-06-14 (2026-10-01)  •  10:30 AM'),
      findsOneWidget,
    );
  });

  testWidgets('restores an existing range with times', (tester) async {
    await _settle(
      tester,
      _picker(
        enableRange: true,
        enableTime: true,
        initialBsDate: '2083-06-14',
        initialBsEndDate: '2083-06-20',
        initialTime: const TimeOfDay(hour: 10, minute: 30),
        initialEndTime: const TimeOfDay(hour: 18, minute: 45),
      ),
    );

    expect(
      find.text(
        '2083-06-14 (2026-10-01)  →  2083-06-20 (2026-10-07)'
        '  •  10:30 AM – 6:45 PM',
      ),
      findsOneWidget,
    );
  });

  testWidgets('updates the shown value when the initial value changes',
      (tester) async {
    await _settle(
      tester,
      _picker(
        displayFormat: NepaliDateDisplayFormat.bs,
        initialBsDate: '2083-06-14',
      ),
    );
    expect(find.text('2083-06-14'), findsOneWidget);

    // An edit form loading a different record into the same picker.
    await _settle(
      tester,
      _picker(
        displayFormat: NepaliDateDisplayFormat.bs,
        initialBsDate: '2083-06-20',
      ),
    );

    expect(find.text('2083-06-20'), findsOneWidget);
    expect(find.text('2083-06-14'), findsNothing);
  });

  testWidgets('does not emit onChanged for restored values',
      (tester) async {
    var emissions = 0;

    await _settle(
      tester,
      _picker(
        initialBsDate: '2083-06-14',
        initialTime: const TimeOfDay(hour: 10, minute: 30),
        onChanged: (_) => emissions++,
      ),
    );

    expect(emissions, 0);
  });

  testWidgets('invalid initial BS value falls back to the hint',
      (tester) async {
    await _settle(
      tester,
      _picker(
        displayFormat: NepaliDateDisplayFormat.bs,
        initialBsDate: 'not-a-date',
      ),
    );

    // BS format selects today when no valid initial value exists.
    expect(find.text('2083-06-14'), findsOneWidget);
  });
}
