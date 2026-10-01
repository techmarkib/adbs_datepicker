import 'nepali_calendar_event.dart';

class NepaliCalendarDay {
  final int bsYear;
  final int bsMonth;
  final int bsDay;
  final int adYear;
  final int adMonth;
  final int adDay;
  final String dateAd;
  final String weekDay;
  final String monthName;
  final String monthNameEn;
  final String longFormat;
  final String? unicodeBsYear;
  final String? unicodeBsMonth;
  final String? unicodeBsDay;
  final String? unicodeAdYear;
  final String? unicodeAdMonth;
  final String? unicodeAdDay;
  final String? unicodeWeekDay;
  final String? unicodeMonthName;
  final String? unicodeLongFormat;
  final bool today;
  final List<NepaliCalendarEvent> events;

  const NepaliCalendarDay({
    required this.bsYear,
    required this.bsMonth,
    required this.bsDay,
    required this.adYear,
    required this.adMonth,
    required this.adDay,
    required this.dateAd,
    required this.weekDay,
    required this.monthName,
    required this.monthNameEn,
    required this.longFormat,
    this.unicodeBsYear,
    this.unicodeBsMonth,
    this.unicodeBsDay,
    this.unicodeAdYear,
    this.unicodeAdMonth,
    this.unicodeAdDay,
    this.unicodeWeekDay,
    this.unicodeMonthName,
    this.unicodeLongFormat,
    this.today = false,
    this.events = const [],
  });

  factory NepaliCalendarDay.fromJson(Map<String, dynamic> json) {
    final unicode = (json['unicode'] as Map?)?.cast<String, dynamic>();
    final rawEvents = json['events'] is List
        ? json['events'] as List
        : const [];

    return NepaliCalendarDay(
      bsYear: _int(json['bs_y']),
      bsMonth: _int(json['bs_m']),
      bsDay: _int(json['bs_d']),
      adYear: _int(json['ad_y']),
      adMonth: _int(json['ad_m']),
      adDay: _int(json['ad_d']),
      dateAd: '${json['date_ad'] ?? ''}',
      weekDay: '${json['week_day'] ?? ''}',
      monthName: '${json['month_name'] ?? ''}',
      monthNameEn: '${json['month_name_en'] ?? ''}',
      longFormat: '${json['long_format'] ?? ''}',
      unicodeBsYear: unicode?['bs_y']?.toString(),
      unicodeBsMonth: unicode?['bs_m']?.toString(),
      unicodeBsDay: unicode?['bs_d']?.toString(),
      unicodeAdYear: unicode?['ad_y']?.toString(),
      unicodeAdMonth: unicode?['ad_m']?.toString(),
      unicodeAdDay: unicode?['ad_d']?.toString(),
      unicodeWeekDay: unicode?['week_day']?.toString(),
      unicodeMonthName: unicode?['month_name']?.toString(),
      unicodeLongFormat: unicode?['long_format']?.toString(),
      today: json['today'] == true,
      events: rawEvents
          .whereType<Map>()
          .map((e) => NepaliCalendarEvent.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }

  bool get isNationalHoliday => events.any((e) => e.nationalHoliday);

  bool get hasEvents => events.isNotEmpty;
  static int _int(dynamic value) => int.parse(value.toString());

  String get bsDate =>
      '$bsYear-${bsMonth.toString().padLeft(2, '0')}-${bsDay.toString().padLeft(2, '0')}';
  String get adDate =>
      '$adYear-${adMonth.toString().padLeft(2, '0')}-${adDay.toString().padLeft(2, '0')}';
  DateTime get adDateTime => DateTime(adYear, adMonth, adDay);
}
