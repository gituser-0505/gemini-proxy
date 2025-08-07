class HistoryItem {
  final String title;
  final String url;
  final String faviconUrl;
  final DateTime accessTime;

  HistoryItem({
    required this.title,
    required this.url,
    required this.faviconUrl,
    DateTime? accessTime,
  }) : accessTime = accessTime ?? DateTime.now();

  // Форматированное время доступа
  String get formattedAccessTime {
    final now = DateTime.now();
    final difference = now.difference(accessTime);
    
    if (difference.inMinutes < 1) {
      return 'Только что';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} мин назад';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} ч назад';
    } else if (difference.inDays == 1) {
      return 'Вчера';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дн назад';
    } else {
      return '${accessTime.day}.${accessTime.month.toString().padLeft(2, '0')}.${accessTime.year}';
    }
  }

  // Точное время в формате чч:мм
  String get exactTime {
    return '${accessTime.hour.toString().padLeft(2, '0')}:${accessTime.minute.toString().padLeft(2, '0')}';
  }
}