/// Solar Hijri (Jalali) date support - the API returns dates such as
/// `1405-06-09` with Afghan month names (Sunbula, Mizan, Aqrab, ...).
///
/// Conversion is a port of the jalaali-js algorithm:
/// https://github.com/jalaali/jalaali-js
class JalaliDate implements Comparable<JalaliDate> {
  const JalaliDate({required this.year, required this.month, required this.day});

  final int year;
  final int month;
  final int day;

  static const List<String> monthNames = [
    'Hamal',
    'Sawr',
    'Jawza',
    'Saratan',
    'Asad',
    'Sunbula',
    'Mizan',
    'Aqrab',
    'Qaws',
    'Jadi',
    'Dalwa',
    'Hoot',
  ];

  static const List<int> daysInMonth = [
    31, 31, 31, 31, 31, 31, 30, 30, 30, 30, 30, 29,
  ];

  /// Parses `1405-06-09` style strings.
  static JalaliDate? tryParse(String? value) {
    if (value == null) return null;
    final match =
        RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})').firstMatch(value.trim());
    if (match == null) return null;
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    return JalaliDate(year: year, month: month, day: day);
  }

  /// Stable key used to group days into calendar months: `1405-6`.
  String get monthKey => '$year-$month';

  String get monthName => monthNames[month - 1];

  /// Number of days of this date's month.
  int get monthLength => daysInMonth[month - 1];

  @override
  bool operator ==(Object other) =>
      other is JalaliDate &&
      year == other.year &&
      month == other.month &&
      day == other.day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  int compareTo(JalaliDate other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  @override
  String toString() =>
      '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  /// Weekday index on a Saturday-first weekly grid (0 = Saturday .. 6 = Friday).
  int get saturdayFirstWeekday {
    final gregorian = toDateTime();
    return (gregorian.weekday + 1) % 7;
  }

  DateTime toDateTime() => _d2g(_j2d(year, month, day));
}

int _div(int a, int b) => a ~/ b;

int _mod(int a, int b) => a - b * (a ~/ b);

const List<int> _breaks = [
  -61, 9, 38, 199, 426, 686, 756, 818, 1111, 2061, 3337, 4697, 6451, 10031,
];

class _JalaliCalibration {
  _JalaliCalibration(this.gy, this.march, {required this.leapJ});
  final int gy;
  final int march;
  final int leapJ;
}

_JalaliCalibration _jalCal(int jy) {
  var leapJ = -14;
  var jp = _breaks[0];
  var jump = 0;

  for (var i = 1; i < _breaks.length; i += 1) {
    final jm = _breaks[i];
    jump = jm - jp;
    if (jy < jm) break;
    leapJ += _div(jump, 33) * 8 + _div(_mod(jump, 33), 4);
    jp = jm;
  }

  var n = jy - jp;
  leapJ += _div(n, 33) * 8 + _div(_mod(n, 33) + 3, 4);
  if (_mod(jump, 33) == 4 && jump - n == 4) leapJ += 1;

  final gy = jy + 621;
  final leapG = _div(gy, 4) - _div((_div(gy, 100) + 1) * 3, 4) - 150;
  final march = 20 + leapJ - leapG;

  if (jump - n < 6) n = n - jump + _div(jump + 4, 33) * 33;
  var leap = _mod(_mod(n + 1, 33) - 1, 4);
  if (leap == -1) leap = 4;

  return _JalaliCalibration(gy, march, leapJ: leap);
}

int _g2d(int gy, int gm, int gd) {
  var d = _div((gy + _div(gm - 8, 6) + 100100) * 1461, 4) +
      _div(153 * _mod(gm + 9, 12) + 2, 5) +
      gd -
      34840408;
  return d - _div(_div(gy + 100100 + _div(gm - 8, 6), 100) * 3, 4) + 752;
}

DateTime _d2g(int jdn) {
  var j = 4 * jdn + 139361631;
  j += _div(_div(4 * jdn + 183187720, 146097) * 3, 4) * 4 - 3908;
  final i = _div(_mod(j, 1461), 4) * 5 + 308;
  final gd = _div(_mod(i, 153), 5) + 1;
  final gm = _mod(_div(i, 153), 12) + 1;
  final gy = _div(j, 1461) - 100100 + _div(8 - gm, 6);
  return DateTime(gy, gm, gd);
}

int _j2d(int jy, int jm, int jd) {
  final calibration = _jalCal(jy);
  return _g2d(calibration.gy, 3, calibration.march) +
      (jm - 1) * 31 -
      _div(jm, 7) * (jm - 7) +
      jd -
      1;
}
