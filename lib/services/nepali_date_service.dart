// services/nepali_date_service.dart
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/nepali_calendar_day.dart';
import '../models/nepali_calendar_month.dart';

class NepaliDateService {
  static const String defaultBaseUrl =
      'https://patro.techarttrekkies.com.np/api/v2/datepicker';

  final String baseUrl;
  final http.Client _client;

  /// In-memory month cache keyed by "year-month".
  final Map<String, NepaliCalendarMonth> _cache = {};
  static const int _maxCacheSize = 24;

  NepaliDateService({String? baseUrl, http.Client? client})
    : baseUrl = baseUrl ?? defaultBaseUrl,
      _client = client ?? http.Client();

  Future<NepaliCalendarMonth> getMonth({
    required int year,
    required int month,
    bool forceRefresh = false,
  }) async {
    final key = '$year-$month';
    if (!forceRefresh && _cache.containsKey(key)) {
      return _cache[key]!;
    }

    final uri = Uri.parse('$baseUrl/dates')
        .replace(queryParameters: {'year': '$year', 'month': '$month'});

    final response = await _client.get(
      uri,
      headers: const {'Accept': 'application/json'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw NepaliDateApiException(
        'Calendar request failed (${response.statusCode}).',
      );
    }

    try {
      final body = jsonDecode(response.body);
      if (body is! Map) {
        throw const NepaliDateApiException('Unexpected API response.');
      }
      final monthData = NepaliCalendarMonth.fromJson(
        body.cast<String, dynamic>(),
      );
      _putCache(key, monthData);
      return monthData;
    } on FormatException catch (e) {
      throw NepaliDateApiException('Invalid API response: ${e.message}');
    }
  }

  /// Current day from API (includes both BS and AD).
  Future<NepaliCalendarDay> getToday() async {
    final uri = Uri.parse('$baseUrl/today');
    final response = await _client.get(
      uri,
      headers: const {'Accept': 'application/json'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw NepaliDateApiException(
        'Today request failed (${response.statusCode}).',
      );
    }

    try {
      final body = jsonDecode(response.body);
      if (body is! Map) {
        throw const NepaliDateApiException('Unexpected API response.');
      }
      return NepaliCalendarDay.fromJson(body.cast<String, dynamic>());
    } on FormatException catch (e) {
      throw NepaliDateApiException('Invalid API response: ${e.message}');
    }
  }

  void _putCache(String key, NepaliCalendarMonth value) {
    if (_cache.length >= _maxCacheSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = value;
  }

  void clearCache() => _cache.clear();

  void dispose() => _client.close();
}

class NepaliDateApiException implements Exception {
  final String message;
  const NepaliDateApiException(this.message);

  @override
  String toString() => message;
}
