class NepaliCalendarEvent {
  final int id;
  final String title;
  final String titleEn;
  final bool nationalHoliday;
  final String? description;

  const NepaliCalendarEvent({
    required this.id,
    required this.title,
    required this.titleEn,
    this.nationalHoliday = false,
    this.description,
  });

  factory NepaliCalendarEvent.fromJson(Map<String, dynamic> json) {
    return NepaliCalendarEvent(
      id: int.tryParse('${json['id'] ?? 0}') ?? 0,
      title: '${json['title'] ?? ''}',
      titleEn: '${json['title_en'] ?? ''}',
      nationalHoliday:
          json['national_holiday'] == 1 ||
          json['national_holiday'] == true ||
          '${json['national_holiday']}' == '1',
      description: json['description']?.toString(),
    );
  }
}
