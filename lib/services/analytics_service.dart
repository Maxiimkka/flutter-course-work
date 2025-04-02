import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  factory AnalyticsService() => _instance;

  AnalyticsService._internal();

  // Инициализация аналитики
  Future<void> init() async {
    await _analytics.setAnalyticsCollectionEnabled(true);
  }

  // Логирование входа пользователя
  Future<void> logLogin(String method) async {
    await _analytics.logLogin(loginMethod: method);
  }

  // Логирование регистрации пользователя
  Future<void> logSignUp(String method) async {
    await _analytics.logSignUp(signUpMethod: method);
  }

  // Логирование создания проекта
  Future<void> logProjectCreated(String projectId, String projectTitle) async {
    await _analytics.logEvent(
      name: 'project_created',
      parameters: {
        'project_id': projectId,
        'project_title': projectTitle,
      },
    );
  }

  // Логирование создания задачи
  Future<void> logTaskCreated(String taskId, String taskTitle, String projectId) async {
    await _analytics.logEvent(
      name: 'task_created',
      parameters: {
        'task_id': taskId,
        'task_title': taskTitle,
        'project_id': projectId,
      },
    );
  }

  // Логирование изменения статуса задачи
  Future<void> logTaskStatusChanged(String taskId, String oldStatus, String newStatus) async {
    await _analytics.logEvent(
      name: 'task_status_changed',
      parameters: {
        'task_id': taskId,
        'old_status': oldStatus,
        'new_status': newStatus,
      },
    );
  }

  // Логирование просмотра экрана
  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  // Логирование времени сессии
  Future<void> logUserEngagement(int seconds) async {
    await _analytics.logEvent(
      name: 'user_engagement',
      parameters: {
        'engagement_time_msec': seconds * 1000,
      },
    );
  }

  Future<void> logUserActivity({
    required String userId,
    required String action,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'user_activity',
        parameters: {
          'user_id': userId,
          'action': action,
          'timestamp': DateTime.now().toIso8601String(),
          ...?parameters,
        },
      );
    } catch (e) {
      print('Error logging analytics: $e');
    }
  }

  Future<void> logProjectActivity({
    required String userId,
    required String projectId,
    required String action,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'project_activity',
        parameters: {
          'user_id': userId,
          'project_id': projectId,
          'action': action,
          'timestamp': DateTime.now().toIso8601String(),
          ...?parameters,
        },
      );
    } catch (e) {
      print('Error logging analytics: $e');
    }
  }

  Future<void> logTaskActivity({
    required String userId,
    required String taskId,
    required String action,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'task_activity',
        parameters: {
          'user_id': userId,
          'task_id': taskId,
          'action': action,
          'timestamp': DateTime.now().toIso8601String(),
          ...?parameters,
        },
      );
    } catch (e) {
      print('Error logging analytics: $e');
    }
  }

  Future<void> logFileActivity({
    required String userId,
    required String fileId,
    required String action,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'file_activity',
        parameters: {
          'user_id': userId,
          'file_id': fileId,
          'action': action,
          'timestamp': DateTime.now().toIso8601String(),
          ...?parameters,
        },
      );
    } catch (e) {
      print('Error logging analytics: $e');
    }
  }
} 