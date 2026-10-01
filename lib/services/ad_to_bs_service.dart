import 'dart:convert';

import 'package:http/http.dart' as http;

/// Result of converting one AD date to BS.
class AdToBsResult {
  final int bsYear;
  final int bsMonth;
  final int bsDay;
  final int adYear;
  final int adMonth;
  final int adDay;

  final String weekDay;
  final String monthName;
  final String longFormat;

  // Nepali (unicode) strings
  final String? unicodeBsYear;
  final String? unicodeBsMonth;
  final String? unicodeBsDay;
  final String? unicodeWeekDay;
  final String? unicodeMonthName;
  final String? unicodeLongFormat;

  final bool today;

  const AdToBsResult({
    required this.bsYear,
    required this.bsMonth,
    required this.bsDay,
    required this.adYear,
    required this.adMonth,
    required this.adDay,
    required this.weekDay,
    required this.monthName,
    required this.longFormat,
    required this.today,
    this.unicodeBsYear,
    this.unicodeBsMonth,
    this.unicodeBsDay,
    this.unicodeWeekDay,
    this.unicodeMonthName,
    this.unicodeLongFormat,
  });

  /// `YYYY-MM-DD` (zero padded) — same shape used elsewhere in the picker.
  String get bsDate => '${_p(bsYear, 4)}-${_p(bsMonth)}-${_p(bsDay)}';
  String get adDate => '${_p(adYear, 4)}-${_p(adMonth)}-${_p(adDay)}';

  static String _p(int n, [int width = 2]) => n.toString().padLeft(width, '0');

  factory AdToBsResult.fromJson(Map<String, dynamic> json) {
    int i(String k) => (json[k] as num).toInt();
    final u = (json['unicode'] as Map?)?.cast<String, dynamic>() ?? const {};

    return AdToBsResult(
      bsYear: i('bs_y'),
      bsMonth: i('bs_m'),
      bsDay: i('bs_d'),
      adYear: i('ad_y'),
      adMonth: i('ad_m'),
      adDay: i('ad_d'),
      weekDay: (json['week_day'] ?? '').toString(),
      monthName: (json['month_name'] ?? '').toString(),
      longFormat: (json['long_format'] ?? '').toString(),
      today: json['today'] == true,
      unicodeBsYear: u['bs_y']?.toString(),
      unicodeBsMonth: u['bs_m']?.toString(),
      unicodeBsDay: u['bs_d']?.toString(),
      unicodeWeekDay: u['week_day']?.toString(),
      unicodeMonthName: u['month_name']?.toString(),
      unicodeLongFormat: u['long_format']?.toString(),
    );
  }
}

/// Converts an AD date to BS using
/// `GET https://patro.techarttrekkies.com.np/ad/{yyyy}/{mm}/{dd}/json`.
///
/// Completely independent from the BS-month [NepaliDateService].
class AdToBsService {
  static const _baseUrl = 'https://patro.techarttrekkies.com.np';

  final http.Client _client;
  final bool _ownsClient;

  AdToBsService({http.Client? client})
    : _client = client ?? http.Client(),
      _ownsClient = client == null;

  Future<AdToBsResult> convert(DateTime ad) async {
    final y = ad.year.toString().padLeft(4, '0');
    final m = ad.month.toString().padLeft(2, '0');
    final d = ad.day.toString().padLeft(2, '0');

    final res = await _client
        .get(Uri.parse('$_baseUrl/ad/$y/$m/$d/json'))
        .timeout(const Duration(seconds: 15));

    if (res.statusCode != 200) {
      throw Exception('Server returned ${res.statusCode}');
    }

    final body = jsonDecode(utf8.decode(res.bodyBytes));
    if (body is! Map<String, dynamic>) {
      throw const FormatException('Unexpected response');
    }
    return AdToBsResult.fromJson(body);
  }

  void dispose() {
    if (_ownsClient) _client.close();
  }
}
