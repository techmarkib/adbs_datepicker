import 'package:adbs_datepicker/adbs_datepicker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('public API exports expected types', () {
    expect(
      CalendarMode.values,
      isNotEmpty,
    );

    expect(
      NepaliDateDisplayFormat.values,
      isNotEmpty,
    );

    expect(
      NepaliDatePickerStyle.values,
      isNotEmpty,
    );

    expect(
      SelectionType.values,
      isNotEmpty,
    );

    const value = NepaliDateValue(
      bsDate: '2083-06-14',
      adDate: '2026-10-01',
    );

    expect(
      value.bsDate,
      '2083-06-14',
    );

    expect(
      value.adDate,
      '2026-10-01',
    );
  });
}
