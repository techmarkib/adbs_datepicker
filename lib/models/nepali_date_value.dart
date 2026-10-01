enum SelectionType { date, month, year }

class NepaliDateValue {
  final String bsDate;
  final String adDate;
  final String? time;
  final SelectionType selectionType;

  const NepaliDateValue({
    required this.bsDate,
    required this.adDate,
    this.time,
    this.selectionType = SelectionType.date,
  });

  Map<String, dynamic> toJson() => {
    'bsDate': bsDate,
    'adDate': adDate,
    if (time != null) 'time': time,
    'selectionType': selectionType.name,
  };

  @override
  String toString() =>
      'BS: $bsDate | AD: $adDate | Time: ${time ?? '-'} | Type: ${selectionType.name}';
}
