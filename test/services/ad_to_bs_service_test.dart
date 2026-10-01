import 'dart:convert';

import 'package:adbs_datepicker/adbs_datepicker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('AdToBsResult', () {
    test('creates result from JSON', () {
      final result = AdToBsResult.fromJson({
        'bs_y': 2083,
        'bs_m': 6,
        'bs_d': 14,
        'ad_y': 2026,
        'ad_m': 10,
        'ad_d': 1,
        'week_day': 'Thursday',
        'month_name': 'Ashwin',
        'long_format': '14 Ashwin 2083',
        'today': true,
        'unicode': {
          'bs_y': '२०८३',
          'bs_m': '०६',
          'bs_d': '१४',
          'week_day': 'बिहिबार',
          'month_name': 'असोज',
          'long_format': '१४ असोज २०८३',
        },
      });

      expect(result.bsYear, 2083);
      expect(result.bsMonth, 6);
      expect(result.bsDay, 14);

      expect(result.adYear, 2026);
      expect(result.adMonth, 10);
      expect(result.adDay, 1);

      expect(result.weekDay, 'Thursday');
      expect(result.monthName, 'Ashwin');
      expect(result.longFormat, '14 Ashwin 2083');
      expect(result.today, isTrue);

      expect(result.bsDate, '2083-06-14');
      expect(result.adDate, '2026-10-01');

      expect(result.unicodeBsYear, '२०८३');
      expect(result.unicodeBsMonth, '०६');
      expect(result.unicodeBsDay, '१४');
    });
  });

  group('AdToBsService', () {
    test('sends request using zero-padded AD date', () async {
      Uri? requestedUri;

      final client = MockClient((request) async {
        requestedUri = request.url;

        return http.Response(
          jsonEncode({
            'bs_y': 2083,
            'bs_m': 6,
            'bs_d': 14,
            'ad_y': 2026,
            'ad_m': 10,
            'ad_d': 1,
            'week_day': 'Thursday',
            'month_name': 'Ashwin',
            'long_format': '14 Ashwin 2083',
            'today': false,
          }),
          200,
        );
      });

      final service = AdToBsService(client: client);

      final result = await service.convert(
        DateTime(2026, 10, 1),
      );

      expect(
        requestedUri.toString(),
        'https://patro.techarttrekkies.com.np/ad/2026/10/01/json',
      );

      expect(result.bsDate, '2083-06-14');
      expect(result.adDate, '2026-10-01');

      service.dispose();
    });

    test('throws when server returns non-200', () async {
      final client = MockClient((request) async {
        return http.Response('Server error', 500);
      });

      final service = AdToBsService(client: client);

      expect(
        () => service.convert(DateTime(2026, 10, 1)),
        throwsA(
          predicate(
            (error) => error.toString() == 'Exception: Server returned 500',
          ),
        ),
      );

      service.dispose();
    });

    test('throws FormatException for unexpected JSON', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode(['unexpected', 'response']),
          200,
        );
      });

      final service = AdToBsService(client: client);

      expect(
        () => service.convert(DateTime(2026, 10, 1)),
        throwsA(isA<FormatException>()),
      );

      service.dispose();
    });
  });
}
