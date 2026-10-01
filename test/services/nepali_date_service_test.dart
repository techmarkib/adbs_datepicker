import 'dart:convert';

import 'package:adbs_datepicker/adbs_datepicker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response jsonResponse(
  Map<String, dynamic> json, {
  int statusCode = 200,
}) {
  return http.Response.bytes(
    utf8.encode(jsonEncode(json)),
    statusCode,
    headers: {
      'content-type': 'application/json; charset=utf-8',
    },
  );
}

Map<String, dynamic> monthJson({
  int year = 2083,
  int month = 6,
}) {
  return {
    'year': year,
    'month': month,
    'month_name': 'असोज',
    'month_name_en': 'Ashwin',
    'month_info': {
      'total_days': 31,
      'starting_weekday': {
        'number': 3,
      },
      'ending_weekday': {
        'number': 5,
      },
      'next_month': month == 12 ? 1 : month + 1,
      'next_year': month == 12 ? year + 1 : year,
      'prev_month': month == 1 ? 12 : month - 1,
      'prev_year': month == 1 ? year - 1 : year,
    },
    'dates': [
      {
        'bs_y': year,
        'bs_m': month,
        'bs_d': 1,
        'ad_y': 2026,
        'ad_m': 9,
        'ad_d': 18,
        'date_ad': '2026-09-18',
        'week_day': 'Friday',
        'month_name': 'असोज',
        'month_name_en': 'Ashwin',
        'long_format': '1 असोज 2083',
        'today': false,
        'events': [],
      },
    ],
  };
}

Map<String, dynamic> todayJson() {
  return {
    'bs_y': 2083,
    'bs_m': 6,
    'bs_d': 14,
    'ad_y': 2026,
    'ad_m': 10,
    'ad_d': 1,
    'date_ad': '2026-10-01',
    'week_day': 'Thursday',
    'month_name': 'असोज',
    'month_name_en': 'Ashwin',
    'long_format': '14 असोज 2083',
    'today': true,
    'events': [],
  };
}

