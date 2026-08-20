/// Relative time formatting for status rows, e.g. "Hace 2 min".
String formatRelativeTime(DateTime dateTime) {
  final difference = DateTime.now().difference(dateTime);

  if (difference.inSeconds < 60) return 'Hace un momento';
  if (difference.inMinutes < 60) return 'Hace ${difference.inMinutes} min';
  if (difference.inHours < 24) return 'Hace ${difference.inHours} h';
  if (difference.inDays == 1) return 'Hace 1 día';
  return 'Hace ${difference.inDays} días';
}
