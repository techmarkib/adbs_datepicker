enum SelectionType { date, month, year }

class NepaliDateValue {
  final String bsDate;
  final String adDate;
  final String? bsEndDate;
  final String? adEndDate;
  final String? time;
  final SelectionType selectionType;

  const NepaliDateValue({
    required this.bsDate,
    required this.adDate,
    this.bsEndDate,
    this.adEndDate,
    this.time,
    this.selectionType = SelectionType.date,
  });

  bool get isRange => bsEndDate != null && adEndDate != null;

  Map<String, dynamic> toJson() => {
        'bsDate': bsDate,
        'adDate': adDate,
        if (bsEndDate != null) 'bsEndDate': bsEndDate,
        if (adEndDate != null) 'adEndDate': adEndDate,
        if (time != null) 'time': time,
        'selectionType': selectionType.name,
      };

  @override
  String toString() =>
      'BS: $bsDate${bsEndDate != null ? ' → $bsEndDate' : ''} | '
      'AD: $adDate${adEndDate != null ? ' → $adEndDate' : ''} | '
      'Time: ${time ?? '-'} | Type: ${selectionType.name}';
}
