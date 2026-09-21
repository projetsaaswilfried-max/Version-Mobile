enum AppNotificationCategory {
  all,
  unread,
  messages,
  profile,
  posts,
  recommendations,
  platform;

  String get label => switch (this) {
    AppNotificationCategory.all => 'Toutes',
    AppNotificationCategory.unread => 'Non lues',
    AppNotificationCategory.messages => 'Messages',
    AppNotificationCategory.profile => 'Profil',
    AppNotificationCategory.posts => 'Publications',
    AppNotificationCategory.recommendations => 'Recommandations',
    AppNotificationCategory.platform => 'Plateforme',
  };
}

AppNotificationCategory notificationCategoryFromType(String type) {
  final value = type.toUpperCase();
  if (value.contains('MESSAGE') ||
      value.contains('INVITE') ||
      value.contains('CONVERSATION') ||
      value.contains('CHAT')) {
    return AppNotificationCategory.messages;
  }
  if (value.contains('FAVORITE') ||
      value.contains('LIKE') ||
      value.contains('VIEW') ||
      value.contains('VISIT') ||
      value.contains('MATCH') ||
      value.contains('PHOTO') ||
      value.contains('VERIF')) {
    return AppNotificationCategory.profile;
  }
  if (value.contains('POST') ||
      value.contains('COMMENT') ||
      value.contains('PUBLICATION')) {
    return AppNotificationCategory.posts;
  }
  if (value.contains('RECOMMEND')) {
    return AppNotificationCategory.recommendations;
  }
  return AppNotificationCategory.platform;
}
