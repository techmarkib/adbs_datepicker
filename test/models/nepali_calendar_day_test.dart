import 'package:adbs_datepicker/adbs_datepicker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NepaliCalendarDay', () {
    test('parses basic date information', () {
      final day = NepaliCalendarDay.fromJson({
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
      });

      expect(day.bsYear, 2083);
      expect(day.bsMonth, 6);
      expect(day.bsDay, 14);

      expect(day.adYear, 2026);
      expect(day.adMonth, 10);
      expect(day.adDay, 1);

      expect(day.dateAd, '2026-10-01');
      expect(day.weekDay, 'Thursday');
      expect(day.monthName, 'असोज');
      expect(day.monthNameEn, 'Ashwin');
      expect(day.longFormat, '14 असोज 2083');

      expect(day.today, isTrue);
    });

    test('creates zero-padded BS date', () {
      const day = NepaliCalendarDay(
        bsYear: 2083,
        bsMonth: 6,
        bsDay: 4,
        adYear: 2026,
        adMonth: 9,
        adDay: 21,
        dateAd: '2026-09-21',
        weekDay: 'Monday',
        monthName: 'असोज',
        monthNameEn: 'Ashwin',
        longFormat: '4 असोज 2083',
      );

      expect(day.bsDate, '2083-06-04');
    });

    test('creates zero-padded AD date', () {
      const day = NepaliCalendarDay(
        bsYear: 2083,
        bsMonth: 6,
        bsDay: 4,
        adYear: 2026,
        adMonth: 9,
        adDay: 5,
        dateAd: '2026-09-05',
        weekDay: 'Saturday',
        monthName: 'असोज',
        monthNameEn: 'Ashwin',
        longFormat: '4 असोज 2083',
      );

      expect(day.adDate, '2026-09-05');
    });

    test('creates AD DateTime', () {
      const day = NepaliCalendarDay(
        bsYear: 2083,
        bsMonth: 6,
        bsDay: 4,
        adYear: 2026,
        adMonth: 9,
        adDay: 5,
        dateAd: '2026-09-05',
        weekDay: 'Saturday',
        monthName: 'असोज',
        monthNameEn: 'Ashwin',
        longFormat: '4 असोज 2083',
      );

      expect(day.adDateTime, DateTime(2026, 9, 5));
    });

    test('parses unicode fields', () {
      final day = NepaliCalendarDay.fromJson({
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
        'unicode': {
          'bs_y': '२०८३',
          'bs_m': '०६',
          'bs_d': '१४',
          'ad_y': '२०२६',
          'ad_m': '१०',
          'ad_d': '०१',
          'week_day': 'बिहिबार',
          'month_name': 'असोज',
          'long_format': '१४ असोज २०८३',
        },
      });

      expect(day.unicodeBsYear, '२०८३');
      expect(day.unicodeBsMonth, '०६');
      expect(day.unicodeBsDay, '१४');
      expect(day.unicodeAdYear, '२०२६');
      expect(day.unicodeAdMonth, '१०');
      expect(day.unicodeAdDay, '०१');
      expect(day.unicodeWeekDay, 'बिहिबार');
      expect(day.unicodeMonthName, 'असोज');
      expect(day.unicodeLongFormat, '१४ असोज २०८३');
    });

    test('parses events', () {
      final day = NepaliCalendarDay.fromJson({
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
        'events': [
          {
            'id': 10,
            'title': 'सार्वजनिक बिदा',
            'title_en': 'National Holiday',
            'national_holiday': 1,
          },
        ],
      });

      expect(day.events, hasLength(1));
      expect(day.hasEvents, isTrue);
      expect(day.isNationalHoliday, isTrue);
      expect(day.events.first.title, 'सार्वजनिक बिदा');
    });

    test('hasEvents is false when there are no events', () {
      const day = NepaliCalendarDay(
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
        longFormat: '14 असोज 2083',
      );

      expect(day.hasEvents, isFalse);
      expect(day.isNationalHoliday, isFalse);
    });
  });
}
