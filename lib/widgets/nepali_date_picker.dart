import 'package:flutter/material.dart';

import '../models/nepali_calendar_day.dart';
import '../models/nepali_calendar_month.dart';
import '../models/nepali_date_value.dart';
import '../services/ad_to_bs_service.dart';
import '../services/nepali_date_service.dart';

/// Calendar shown inside the dialog — Bikram Sambat or Gregorian (AD).
enum CalendarMode { bs, ad }

/// What the field shows, and which calendar the dialog opens on.
/// (The user can always switch BS ⇄ AD inside the dialog.)
///
/// * [bs]       → `2083-06-14`               opens on BS
/// * [bsWithAd] → `2083-06-14 (2026-10-01)`  opens on BS
/// * [ad]       → `2026-10-01`               opens on AD
/// * [adWithBs] → `2026-10-01 (2083-06-14)`  opens on AD
enum NepaliDateDisplayFormat {
  bs(CalendarMode.bs),
  bsWithAd(CalendarMode.bs),
  ad(CalendarMode.ad),
  adWithBs(CalendarMode.ad);

  const NepaliDateDisplayFormat(this.calendarMode);

  /// Calendar the dialog opens on.
  final CalendarMode calendarMode;

  String format(String bs, String ad) {
    switch (this) {
      case NepaliDateDisplayFormat.bs:
        return bs;
      case NepaliDateDisplayFormat.ad:
        return ad;
      case NepaliDateDisplayFormat.adWithBs:
        return '$ad ($bs)';
      case NepaliDateDisplayFormat.bsWithAd:
        return '$bs ($ad)';
    }
  }
}

/// Visual style of the field that opens the calendar.
enum NepaliDatePickerStyle {
  standard,
  filled,
  outlined,
  compact,
  card,
  listTile,
  minimal,
}

/// Builds a completely custom trigger.
typedef NepaliDateTriggerBuilder = Widget Function(
  BuildContext context,
  String? displayText,
  VoidCallback open,
);

/// Internal dialog view: day grid, month grid, or year grid.
enum _DialogView { day, month, year }

class NepaliDatePicker extends StatefulWidget {
  /// Initial BS date, e.g. `2083-06-14`.
  final String? initialBsDate;

  /// Initial AD date (used for AD formats; converted to BS via API).
  final DateTime? initialAdDate;

  final bool enableTime;
  final String timeFormat;
  final bool enableRange;
  final ValueChanged<NepaliDateValue> onChanged;
  final String label;
  final String hint;
  final DateTime? firstAdDate;
  final DateTime? lastAdDate;

  /// BS month service (BS calendar).
  final NepaliDateService? service;

  /// AD → BS converter (used when a day is picked on the AD calendar).
  final AdToBsService? adService;

  final NepaliDateDisplayFormat displayFormat;
  final NepaliDatePickerStyle style;
  final IconData? icon;
  final NepaliDateTriggerBuilder? triggerBuilder;

  /// Show the BS / AD switch inside the dialog.
  final bool showModeToggle;

  /// BS calendar only: show the matching AD day as small text at the
  /// bottom-right of each cell. (The AD calendar stays a plain AD calendar.)
  final bool showSecondaryDay;

  const NepaliDatePicker({
    super.key,
    this.initialBsDate,
    this.initialAdDate,
    this.enableTime = false,
    this.timeFormat = '12',
    this.enableRange = false,
    required this.onChanged,
    this.label = 'Date',
    this.hint = 'Select date',
    this.firstAdDate,
    this.lastAdDate,
    this.service,
    this.adService,
    this.displayFormat = NepaliDateDisplayFormat.bsWithAd,
    this.style = NepaliDatePickerStyle.standard,
    this.icon,
    this.triggerBuilder,
    this.showModeToggle = true,
    this.showSecondaryDay = true,
  }) : assert(timeFormat == '12' || timeFormat == '24');

  @override
  State<NepaliDatePicker> createState() => _NepaliDatePickerState();
}

class _NepaliDatePickerState extends State<NepaliDatePicker> {
  late final NepaliDateService _service;
  late final AdToBsService _adService;
  bool _serviceOwned = false;
  bool _adServiceOwned = false;

  // Unified selection (YYYY-MM-DD strings).
  String? _selectedBs;
  String? _selectedAd;
  String? _selectedBsEnd;
  String? _selectedAdEnd;
  TimeOfDay? _selectedTime;
  TimeOfDay? _selectedEndTime;
  bool _converting = false;

  // BS calendar state
  NepaliCalendarMonth? _calendar;
  int _year = 2083;
  int _month = 6;
  bool _loading = false;
  String? _error;

  // AD calendar state (purely local)
  late int _adYear;
  late int _adMonth;

