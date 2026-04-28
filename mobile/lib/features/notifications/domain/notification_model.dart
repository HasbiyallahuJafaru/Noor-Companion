/// notification_model.dart — in-app notification record from the backend.
///
/// Mirrors the Notification table returned by GET /api/v1/notifications.
/// The [data] field carries extra context for navigation (e.g. sessionId).
library;

/// A single notification item from the backend.
class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.data,
  });

  final String id;

  /// Matches a [NotificationType] enum value — e.g. 'streak_reminder'.
  final String type;

  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  /// Optional JSON payload with navigation context (sessionId, therapistId, etc.)
  final Map<String, dynamic>? data;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      isRead: json['isRead'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      data: json['data'] != null
          ? Map<String, dynamic>.from(json['data'] as Map)
          : null,
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      type: type,
      title: title,
      body: body,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      data: data,
    );
  }
}

/// Resolved list response from GET /api/v1/notifications.
class NotificationsResponse {
  const NotificationsResponse({
    required this.notifications,
    required this.unreadCount,
  });

  final List<NotificationModel> notifications;
  final int unreadCount;

  factory NotificationsResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return NotificationsResponse(
      notifications: (data['notifications'] as List)
          .map((n) => NotificationModel.fromJson(n as Map<String, dynamic>))
          .toList(),
      unreadCount: data['unreadCount'] as int,
    );
  }
}
