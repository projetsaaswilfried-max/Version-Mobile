import 'package:equatable/equatable.dart';

import '../notification_category.dart';

class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
    required this.category,
    this.aggregateCount = 1,
    this.type = '',
    this.targetUrl,
    this.actorId,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final AppNotificationCategory category;
  final int aggregateCount;

  /// Type brut de la table (ex. `NEW_MESSAGE`, `PROFILE_VISIT`,
  /// `CONVERSATION_INVITE`) — utilisé pour router le tap, plus fiable que
  /// [targetUrl] qui reste pensé pour le web (`/messages?conversation=...`).
  final String type;
  final String? targetUrl;
  final String? actorId;

  AppNotification asRead() => AppNotification(
    id: id,
    title: title,
    body: body,
    createdAt: createdAt,
    isRead: true,
    category: category,
    aggregateCount: aggregateCount,
    type: type,
    targetUrl: targetUrl,
    actorId: actorId,
  );

  @override
  List<Object?> get props => [
    id,
    title,
    body,
    createdAt,
    isRead,
    category,
    aggregateCount,
    type,
    targetUrl,
    actorId,
  ];
}
