import 'package:adbs_datepicker/adbs_datepicker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NepaliCalendarMonth', () {
    test('parses month information and dates', () {
      final month = NepaliCalendarMonth.fromJson({
        'year': 2083,
        'month': 6,
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
          'next_month': 7,
          'next_year': 2083,
          'prev_month': 5,
          'prev_year': 2083,
        },
        'dates': [
          {
            'bs_y': 2083,
            'bs_m': 6,
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
          {
            'bs_y': 2083,
            'bs_m': 6,
            'bs_d': 2,
            'ad_y': 2026,
            'ad_m': 9,
            'ad_d': 19,
            'date_ad': '2026-09-19',
            'week_day': 'Saturday',
            'month_name': 'असोज',
            'month_name_en': 'Ashwin',
            'long_format': '2 असोज 2083',
            'today': false,
            'events': [],
          },
        ],
      });

      expect(month.year, 2083);
      expect(month.month, 6);

      expect(month.monthName, 'असोज');
      expect(month.monthNameEn, 'Ashwin');

      expect(month.totalDays, 31);
      expect(month.startingWeekday, 3);
      expect(month.endingWeekday, 5);

      expect(month.nextMonth, 7);
      expect(month.nextYear, 2083);

      expect(month.previousMonth, 5);
      expect(month.previousYear, 2083);

      expect(month.dates, hasLength(2));

      expect(
        month.dates.first.bsDate,
        '2083-06-01',
      );

      expect(
        month.dates.last.bsDate,
        '2083-06-02',
      );
    });

    test('creates month directly', () {
      const month = NepaliCalendarMonth(
        year: 2083,
        month: 6,
        monthName: 'असोज',
        monthNameEn: 'Ashwin',
        totalDays: 31,
        startingWeekday: 3,
        endingWeekday: 5,
        nextMonth: 7,
        nextYear: 2083,
        previousMonth: 5,
        previousYear: 2083,
        dates: [],
      );

      expect(month.year, 2083);
      expect(month.month, 6);
      expect(month.monthName, 'असोज');
      expect(month.monthNameEn, 'Ashwin');

      expect(month.totalDays, 31);
      expect(month.startingWeekday, 3);
      expect(month.endingWeekday, 5);

      expect(month.nextMonth, 7);
      expect(month.nextYear, 2083);

      expect(month.previousMonth, 5);
      expect(month.previousYear, 2083);

      expect(month.dates, isEmpty);
    });

    test('supports month boundary from Chaitra to Baisakh', () {
      final month = NepaliCalendarMonth.fromJson({
        'year': 2082,
        'month': 12,
        'month_name': 'चैत्र',
        'month_name_en': 'Chaitra',
        'month_info': {
          'total_days': 30,
          'starting_weekday': {
            'number': 1,
          },
          'ending_weekday': {
            'number': 2,
          },
          'next_month': 1,
          'next_year': 2083,
          'prev_month': 11,
          'prev_year': 2082,
        },
        'dates': [],
      });

      expect(month.month, 12);
      expect(month.year, 2082);

      expect(month.nextMonth, 1);
      expect(month.nextYear, 2083);

      expect(month.previousMonth, 11);
      expect(month.previousYear, 2082);
    });

    test('supports month boundary from Baisakh to Chaitra', () {
      final month = NepaliCalendarMonth.fromJson({
        'year': 2083,
        'month': 1,
        'month_name': 'बैशाख',
        'month_name_en': 'Baisakh',
        'month_info': {
          'total_days': 31,
          'starting_weekday': {
            'number': 3,
          },
          'ending_weekday': {
            'number': 5,
          },
          'next_month': 2,
          'next_year': 2083,
          'prev_month': 12,
          'prev_year': 2082,
        },
        'dates': [],
      });

      expect(month.month, 1);
      expect(month.year, 2083);

      expect(month.nextMonth, 2);
      expect(month.nextYear, 2083);

      expect(month.previousMonth, 12);
      expect(month.previousYear, 2082);
    });
  });
}