void main() {
  group('NepaliDateService', () {
    test('getMonth requests correct URL and parses response', () async {
      Uri? requestedUri;

      final client = MockClient((request) async {
        requestedUri = request.url;

        return jsonResponse(monthJson());
      });

      final service = NepaliDateService(
        baseUrl: 'https://example.com/api',
        client: client,
      );

      final result = await service.getMonth(
        year: 2083,
        month: 6,
      );

      expect(
        requestedUri.toString(),
        'https://example.com/api/dates?year=2083&month=6',
      );

      expect(result.year, 2083);
      expect(result.month, 6);
      expect(result.monthName, 'असोज');
      expect(result.monthNameEn, 'Ashwin');
      expect(result.totalDays, 31);
      expect(result.dates, hasLength(1));
      expect(result.dates.first.bsDate, '2083-06-01');

      service.dispose();
    });

    test('getMonth caches the response', () async {
      var requestCount = 0;

      final client = MockClient((request) async {
        requestCount++;

        return jsonResponse(monthJson());
      });

      final service = NepaliDateService(
        baseUrl: 'https://example.com/api',
        client: client,
      );

      final first = await service.getMonth(
        year: 2083,
        month: 6,
      );

      final second = await service.getMonth(
        year: 2083,
        month: 6,
      );

      expect(requestCount, 1);
      expect(identical(first, second), isTrue);

      service.dispose();
    });

    test('different months are fetched separately', () async {
      var requestCount = 0;

      final client = MockClient((request) async {
        requestCount++;

        final month = request.url.queryParameters['month'];

        return jsonResponse(
          monthJson(
            year: 2083,
            month: int.parse(month!),
          ),
        );
      });

      final service = NepaliDateService(
        baseUrl: 'https://example.com/api',
        client: client,
      );

      final first = await service.getMonth(
        year: 2083,
        month: 6,
      );

      final second = await service.getMonth(
        year: 2083,
        month: 7,
      );

      expect(requestCount, 2);
      expect(first.month, 6);
      expect(second.month, 7);

      service.dispose();
    });

    test('forceRefresh bypasses cache', () async {
      var requestCount = 0;

      final client = MockClient((request) async {
        requestCount++;

        return jsonResponse(monthJson());
      });

      final service = NepaliDateService(
        baseUrl: 'https://example.com/api',
        client: client,
      );

      await service.getMonth(
        year: 2083,
        month: 6,
      );

      await service.getMonth(
        year: 2083,
        month: 6,
        forceRefresh: true,
      );

      expect(requestCount, 2);

      service.dispose();
    });

    test('clearCache causes the next request to hit the API', () async {
      var requestCount = 0;

      final client = MockClient((request) async {
        requestCount++;

        return jsonResponse(monthJson());
      });

      final service = NepaliDateService(
        baseUrl: 'https://example.com/api',
        client: client,
      );

      await service.getMonth(
        year: 2083,
        month: 6,
      );

      expect(requestCount, 1);

      service.clearCache();

      await service.getMonth(
        year: 2083,
        month: 6,
      );

      expect(requestCount, 2);

      service.dispose();
    });

    test('getMonth throws NepaliDateApiException for server error', () async {
      final client = MockClient((request) async {
        return http.Response(
          'Server error',
          500,
        );
      });

      final service = NepaliDateService(
        baseUrl: 'https://example.com/api',
        client: client,
      );

      expect(
        () => service.getMonth(
          year: 2083,
          month: 6,
        ),
        throwsA(isA<NepaliDateApiException>()),
      );

      service.dispose();
    });

    test('getMonth throws for unexpected response body', () async {
      final client = MockClient((request) async {
        return jsonResponse({
          'unexpected': 'response',
        });
      });

      final service = NepaliDateService(
        baseUrl: 'https://example.com/api',
        client: client,
      );

      expect(
        () => service.getMonth(
          year: 2083,
          month: 6,
        ),
        throwsA(isA<TypeError>()),
      );

      service.dispose();
    });
    test('getMonth throws for invalid JSON', () async {
      final client = MockClient((request) async {
        return http.Response(
          '{invalid json',
          200,
        );
      });

      final service = NepaliDateService(
        baseUrl: 'https://example.com/api',
        client: client,
      );

      expect(
        () => service.getMonth(
          year: 2083,
          month: 6,
        ),
        throwsA(
          predicate(
            (error) =>
                error is NepaliDateApiException &&
                error.message.startsWith('Invalid API response:'),
          ),
        ),
      );

      service.dispose();
    });

    test('getToday requests today endpoint', () async {
      Uri? requestedUri;

      final client = MockClient((request) async {
        requestedUri = request.url;

        return jsonResponse(todayJson());
      });

      final service = NepaliDateService(
        baseUrl: 'https://example.com/api',
        client: client,
      );

      final result = await service.getToday();

      expect(
        requestedUri.toString(),
        'https://example.com/api/today',
      );

      expect(result.bsDate, '2083-06-14');
      expect(result.adDate, '2026-10-01');
      expect(result.today, isTrue);

      service.dispose();
    });

    test('getToday throws NepaliDateApiException for server error', () async {
      final client = MockClient((request) async {
        return http.Response(
          'Server error',
          503,
        );
      });

      final service = NepaliDateService(
        baseUrl: 'https://example.com/api',
        client: client,
      );

      expect(
        () => service.getToday(),
        throwsA(
          predicate(
            (error) =>
                error is NepaliDateApiException &&
                error.message == 'Today request failed (503).',
          ),
        ),
      );

      service.dispose();
    });

    test('getToday throws for invalid JSON', () async {
      final client = MockClient((request) async {
        return http.Response(
          '{invalid json',
          200,
        );
      });

      final service = NepaliDateService(
        baseUrl: 'https://example.com/api',
        client: client,
      );

      expect(
        () => service.getToday(),
        throwsA(
          predicate(
            (error) =>
                error is NepaliDateApiException &&
                error.message.startsWith('Invalid API response:'),
          ),
        ),
      );

      service.dispose();
    });
  });

  group('NepaliDateApiException', () {
    test('stores message', () {
      const exception = NepaliDateApiException(
        'Something went wrong',
      );

      expect(
        exception.message,
        'Something went wrong',
      );
    });

    test('toString returns message', () {
      const exception = NepaliDateApiException(
        'Something went wrong',
      );

      expect(
        exception.toString(),
        'Something went wrong',
      );
    });
  });
}