  // Shared dialog state
  late CalendarMode _mode;
  _DialogView _view = _DialogView.day;
  int _viewingYear = 2083;
  int _yearRangeStart = 2076;

  /// Refreshes the currently open calendar dialog.
  ///
  /// This callback is cleared as soon as the dialog closes so async
  /// calendar requests cannot update an already-disposed dialog.
  VoidCallback? _dialogRefresh;
  bool _dialogOpen = false;

  /// Context of the open dialog route.
  ///
  /// `showDialog` pushes onto the ROOT navigator, while this widget's own
  /// [context] may belong to a nested navigator (go_router ShellRoute).
  /// Popping with this context always closes the dialog itself instead of
  /// accidentally popping the host screen.
  BuildContext? _dialogContext;

  static const _weekdayNepaliNames = [
    'आइत',
    'सोम',
    'मंगल',
    'बुध',
    'बिहि',
    'शुक्र',
    'शनि',
  ];
  static const _weekdayEnglishNames = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];
  static const _nepaliMonths = [
    'बैशाख',
    'जेठ',
    'असार',
    'श्रावण',
    'भाद्र',
    'असोज',
    'कार्तिक',
    'मंसिर',
    'पौष',
    'माघ',
    'फाल्गुन',
    'चैत्र',
  ];
  static const _englishMonths = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  static const _nepaliDigits = [
    '०',
    '१',
    '२',
    '३',
    '४',
    '५',
    '६',
    '७',
    '८',
    '९',
  ];

  // ── Lifecycle ───────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? NepaliDateService();
    _serviceOwned = widget.service == null;
    _adService = widget.adService ?? AdToBsService();
    _adServiceOwned = widget.adService == null;

    _mode = widget.displayFormat.calendarMode;
    final n = widget.initialAdDate ?? DateTime.now();
    _adYear = n.year;
    _adMonth = n.month;

    _bootstrap();
  }

  @override
  void dispose() {
    _dialogOpen = false;
    _dialogRefresh = null;
    _dialogContext = null;

    if (_serviceOwned) {
      _service.dispose();
    }

    if (_adServiceOwned) {
      _adService.dispose();
    }

    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (_mode == CalendarMode.bs) {
      await _bootstrapBs(selectToday: true);
      return;
    }
    // AD formats: BS calendar is loaded lazily when the user switches to it.
    final ad = widget.initialAdDate;
    if (ad != null) {
      await _convertAndSelect(ad, announce: false);
    } else if (widget.initialBsDate != null) {
      await _bootstrapBs(selectToday: false);
    }
  }

  List<int>? _parseBs(String? s) {
    if (s == null || !RegExp(r'^\d{4}-\d{1,2}-\d{1,2}$').hasMatch(s)) {
      return null;
    }
    return s.split('-').map(int.parse).toList();
  }

  /// Loads the BS month to display (selected → initial → today).
  Future<void> _bootstrapBs({
    required bool selectToday,
    VoidCallback? refresh,
  }) async {
    if (!mounted) return;

    _loading = true;
    _error = null;

    var pos = _parseBs(_selectedBs) ?? _parseBs(widget.initialBsDate);

    if (pos == null) {
      try {
        final today = await _service.getToday();

        if (!mounted) return;

        pos = [
          today.bsYear,
          today.bsMonth,
        ];

        if (selectToday && _selectedBs == null) {
          setState(() {
            _selectedBs = today.bsDate;
            _selectedAd = today.adDate;
          });
        }
      } catch (_) {
        if (!mounted) return;

        pos = [2083, 6];
      }
    }

    if (!mounted) return;

    setState(() {
      _year = pos![0];
      _month = pos[1];
      _viewingYear = _year;
      _yearRangeStart = (_year ~/ 12) * 12;
    });

    if (!mounted) return;

    await _loadMonth(refresh);
  }

  // ── BS data loading ─────────────────────────────────────────────────

  Future<void> _loadMonth([VoidCallback? refreshDialog]) async {
    void refreshDialogSafely() {
      if (!_dialogOpen || !mounted) return;

      refreshDialog?.call();
    }

    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    refreshDialogSafely();

    try {
      final month = await _service.getMonth(
        year: _year,
        month: _month,
      );

      // The date picker may have been removed while the API was loading.
      if (!mounted) return;

      setState(() {
        _calendar = month;
      });

      refreshDialogSafely();

      if (!mounted) return;

      _selectInitialDayIfNeeded();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
      });

      refreshDialogSafely();
    } finally {
      // No `return` inside finally (it can swallow exceptions).
      if (mounted) {
        setState(() {
          _loading = false;
        });

        refreshDialogSafely();
      }
    }
  }

  void _selectInitialDayIfNeeded() {
    if (!mounted) return;

    if (_selectedBs != null || widget.initialBsDate == null) {
      return;
    }

    final match = _calendar?.dates
        .where(
          (d) => d.bsDate == widget.initialBsDate,
        )
        .firstOrNull;

    if (match == null || !mounted) return;

    setState(() {
      _selectedBs = match.bsDate;
      _selectedAd = match.adDate;
    });
  }

  void _goToMonth(int year, int month, VoidCallback refreshDialog) {
    setState(() {
      _year = year;
      _month = month;
      _calendar = null;
    });
    refreshDialog();
    _loadMonth(refreshDialog);
  }

  // ── AD → BS conversion ──────────────────────────────────────────────

  Future<void> _convertAndSelect(
    DateTime ad, {
    required bool announce,
    VoidCallback? refresh,
  }) async {
    if (!mounted) return;

    setState(() {
      _converting = true;
    });

    refresh?.call();

    try {
      final r = await _adService.convert(ad);

      if (!mounted) return;

      setState(() {
        _selectedBs = r.bsDate;
        _selectedAd = r.adDate;
      });

      refresh?.call();

      if (!mounted) return;

      if (announce) {
        _emit();
      }

      if (widget.enableTime) {
        // Stay open — the user must pick a time before the dialog closes.
        refresh?.call();
      } else {
        _closeDialog();
      }
    } catch (e) {
      if (!mounted) return;

      if (announce) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text(
              'Could not convert date: $e',
            ),
          ),
        );
      }
    } finally {
      // No `return` inside finally (it can swallow exceptions).
      if (mounted) {
        setState(() {
          _converting = false;
        });

        refresh?.call();
      }
    }
  }

  // ── Dialog ──────────────────────────────────────────────────────────

  Future<void> _openCalendar() async {
    if (!mounted || _converting) return;

    _mode = widget.displayFormat.calendarMode;
    _view = _DialogView.day;

    _syncPosition(_mode);

    _dialogOpen = true;

    if (_mode == CalendarMode.bs && _calendar == null && !_loading) {
      _bootstrapBs(selectToday: false);
    }

    bool dialogMounted = true;

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogCtx) {
          // Remember the dialog's own context so we can close the correct
          // route later, whichever navigator it was pushed on.
          _dialogContext = dialogCtx;

          return Dialog(
            insetPadding: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 400,
                maxHeight: widget.enableTime ? 640 : 560,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: StatefulBuilder(
                  builder: (dialogContext, setDialogState) {
                    if (!dialogMounted) {
                      return const SizedBox.shrink();
                    }

                    _dialogRefresh = () {
                      if (!dialogMounted) return;
                      if (!_dialogOpen) return;
                      if (!mounted) return;

                      setDialogState(() {});
                    };

                    return _dialogContent(_dialogRefresh!);
                  },
                ),
              ),
            ),
          );
        },
      );
    } finally {
      // Prevent any pending async operation from refreshing
      // the already-closed dialog.
      dialogMounted = false;
      _dialogOpen = false;
      _dialogRefresh = null;
      _dialogContext = null;
    }
  }

  /// Closes the calendar dialog using the dialog's own context.
  void _closeDialog() {
    final ctx = _dialogContext;
    if (ctx != null && ctx.mounted) {
      Navigator.of(ctx).pop();
    }
  }

  /// Moves the target calendar to the month of the current selection.
  void _syncPosition(CalendarMode target) {
    if (target == CalendarMode.ad) {
      final ad = _selectedAd != null ? DateTime.tryParse(_selectedAd!) : null;
      if (ad != null) {
        _adYear = ad.year;
        _adMonth = ad.month;
      } else {
        final cal = _calendar;
        if (cal != null && cal.dates.isNotEmpty) {
          final d = cal.dates[cal.dates.length ~/ 2];
          _adYear = d.adYear;
          _adMonth = d.adMonth;
        }
      }
    }
  }

  void _switchMode(CalendarMode mode, VoidCallback refresh) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _view = _DialogView.day;
    });

    if (mode == CalendarMode.ad) {
      _syncPosition(CalendarMode.ad);
    } else if (_calendar == null && !_loading) {
      _bootstrapBs(
        selectToday: false,
        refresh: refresh,
      );
    } else {
      final bs = _parseBs(_selectedBs);

      if (bs != null && (bs[0] != _year || bs[1] != _month)) {
        _goToMonth(
          bs[0],
          bs[1],
          refresh,
        );
      }
    }

    refresh();
  }

  Future<void> _selectTime(VoidCallback? refresh, {bool end = false}) async {
    if (!mounted) return;

    final current = end ? _selectedEndTime : _selectedTime;
    final picked = await showTimePicker(
      // Use the dialog's context so the picker appears above the dialog
      // even when the host screen lives on a nested navigator.
      context: _dialogContext ?? context,
      initialTime: current ?? TimeOfDay.now(),
    );

    if (!mounted || picked == null) return;

    setState(() {
      if (end) {
        _selectedEndTime = picked;
      } else {
        _selectedTime = picked;
      }
    });

    refresh?.call();

    if (!mounted) return;

    _emit();

    // Time confirmed → close the dialog automatically. In range+time mode
    // wait until the end time is chosen before closing.
    if (widget.enableTime &&
        !(widget.enableRange && !end && _selectedEndTime == null)) {
      _closeDialog();
    }
  }

  // ── Selection ───────────────────────────────────────────────────────

  void _selectBsDay(NepaliCalendarDay day) {
    if (_isBsDisabled(day)) return;

    if (widget.enableRange) {
      _selectBsRangeDay(day);
      return;
    }

    setState(() {
      _selectedBs = day.bsDate;
      _selectedAd = day.adDate;
    });
    _emit();
    if (widget.enableTime) {
      _dialogRefresh?.call();
    } else {
      _closeDialog();
    }
  }

  /// Range mode: first tap sets the start, second tap sets the end.
  /// Tapping again (after a complete range) starts over.
  void _selectBsRangeDay(NepaliCalendarDay day) {
    setState(() {
      if (_selectedBs == null || _selectedBsEnd != null) {
        _selectedBs = day.bsDate;
        _selectedAd = day.adDate;
        _selectedBsEnd = null;
        _selectedAdEnd = null;
      } else if (day.adDateTime.isBefore(DateTime.parse(_selectedAd!))) {
        // Tapped before the start → restart with this day.
        _selectedBs = day.bsDate;
        _selectedAd = day.adDate;
        _selectedBsEnd = null;
        _selectedAdEnd = null;
      } else {
        _selectedBsEnd = day.bsDate;
        _selectedAdEnd = day.adDate;
      }
    });

    if (_selectedBsEnd != null) {
      _emit();
      if (widget.enableTime) {
        _dialogRefresh?.call();
      } else {
        _closeDialog();
      }
    } else {
      _dialogRefresh?.call();
    }
  }

  /// AD day tapped → resolve BS through the API.
  void _selectAdDay(DateTime date) {
    if (_isAdDisabled(date)) return;

    if (widget.enableRange) {
      _selectAdRangeDay(date);
      return;
    }

    _convertAndSelect(
      date,
      announce: true,
      refresh: widget.enableTime ? _dialogRefresh : null,
    );
  }

  void _selectAdRangeDay(DateTime date) {
    if (_selectedAd == null || _selectedAdEnd != null) {
      setState(() {
        _selectedAd = _dateOnly(date).toIso8601String().substring(0, 10);
        _selectedAdEnd = null;
        _selectedBs = null; // filled after conversion
        _selectedBsEnd = null;
      });
      _dialogRefresh?.call();
      _convertStartOnly(date);
      return;
    }

    final start = DateTime.parse(_selectedAd!);
    if (_dateOnly(date).isBefore(start)) {
      setState(() {
        _selectedAd = _dateOnly(date).toIso8601String().substring(0, 10);
        _selectedAdEnd = null;
        _selectedBs = null;
        _selectedBsEnd = null;
      });
      _dialogRefresh?.call();
      _convertStartOnly(date);
      return;
    }

    setState(() {
      _selectedAdEnd = _dateOnly(date).toIso8601String().substring(0, 10);
    });
    _dialogRefresh?.call();
    _convertRangeAndEmit();
  }

  Future<void> _convertStartOnly(DateTime ad) async {
    try {
      final r = await _adService.convert(ad);
      if (!mounted) return;
      setState(() {
        _selectedBs = r.bsDate;
        _selectedAd = r.adDate;
      });
      _dialogRefresh?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text('Could not convert date: $e')),
      );
    }
  }

  Future<void> _convertRangeAndEmit() async {
    final end = _selectedAdEnd != null ? DateTime.parse(_selectedAdEnd!) : null;
    if (end == null) return;

    setState(() => _converting = true);
    _dialogRefresh?.call();

    try {
      final r = await _adService.convert(end);
      if (!mounted) return;
      setState(() {
        _selectedBsEnd = r.bsDate;
        _selectedAdEnd = r.adDate;
      });
      _emit();
      if (widget.enableTime) {
        _dialogRefresh?.call();
      } else {
        _closeDialog();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text('Could not convert date: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _converting = false);
        _dialogRefresh?.call();
      }
    }
  }

  void _selectBsMonth(int month, VoidCallback refreshDialog) {
    setState(() {
      _month = month;
      _view = _DialogView.day;
      _calendar = null;
    });
    refreshDialog();
    _loadMonth(refreshDialog);
  }

  void _selectBsYear(int year, VoidCallback refreshDialog) {
    setState(() {
      _year = year;
      _viewingYear = year;
      _month = 1;
      _view = _DialogView.month;
      _calendar = null;
    });
    refreshDialog();
    _loadMonth(refreshDialog);
  }

  void _emit() {
    final bs = _selectedBs;
    final ad = _selectedAd;
    if (bs == null || ad == null) return;
    widget.onChanged(
      NepaliDateValue(
        bsDate: bs,
        adDate: ad,
        bsEndDate: widget.enableRange ? _selectedBsEnd : null,
        adEndDate: widget.enableRange ? _selectedAdEnd : null,
        time: _selectedTime == null ? null : _formatTime(_selectedTime!),
        endTime: widget.enableRange && _selectedEndTime != null
            ? _formatTime(_selectedEndTime!)
            : null,
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────

  bool _isBsDisabled(NepaliCalendarDay day) => _isAdDisabled(day.adDateTime);

  bool _isAdDisabled(DateTime d) {
    final date = _dateOnly(d);
    if (widget.firstAdDate != null &&
        date.isBefore(_dateOnly(widget.firstAdDate!))) {
      return true;
    }
    if (widget.lastAdDate != null &&
        date.isAfter(_dateOnly(widget.lastAdDate!))) {
      return true;
    }
    return false;
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  String _pad(int n, [int w = 2]) => n.toString().padLeft(w, '0');

  String _formatTime(TimeOfDay t) {
    if (widget.timeFormat == '24') {
      return '${_pad(t.hour)}:${_pad(t.minute)}';
    }
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final p = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:${_pad(t.minute)} $p';
  }

  String _toNepali(int n) {
    return n.toString().split('').map((c) {
      final i = int.tryParse(c);
      return i != null ? _nepaliDigits[i] : c;
    }).join();
  }

  String _yearText(int y) => _mode == CalendarMode.bs ? _toNepali(y) : '$y';

  /// Text shown in the trigger, or null when nothing is selected.
  String? get _displayText {
    if (_converting) return 'Converting…';
    final bs = _selectedBs;
    final ad = _selectedAd;
    if (bs == null || ad == null) return null;
    final time = _selectedTime;
    String fmt(String bs, String ad) => widget.displayFormat.format(bs, ad);

    String date = fmt(bs, ad);
    if (widget.enableRange &&
        _selectedBsEnd != null &&
        _selectedAdEnd != null) {
      date = '$date  →  ${fmt(_selectedBsEnd!, _selectedAdEnd!)}';
    }

    if (time == null || !widget.enableTime) return date;
    var result = '$date  •  ${_formatTime(time)}';
    if (widget.enableRange && _selectedEndTime != null) {
      result = '$result – ${_formatTime(_selectedEndTime!)}';
    }
    return result;
  }

  // ── Trigger UI ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return _trigger();
  }

  Widget _trigger() {
    final text = _displayText;

    if (widget.triggerBuilder != null) {
      return widget.triggerBuilder!(context, text, _openCalendar);
    }

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final shown = text ?? widget.hint;
    final muted = text == null ? cs.onSurfaceVariant : null;

    switch (widget.style) {
      case NepaliDatePickerStyle.standard:
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _openCalendar,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: widget.label,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: Icon(widget.icon ?? Icons.calendar_month),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            child: Text(shown, style: TextStyle(color: muted)),
          ),
        );

      case NepaliDatePickerStyle.filled:
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _openCalendar,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: widget.label,
              filled: true,
              fillColor: cs.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixIcon: Icon(widget.icon ?? Icons.calendar_month),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            child: Text(shown, style: TextStyle(color: muted)),
          ),
        );

      case NepaliDatePickerStyle.outlined:
        return InkWell(
          onTap: _openCalendar,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(color: cs.outline),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(widget.icon ?? Icons.event_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.label, style: theme.textTheme.labelMedium),
                      const SizedBox(height: 4),
                      Text(shown, style: TextStyle(color: muted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

      case NepaliDatePickerStyle.compact:
        return Align(
          alignment: Alignment.centerLeft,
          child: InkWell(
            onTap: _openCalendar,
            borderRadius: BorderRadius.circular(50),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: cs.secondaryContainer,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon ?? Icons.calendar_today, size: 18),
                  const SizedBox(width: 8),
                  Text(shown),
                ],
              ),
            ),
          ),
        );

      case NepaliDatePickerStyle.card:
        return Card(
          margin: EdgeInsets.zero,
          elevation: 1,
          child: InkWell(
            onTap: _openCalendar,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      widget.icon ?? Icons.event,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.label, style: theme.textTheme.labelMedium),
                        const SizedBox(height: 4),
                        Text(
                          shown,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        );

      case NepaliDatePickerStyle.listTile:
        return Material(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          child: ListTile(
            onTap: _openCalendar,
            leading: Icon(widget.icon ?? Icons.calendar_month_outlined),
            title: Text(widget.label),
            subtitle: Text(shown),
            trailing: const Icon(Icons.chevron_right),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

      case NepaliDatePickerStyle.minimal:
        return InkWell(
          onTap: _openCalendar,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.label, style: theme.textTheme.labelLarge),
                      const SizedBox(height: 5),
                      Text(
                        shown,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(widget.icon ?? Icons.calendar_today_outlined),
              ],
            ),
          ),
        );
    }
  }

  // ── Dialog body ─────────────────────────────────────────────────────

  /// Full dialog content: calendar plus, when [enableTime] is on, a time
  /// picker row and a confirm button.
  Widget _dialogContent(VoidCallback refresh) {
    if (!widget.enableTime) return _calendarBody(refresh);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: _calendarBody(refresh)),
        const SizedBox(height: 16),
        if (widget.enableRange)
          Row(
            children: [
              Expanded(child: _timeField(refresh, end: false)),
              const SizedBox(width: 12),
              Expanded(child: _timeField(refresh, end: true)),
            ],
          )
        else
          _timeField(refresh),
      ],
    );
  }

  /// Time field shown inside the dialog, styled like the date trigger.
  Widget _timeField(VoidCallback refresh, {bool end = false}) {
    final selected = end ? _selectedEndTime : _selectedTime;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _selectTime(refresh, end: end),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: widget.enableRange
              ? (end ? 'End time' : 'Start time')
              : 'Time',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          suffixIcon: const Icon(Icons.access_time),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        child: Text(
          selected == null ? 'Select time' : _formatTime(selected),
        ),
      ),
    );
  }

  Widget _calendarBody(VoidCallback refresh) {
    // BS needs network; AD is local so it never loads / errors.
    if (_mode == CalendarMode.bs) {
      if (_loading) {
        return _statusBody(refresh, const CircularProgressIndicator());
      }
      if (_error != null) {
        return _statusBody(
          refresh,
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 40),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _loadMonth(refresh),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        );
      }
    }

    switch (_view) {
      case _DialogView.day:
        return _dayView(refresh);
      case _DialogView.month:
        return _monthView(refresh);
      case _DialogView.year:
        return _yearView(refresh);
    }
  }

  /// Loading / error body that keeps the BS ⇄ AD switch reachable.
  Widget _statusBody(VoidCallback refresh, Widget child) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showModeToggle)
          Align(alignment: Alignment.centerRight, child: _modeToggle(refresh)),
        SizedBox(height: 320, child: Center(child: child)),
      ],
    );
  }

  // ── Day view (shared layout for BS and AD) ──────────────────────────

  Widget _dayView(VoidCallback refresh) {
    if (_mode == CalendarMode.ad) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _header(
            title: '${_englishMonths[_adMonth - 1]} $_adYear',
            onPrev: () => _stepAdMonth(-1, refresh),
            onNext: () => _stepAdMonth(1, refresh),
            onTitleTap: () {
              setState(() {
                _viewingYear = _adYear;
                _view = _DialogView.month;
              });
              refresh();
            },
            refresh: refresh,
          ),
          const SizedBox(height: 12),
          _weekHeader(),
          const SizedBox(height: 8),
          _adDaysGrid(),
        ],
      );
    }

    final cal = _calendar;
    if (cal == null) return const SizedBox(height: 320);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _header(
          title: '${cal.monthName} ${_toNepali(cal.year)}',
          onPrev: () =>
              _goToMonth(cal.previousYear, cal.previousMonth, refresh),
          onNext: () => _goToMonth(cal.nextYear, cal.nextMonth, refresh),
          onTitleTap: () {
            setState(() {
              _viewingYear = cal.year;
              _view = _DialogView.month;
            });
            refresh();
          },
          refresh: refresh,
        ),
        const SizedBox(height: 12),
        _weekHeader(),
        const SizedBox(height: 8),
        _bsDaysGrid(cal),
      ],
    );
  }

  void _stepAdMonth(int delta, VoidCallback refresh) {
    setState(() {
      final d = DateTime(_adYear, _adMonth + delta, 1);
      _adYear = d.year;
      _adMonth = d.month;
    });
    refresh();
  }

  Widget _header({
    required String title,
    required VoidCallback onPrev,
    required VoidCallback onNext,
    required VoidCallback onTitleTap,
    required VoidCallback refresh,
  }) {
    return Row(
      children: [
        IconButton(icon: const Icon(Icons.chevron_left), onPressed: onPrev),
        Expanded(
          child: Center(
            child: GestureDetector(
              onTap: onTitleTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
        IconButton(icon: const Icon(Icons.chevron_right), onPressed: onNext),
        if (widget.showModeToggle) ...[
          const SizedBox(width: 4),
          _modeToggle(refresh),
        ],
      ],
    );
  }

  Widget _gridOf(int leading, List<Widget> days) {
    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1,
      children: [for (var i = 0; i < leading; i++) const SizedBox(), ...days],
    );
  }

  /// API `starting_weekday.number` is ISO-style (1 = Mon … 7 = Sun).
  /// Week header is Sunday-first, so leading empty cells = number % 7.
  Widget _bsDaysGrid(NepaliCalendarMonth cal) {
    return _gridOf(cal.startingWeekday % 7, cal.dates.map(_bsDayCell).toList());
  }

  /// Plain Gregorian month, computed locally.
  Widget _adDaysGrid() {
    final leading = DateTime(_adYear, _adMonth, 1).weekday % 7;
    final count = DateUtils.getDaysInMonth(_adYear, _adMonth);
    final now = DateTime.now();

    return _gridOf(
      leading,
      List.generate(count, (i) {
        final date = DateTime(_adYear, _adMonth, i + 1);
        final iso =
            '${_pad(date.year, 4)}-${_pad(date.month)}-${_pad(date.day)}';
        final rangeEnd = _selectedAdEnd;
        return _dayTile(
          primary: '${date.day}',
          selected: _selectedAd == iso || rangeEnd == iso,
          today: date.year == now.year &&
              date.month == now.month &&
              date.day == now.day,
          disabled: _isAdDisabled(date),
          isRedDay: date.weekday == DateTime.saturday,
          bold: false,
          inRange: _isInRange(date),
          onTap: () => _selectAdDay(date),
        );
      }),
    );
  }

  bool _isInRange(DateTime date) {
    if (!widget.enableRange ||
        _selectedAd == null ||
        _selectedAdEnd == null) {
      return false;
    }
    final d = _dateOnly(date);
    final s = _dateOnly(DateTime.parse(_selectedAd!));
    final e = _dateOnly(DateTime.parse(_selectedAdEnd!));
    return d.isAfter(s) && d.isBefore(e);
  }

  Widget _bsDayCell(NepaliCalendarDay day) {
    final disabled = _isBsDisabled(day);
    final isHoliday = day.isNationalHoliday;

    return _dayTile(
      primary: day.unicodeBsDay ?? _toNepali(day.bsDay),
      secondary: widget.showSecondaryDay ? '${day.adDay}' : null,
      selected: _selectedBs == day.bsDate ||
          (widget.enableRange && _selectedBsEnd == day.bsDate),
      today: day.today,
      disabled: disabled,
      isRedDay: day.adDateTime.weekday == DateTime.saturday || isHoliday,
      bold: isHoliday,
      inRange: _isInRange(day.adDateTime),
      onTap: () => _selectBsDay(day),
      onLongPress:
          !disabled && day.hasEvents ? () => _showEventsSheet(day) : null,
    );
  }

  /// One day cell — identical size and look for BS and AD.
  /// [secondary] (BS calendar only) is a small AD day at the bottom-right.
  Widget _dayTile({
    required String primary,
    String? secondary,
    required bool selected,
    required bool today,
    required bool disabled,
    required bool isRedDay,
    required bool bold,
    bool inRange = false,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: disabled ? null : onTap,
      onLongPress: disabled ? null : onLongPress,
      customBorder: const CircleBorder(),
      child: Center(
        child: SizedBox(
          width: 46,
          height: 46,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? cs.primary
                      : inRange
                          ? cs.secondaryContainer
                          : null,
                  border: today && !selected
                      ? Border.all(color: cs.primary, width: 1.5)
                      : null,
                ),
                child: Text(
                  primary,
                  style: TextStyle(
                    color: disabled
                        ? cs.onSurface.withValues(alpha: 0.38)
                        : selected
                            ? cs.onPrimary
                            : isRedDay
                                ? cs.error
                                : null,
                    fontWeight: today || selected || bold
                        ? FontWeight.w600
                        : FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
              ),
              if (secondary != null)
                Positioned(
                  right: 1,
                  bottom: 1,
                  child: Text(
                    secondary,
                    style: TextStyle(
                      fontSize: 8,
                      height: 1,
                      fontWeight: FontWeight.w500,
                      color: disabled
                          ? cs.onSurface.withValues(alpha: 0.3)
                          : isRedDay
                              ? cs.error.withValues(alpha: 0.8)
                              : cs.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bottom sheet with events (long-press on a BS day).
  void _showEventsSheet(NepaliCalendarDay day) {
    final cs = Theme.of(context).colorScheme;
    final dateLabel = '${day.unicodeBsDay ?? _toNepali(day.bsDay)} '
        '${day.unicodeMonthName ?? day.monthName} '
        '${day.unicodeBsYear ?? _toNepali(day.bsYear)}';

    showModalBottomSheet<void>(
      // Use the dialog's context so the sheet is pushed on the same
      // (root) navigator as the dialog and appears above it, not behind.
      context: _dialogContext ?? context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  dateLabel,
                  style: Theme.of(ctx)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${day.bsDate}  •  ${day.adDate}',
                  style: Theme.of(ctx)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.45,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: day.events.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final e = day.events[i];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          e.nationalHoliday
                              ? Icons.flag_rounded
                              : Icons.event_rounded,
                          color: e.nationalHoliday ? cs.error : cs.primary,
                        ),
                        title: Text(
                          e.title.isNotEmpty ? e.title : e.titleEn,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: e.nationalHoliday ? cs.error : null,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (e.nationalHoliday)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'सार्वजनिक बिदा',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: cs.error,
                                  ),
                                ),
                              ),
                            if (e.description != null &&
                                e.description!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(e.description!),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    // Close the sheet with its own context, then select
                    // (which closes the dialog via _closeDialog).
                    Navigator.of(ctx).pop();
                    _selectBsDay(day);
                  },
                  child: const Text('Select this date'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Mode toggle ─────────────────────────────────────────────────────

  Widget _modeToggle(VoidCallback refresh) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _modeChip('BS', CalendarMode.bs, refresh),
          _modeChip('AD', CalendarMode.ad, refresh),
        ],
      ),
    );
  }

  Widget _modeChip(String label, CalendarMode mode, VoidCallback refresh) {
    final selected = _mode == mode;
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => _switchMode(mode, refresh),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? cs.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? cs.onPrimary : cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _weekHeader() {
    final cs = Theme.of(context).colorScheme;
    final weekdays =
        _mode == CalendarMode.bs ? _weekdayNepaliNames : _weekdayEnglishNames;

    return Row(
      children: List.generate(7, (i) {
        return Expanded(
          child: Center(
            child: Text(
              weekdays[i],
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: i == 6 ? cs.error : cs.onSurfaceVariant,
              ),
            ),
          ),
        );
      }),
    );
  }

  // ── Month view (shared) ─────────────────────────────────────────────

  Widget _monthView(VoidCallback refresh) {
    final cs = Theme.of(context).colorScheme;
    final isBs = _mode == CalendarMode.bs;
    final names = isBs ? _nepaliMonths : _englishMonths;
    final curYear = isBs ? _year : _adYear;
    final curMonth = isBs ? _month : _adMonth;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                setState(() => _viewingYear--);
                refresh();
              },
            ),
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _yearRangeStart = (_viewingYear ~/ 12) * 12;
                      _view = _DialogView.year;
                    });
                    refresh();
                  },
                  child: Text(
                    _yearText(_viewingYear),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                setState(() => _viewingYear++);
                refresh();
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: List.generate(12, (i) {
            final m = i + 1;
            final selected = curMonth == m && curYear == _viewingYear;
            return _gridChip(
              label: names[i],
              selected: selected,
              cs: cs,
              onTap: () {
                if (isBs) {
                  setState(() => _year = _viewingYear);
                  _selectBsMonth(m, refresh);
                } else {
                  setState(() {
                    _adYear = _viewingYear;
                    _adMonth = m;
                    _view = _DialogView.day;
                  });
                  refresh();
                }
              },
            );
          }),
        ),
      ],
    );
  }

  // ── Year view (shared) ──────────────────────────────────────────────

  Widget _yearView(VoidCallback refresh) {
    final cs = Theme.of(context).colorScheme;
    final isBs = _mode == CalendarMode.bs;
    final curYear = isBs ? _year : _adYear;
    final start = _yearRangeStart;
    final end = start + 11;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                setState(() => _yearRangeStart -= 12);
                refresh();
              },
            ),
            Expanded(
              child: Center(
                child: Text(
                  '${_yearText(start)} – ${_yearText(end)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                setState(() => _yearRangeStart += 12);
                refresh();
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: List.generate(12, (i) {
            final y = start + i;
            return _gridChip(
              label: _yearText(y),
              selected: curYear == y,
              cs: cs,
              onTap: () {
                if (isBs) {
                  _selectBsYear(y, refresh);
                } else {
                  setState(() {
                    _adYear = y;
                    _viewingYear = y;
                    _view = _DialogView.month;
                  });
                  refresh();
                }
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _gridChip({
    required String label,
    required bool selected,
    required ColorScheme cs,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selected ? cs.primary : null,
          border: Border.all(color: selected ? cs.primary : cs.outlineVariant),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? cs.onPrimary : null,
          ),
        ),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
