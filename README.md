# adbs_datepicker

A Flutter date picker for **Bikram Sambat (BS)** and **Gregorian (AD)** dates, with a built-in BS ⇄ AD switch, Nepali numerals, public holidays and events.

Pick a date in either calendar and always get **both** the BS and AD values back.

---

## Features

- **Two calendars in one dialog.** Switch between BS and AD at any time.
- **Both dates returned.** Every selection gives you `bsDate` and `adDate` in `YYYY-MM-DD` format.
- **Four display formats.** Show BS only, AD only, or either one with the other in brackets.
- **Seven trigger styles.** `standard`, `filled`, `outlined`, `compact`, `card`, `listTile` and `minimal`. You can also supply a fully custom trigger.
- **Nepali localisation.** Nepali month names, weekday names and Devanagari numerals on the BS calendar.
- **Holidays and events.** National holidays are highlighted in red, and a long-press on a day shows its events.
- **Secondary day.** The BS calendar can show the matching AD day in each cell.
- **Date range limits.** Restrict selection with `firstAdDate` and `lastAdDate`.
- **Optional time picker.** 12-hour or 24-hour format.
- **Month and year pickers.** Tap the title to jump to a month grid, then a year grid.
- **Month caching.** BS months are cached in memory (up to 24 months).
- **Injectable services.** Provide your own HTTP client or base URL, which is handy for testing and proxies.

---

## Installation

### From pub.dev

```yaml
dependencies:
  adbs_datepicker: ^1.0.0
```

### From GitHub

```yaml
dependencies:
  adbs_datepicker:
    git:
      url: https://github.com/your-username/adbs_datepicker.git
      ref: v1.0.0
```

Then run:

```bash
flutter pub get
```

**Requirements**

|         | Minimum |
| ------- | ------- |
| Flutter | 3.27    |
| Dart    | 3.0     |

### Platform setup

The BS calendar and AD→BS conversion call an online API, so the app needs internet access.

**Android**: add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

**macOS**: add to both `DebugProfile.entitlements` and `Release.entitlements`:

```xml
<key>com.apple.security.network.client</key>
<true/>
```

iOS, web, Windows and Linux need no extra setup. On web, the API server must allow CORS for your origin.

---

## Quick start

```dart
import 'package:adbs_datepicker/adbs_datepicker.dart';

NepaliDatePicker(
  label: 'Date of Birth',
  onChanged: (NepaliDateValue value) {
    print(value.bsDate); // 2083-06-14
    print(value.adDate); // 2026-10-01
  },
)
```

With every option:

```dart
NepaliDatePicker(
  label: 'Appointment',
  hint: 'Choose a date',
  displayFormat: NepaliDateDisplayFormat.bsWithAd,
  style: NepaliDatePickerStyle.filled,
  initialBsDate: '2083-06-14',
  firstAdDate: DateTime(2026, 1, 1),
  lastAdDate: DateTime(2027, 12, 31),
  enableTime: true,
  timeFormat: '12',
  showModeToggle: true,
  showSecondaryDay: true,
  onChanged: (value) => debugPrint(value.toString()),
)
```

---

## Display formats

`displayFormat` controls the text shown in the field **and** which calendar the dialog opens on. The user can still switch calendars inside the dialog.

| Format                                         | Field text                | Opens on |
| ---------------------------------------------- | ------------------------- | -------- |
| `NepaliDateDisplayFormat.bs`                   | `2083-06-14`              | BS       |
| `NepaliDateDisplayFormat.bsWithAd` _(default)_ | `2083-06-14 (2026-10-01)` | BS       |
| `NepaliDateDisplayFormat.ad`                   | `2026-10-01`              | AD       |
| `NepaliDateDisplayFormat.adWithBs`             | `2026-10-01 (2083-06-14)` | AD       |

Use `displayFormat.calendarMode` to read which calendar a format opens on.

---

## Trigger styles

```dart
NepaliDatePicker(
  style: NepaliDatePickerStyle.card,
  onChanged: (_) {},
)
```

| Style      | Description                                                          |
| ---------- | -------------------------------------------------------------------- |
| `standard` | Outlined text field with a calendar icon _(default)_                 |
| `filled`   | Filled text field with no border                                     |
| `outlined` | Bordered box with the icon on the left and the label above the value |
| `compact`  | Rounded pill, sized to its content                                   |
| `card`     | Elevated card with an icon badge and a chevron                       |
| `listTile` | A tinted `ListTile`                                                  |
| `minimal`  | Plain label and value, no border                                     |

Pass `icon:` to replace the default icon in any style.

### Fully custom trigger

Use `triggerBuilder` to draw your own trigger. It receives the current display text (`null` when nothing is selected) and a callback that opens the calendar:

```dart
NepaliDatePicker(
  onChanged: (v) => setState(() => _value = v),
  triggerBuilder: (context, displayText, open) {
    return ElevatedButton.icon(
      onPressed: open,
      icon: const Icon(Icons.event),
      label: Text(displayText ?? 'Pick a date'),
    );
  },
)
```

---

## Options

| Parameter          | Type                            | Default         | Description                                                                        |
| ------------------ | ------------------------------- | --------------- | ---------------------------------------------------------------------------------- |
| `onChanged`        | `ValueChanged<NepaliDateValue>` | **required**    | Called when the user picks a date, or changes the time.                            |
| `label`            | `String`                        | `'Date'`        | Field label.                                                                       |
| `hint`             | `String`                        | `'Select date'` | Text shown when nothing is selected.                                               |
| `initialBsDate`    | `String?`                       | `null`          | Initial BS date as `YYYY-MM-DD`.                                                   |
| `initialAdDate`    | `DateTime?`                     | `null`          | Initial AD date. Converted to BS through the API.                                  |
| `displayFormat`    | `NepaliDateDisplayFormat`       | `bsWithAd`      | Field text format and the calendar the dialog opens on.                            |
| `style`            | `NepaliDatePickerStyle`         | `standard`      | Look of the trigger.                                                               |
| `icon`             | `IconData?`                     | style default   | Trigger icon.                                                                      |
| `triggerBuilder`   | `NepaliDateTriggerBuilder?`     | `null`          | Fully custom trigger. Overrides `style`.                                           |
| `firstAdDate`      | `DateTime?`                     | `null`          | Earliest selectable date. Earlier days are disabled.                               |
| `lastAdDate`       | `DateTime?`                     | `null`          | Latest selectable date. Later days are disabled.                                   |
| `enableTime`       | `bool`                          | `false`         | Lets the user pick a time inside the same dialog; picking the time closes it.       |
| `timeFormat`       | `String`                        | `'12'`          | `'12'` (`10:30 AM`) or `'24'` (`22:30`). Anything else fails an assertion.         |
| `showModeToggle`   | `bool`                          | `true`          | Shows the BS / AD switch in the dialog.                                            |
| `showSecondaryDay` | `bool`                          | `true`          | BS calendar only. Shows the AD day in small text at the bottom-right of each cell. |
| `service`          | `NepaliDateService?`            | internal        | Custom BS month service.                                                           |
| `adService`        | `AdToBsService?`                | internal        | Custom AD→BS converter.                                                            |

Date limits are always expressed in **AD** (`firstAdDate` / `lastAdDate`), and they are applied to both calendars. A BS day is disabled when its AD equivalent falls outside the range.

---

## The returned value

`onChanged` gives you a `NepaliDateValue`:

```dart
class NepaliDateValue {
  final String bsDate;               // '2083-06-14'
  final String adDate;               // '2026-10-01'
  final String? time;                // '10:30 AM' or '22:30', null if unset
  final SelectionType selectionType; // always SelectionType.date for now
}
```

```dart
onChanged: (v) {
  print(v);          // BS: 2083-06-14 | AD: 2026-10-01 | Time: - | Type: date
  print(v.toJson()); // {bsDate: 2083-06-14, adDate: 2026-10-01, selectionType: date}
}
```

`toJson()` leaves out `time` when it is `null`.

Parse the strings back into dates if you need to:

```dart
final ad = DateTime.parse(value.adDate); // 2026-10-01 00:00:00.000
```

### Behaviour notes

- When the picker opens on BS and you don't give it an initial date, **today is selected and shown automatically**. `onChanged` is _not_ fired for this automatic selection, only for real user picks.
- With an AD format and no initial date, the field shows the `hint` until the user picks something.
- `onChanged` fires only after both a BS and an AD date are known. Picking a time before a date does not fire it.
- Picking a day on the **AD** calendar closes the dialog and converts it to BS through the API. The field shows `Converting…` while that request runs.

---

## Using the calendar

| Action                         | Result                                                               |
| ------------------------------ | -------------------------------------------------------------------- |
| Tap a day                      | Select it and close the dialog.                                      |
| Long-press a day with events   | Open a sheet listing its events, with a **Select this date** button. |
| Tap the month title            | Open the month grid.                                                 |
| Tap the year in the month grid | Open the year grid.                                                  |
| `‹` / `›`                      | Previous / next month, or year range in the grids.                   |
| **BS / AD** chips              | Switch calendar. The target calendar jumps to the current selection. |

Red text marks Saturdays and national holidays. Today has an outlined ring, and the selected day is filled.

---

## Time

```dart
NepaliDatePicker(
  enableTime: true,
  timeFormat: '24',
  onChanged: (v) => print('${v.bsDate} at ${v.time}'),
)
```

