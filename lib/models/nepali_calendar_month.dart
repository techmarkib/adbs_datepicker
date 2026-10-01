import 'nepali_calendar_day.dart';

class NepaliCalendarMonth {
  final int year;
  final int month;
  final String monthName;
  final String monthNameEn;
  final int totalDays;
  final int startingWeekday;
  final int endingWeekday;
  final int nextMonth;
  final int nextYear;
  final int previousMonth;
  final int previousYear;
  final List<NepaliCalendarDay> dates;

  const NepaliCalendarMonth({
    required this.year,
    required this.month,
    required this.monthName,
    required this.monthNameEn,
    required this.totalDays,
    required this.startingWeekday,
    required this.endingWeekday,
    required this.nextMonth,
    required this.nextYear,
    required this.previousMonth,
    required this.previousYear,
    required this.dates,
  });

  factory NepaliCalendarMonth.fromJson(Map<String, dynamic> json) {
    final info = (json['month_info'] as Map).cast<String, dynamic>();
    final start = (info['starting_weekday'] as Map).cast<String, dynamic>();
    final end = (info['ending_weekday'] as Map).cast<String, dynamic>();
    final dates = json['dates'] is List ? json['dates'] as List : const [];

    return NepaliCalendarMonth(
      year: _int(json['year']),
      month: _int(json['month']),
      monthName: '${json['month_name'] ?? ''}',
      monthNameEn: '${json['month_name_en'] ?? ''}',
      totalDays: _int(info['total_days']),
      startingWeekday: _int(start['number']),
      endingWeekday: _int(end['number']),
      nextMonth: _int(info['next_month']),
      nextYear: _int(info['next_year']),
      previousMonth: _int(info['prev_month']),
      previousYear: _int(info['prev_year']),
      dates: dates
          .map(
            (e) =>
                NepaliCalendarDay.fromJson((e as Map).cast<String, dynamic>()),
          )
          .toList(),
    );
  }

  static int _int(dynamic value) => int.parse(value.toString());
}
