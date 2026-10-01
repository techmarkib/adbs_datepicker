import 'package:adbs_datepicker/adbs_datepicker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NepaliCalendarEvent', () {
    test('creates event from JSON', () {
      final event = NepaliCalendarEvent.fromJson({
        'id': 123,
        'title': 'दशैं',
        'title_en': 'Dashain',
        'national_holiday': 1,
        'description': 'National festival',
      });

      expect(event.id, 123);
      expect(event.title, 'दशैं');
      expect(event.titleEn, 'Dashain');
      expect(event.nationalHoliday, isTrue);
      expect(event.description, 'National festival');
    });

    test('accepts national_holiday as boolean true', () {
      final event = NepaliCalendarEvent.fromJson({
        'id': 1,
        'title': 'Holiday',
        'title_en': 'Holiday',
        'national_holiday': true,
      });

      expect(event.nationalHoliday, isTrue);
    });

    test('accepts national_holiday as string "1"', () {
      final event = NepaliCalendarEvent.fromJson({
        'id': 1,
        'title': 'Holiday',
        'title_en': 'Holiday',
        'national_holiday': '1',
      });

      expect(event.nationalHoliday, isTrue);
    });

    test('national_holiday is false for zero', () {
      final event = NepaliCalendarEvent.fromJson({
        'id': 1,
        'title': 'Event',
        'title_en': 'Event',
        'national_holiday': 0,
      });

      expect(event.nationalHoliday, isFalse);
    });

    test('missing optional description remains null', () {
      final event = NepaliCalendarEvent.fromJson({
        'id': 1,
        'title': 'Event',
        'title_en': 'Event',
      });

      expect(event.description, isNull);
    });

    test('missing values use the model defaults', () {
      final event = NepaliCalendarEvent.fromJson({});

      expect(event.id, 0);
      expect(event.title, '');
      expect(event.titleEn, '');
      expect(event.nationalHoliday, isFalse);
      expect(event.description, isNull);
    });
  });
}
