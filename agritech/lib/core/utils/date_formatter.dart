import 'package:intl/intl.dart';

/// Formatage de dates en français pour AgriSmart
class DateFormatter {
  DateFormatter._();

  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy', 'fr_FR');
  static final DateFormat _dateTimeFormat =
      DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy', 'fr_FR');
  static final DateFormat _dayMonthFormat = DateFormat('d MMM', 'fr_FR');

  static String formatDate(DateTime date) => _dateFormat.format(date);

  static String formatDateTime(DateTime date) => _dateTimeFormat.format(date);

  static String formatMonthYear(DateTime date) => _monthYearFormat.format(date);

  static String formatDayMonth(DateTime date) => _dayMonthFormat.format(date);

  /// Retourne "il y a X jours", "aujourd'hui", etc.
  static String formatRelative(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return "Aujourd'hui";
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} jours';
    if (diff.inDays < 30) return 'Il y a ${(diff.inDays / 7).floor()} sem.';
    if (diff.inDays < 365) return 'Il y a ${(diff.inDays / 30).floor()} mois';
    return 'Il y a ${(diff.inDays / 365).floor()} an(s)';
  }

  static String formatMois(DateTime date) {
    const mois = [
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Jun',
      'Jul',
      'Aoû',
      'Sep',
      'Oct',
      'Nov',
      'Déc'
    ];
    return mois[date.month - 1];
  }
}
