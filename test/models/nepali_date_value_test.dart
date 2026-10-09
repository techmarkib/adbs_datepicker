import 'package:adbs_datepicker/adbs_datepicker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NepaliDateValue', () {
    test('creates date value', () {
      const value = NepaliDateValue(
        bsDate: '2083-06-14',
        adDate: '2026-10-01',
      );

      expect(value.bsDate, '2083-06-14');
      expect(value.adDate, '2026-10-01');
      expect(value.time, isNull);
      expect(value.isRange, isFalse);
    });

    test('stores time', () {
      const value = NepaliDateValue(
        bsDate: '2083-06-14',
        adDate: '2026-10-01',
        time: '10:30 AM',
      );

      expect(value.time, '10:30 AM');
    });

    test('supports range values', () {
      const value = NepaliDateValue(
        bsDate: '2083-06-14',
        adDate: '2026-10-01',
        bsEndDate: '2083-06-20',
        adEndDate: '2026-10-07',
      );

      expect(value.isRange, isTrue);
      expect(value.bsEndDate, '2083-06-20');
      expect(value.adEndDate, '2026-10-07');
    });

    test('range requires both end dates', () {
      const value = NepaliDateValue(
        bsDate: '2083-06-14',
        adDate: '2026-10-01',
        bsEndDate: '2083-06-20',
      );

      expect(value.isRange, isFalse);
    });

    test('toJson excludes null fields', () {
      const value = NepaliDateValue(
        bsDate: '2083-06-14',
        adDate: '2026-10-01',
      );

      expect(
        value.toJson(),
        {
          'bsDate': '2083-06-14',
          'adDate': '2026-10-01',
        },
      );
    });

    test('toJson includes time and range when available', () {
      const value = NepaliDateValue(
        bsDate: '2083-06-14',
        adDate: '2026-10-01',
        bsEndDate: '2083-06-20',
        adEndDate: '2026-10-07',
        time: '10:30 AM',
        endTime: '6:45 PM',
      );

      expect(
        value.toJson(),
        {
          'bsDate': '2083-06-14',
          'adDate': '2026-10-01',
          'bsEndDate': '2083-06-20',
          'adEndDate': '2026-10-07',
          'time': '10:30 AM',
          'endTime': '6:45 PM',
        },
      );
    });

    test('toString returns readable value', () {
      const value = NepaliDateValue(
        bsDate: '2083-06-14',
        adDate: '2026-10-01',
      );

      expect(
        value.toString(),
        'BS: 2083-06-14 | AD: 2026-10-01 | Time: - ',
      );
    });

    test('toString includes range and time', () {
      const value = NepaliDateValue(
        bsDate: '2083-06-14',
        adDate: '2026-10-01',
        bsEndDate: '2083-06-20',
        adEndDate: '2026-10-07',
        time: '10:30 AM',
        endTime: '6:45 PM',
      );

      expect(
        value.toString(),
        'BS: 2083-06-14 → 2083-06-20 | '
        'AD: 2026-10-01 → 2026-10-07 | '
        'Time: 10:30 AM → 6:45 PM ',
      );
    });
  });
}
