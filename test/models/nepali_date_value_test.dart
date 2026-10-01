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
      expect(value.selectionType, SelectionType.date);
    });

    test('stores time', () {
      const value = NepaliDateValue(
        bsDate: '2083-06-14',
        adDate: '2026-10-01',
        time: '10:30 AM',
      );

      expect(value.time, '10:30 AM');
    });

    test('supports month selection', () {
      const value = NepaliDateValue(
        bsDate: '2083-06',
        adDate: '2026-10',
        selectionType: SelectionType.month,
      );

      expect(value.selectionType, SelectionType.month);
    });

    test('supports year selection', () {
      const value = NepaliDateValue(
        bsDate: '2083',
        adDate: '2026',
        selectionType: SelectionType.year,
      );

      expect(value.selectionType, SelectionType.year);
    });

    test('toJson excludes null time', () {
      const value = NepaliDateValue(
        bsDate: '2083-06-14',
        adDate: '2026-10-01',
      );

      expect(
        value.toJson(),
        {
          'bsDate': '2083-06-14',
          'adDate': '2026-10-01',
          'selectionType': 'date',
        },
      );
    });

    test('toJson includes time when available', () {
      const value = NepaliDateValue(
        bsDate: '2083-06-14',
        adDate: '2026-10-01',
        time: '10:30 AM',
      );

      expect(
        value.toJson(),
        {
          'bsDate': '2083-06-14',
          'adDate': '2026-10-01',
          'time': '10:30 AM',
          'selectionType': 'date',
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
        'BS: 2083-06-14 | AD: 2026-10-01 | Time: - | Type: date',
      );
    });
  });
}
