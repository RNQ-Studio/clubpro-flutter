import 'package:intl/intl.dart';

abstract final class AppDateUtils {
  static String format(DateTime date, {String pattern = 'dd MMM yyyy'}) =>
      DateFormat(pattern).format(date);

  static String formatTime(DateTime date, {String pattern = 'HH:mm'}) =>
      DateFormat(pattern).format(date);

  static String formatDateTime(DateTime date) =>
      DateFormat('dd MMM yyyy, HH:mm').format(date);

  static const _bulan = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', //
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  /// "12 April 2001" — tanpa bergantung pada data locale intl.
  static String longDateId(DateTime date) =>
      '${date.day} ${_bulan[date.month - 1]} ${date.year}';

  /// "Juli 2019".
  static String monthYearId(DateTime date) =>
      '${_bulan[date.month - 1]} ${date.year}';

  /// "2001-04-12" untuk API.
  static String isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return format(date);
  }
}