The time field opens Flutter's standard time picker. The value is included in `NepaliDateValue.time`, formatted per `timeFormat`.

---

## Services

The widget creates its own services by default. Pass your own to control networking:

```dart
final client = http.Client();

NepaliDatePicker(
  service: NepaliDateService(
    baseUrl: 'https://my-proxy.example.com/api/v2/datepicker',
    client: client,
  ),
  adService: AdToBsService(client: client),
  onChanged: (_) {},
)
```

If you pass a service in, **you** own it and are responsible for disposing it. The widget disposes only the services it created itself.

### `NepaliDateService`: BS calendar data

```dart
final service = NepaliDateService();

final month = await service.getMonth(year: 2083, month: 6);
print(month.monthName);   // असोज
print(month.totalDays);   // 30
print(month.dates.first); // NepaliCalendarDay

final today = await service.getToday();
print(today.bsDate);      // 2083-06-14
print(today.adDate);      // 2026-10-01

service.clearCache();
service.dispose();
```

- Months are cached in memory by `year-month`. The cache holds up to **24** months and evicts the oldest first.
- `getMonth(forceRefresh: true)` skips the cache.
- Errors are thrown as `NepaliDateApiException`, whose `message` is user-friendly.

### `AdToBsService`: AD → BS conversion

```dart
final service = AdToBsService();

final r = await service.convert(DateTime(2026, 10, 1));
print(r.bsDate);             // 2083-06-14
print(r.unicodeLongFormat);  // १४ असोज २०८३

service.dispose();
```

Requests time out after 15 seconds. A non-200 response throws an `Exception`, and an unexpected body throws a `FormatException`.

---

## Models

| Class                 | Purpose                                                                                                                                                                          |
| --------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `NepaliDateValue`     | The value returned by the picker.                                                                                                                                                |
| `NepaliCalendarMonth` | A BS month: name, total days, starting and ending weekday, prev/next month, and its `dates`.                                                                                     |
| `NepaliCalendarDay`   | A single day with BS and AD parts, names, a `today` flag, Nepali (`unicode*`) strings and `events`. Helpers: `bsDate`, `adDate`, `adDateTime`, `hasEvents`, `isNationalHoliday`. |
| `NepaliCalendarEvent` | An event with `title`, `titleEn`, `description` and `nationalHoliday`.                                                                                                           |
| `AdToBsResult`        | The result of an AD→BS conversion.                                                                                                                                               |

All of them are exported from `package:adbs_datepicker/adbs_datepicker.dart`.

---

## Data source

BS calendar data, holidays and AD→BS conversion come from the public API at `patro.techarttrekkies.com.np`:

| Endpoint                                    | Used for                            |
| ------------------------------------------- | ----------------------------------- |
| `GET /api/v2/datepicker/dates?year=&month=` | A BS month with its days and events |
| `GET /api/v2/datepicker/today`              | Today's date in BS and AD           |
| `GET /ad/{yyyy}/{mm}/{dd}/json`             | Convert an AD date to BS            |

Because of this:

- The **BS calendar and AD→BS conversion need an internet connection.** The AD calendar itself is computed locally and works offline, but picking an AD day still needs the API to find its BS date.
- If the BS month can't be loaded, the dialog shows an error with a **Retry** button.
- The range of BS years you can browse depends on what the API supports.

---

## Testing

Run the package's tests with:

```bash
flutter test
```

The tests use a fake HTTP client (`MockClient` from `package:http/testing.dart`), so they never touch the network. You can do the same in your own widget tests:

```dart
final client = MockClient((request) async {
  // return fixture JSON for /today, /dates and /ad/... here
  return http.Response('{}', 200);
});

NepaliDatePicker(
  service: NepaliDateService(client: client),
  adService: AdToBsService(client: client),
  onChanged: (_) {},
)
```

---

## Example

A minimal app:

```dart
import 'package:adbs_datepicker/adbs_datepicker.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: const Demo(),
    );
  }
}

class Demo extends StatefulWidget {
  const Demo({super.key});

  @override
  State<Demo> createState() => _DemoState();
}

class _DemoState extends State<Demo> {
  NepaliDateValue? _value;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('adbs_datepicker')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            NepaliDatePicker(
              label: 'Date',
              style: NepaliDatePickerStyle.filled,
              onChanged: (v) => setState(() => _value = v),
            ),
            const SizedBox(height: 24),
            Text(_value?.toString() ?? 'Nothing selected yet'),
          ],
        ),
      ),
    );
  }
}
```

---

## Contributing

Issues and pull requests are welcome.

1. Fork the repo and create a branch.
2. Make your change and add or update tests.
3. Run `flutter analyze` and `flutter test`.
4. Open a pull request describing what changed and why.

---

## License

Add your license here, for example MIT. See [LICENSE](LICENSE).
