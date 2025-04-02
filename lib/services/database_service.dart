import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import '../models/project.dart';
import '../models/task.dart';
import '../models/activity.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final firebase_storage.FirebaseStorage _storage = firebase_storage.FirebaseStorage.instance;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  // Projects
  Future<void> createProject(Project project) async {
    try {
      print('Creating project: ${project.title} for user: ${project.createdBy}');
      await _database.ref('projects').push().set(project.toJson());
      print('Project created successfully');
      await _logActivity(
        'project_created',
        'Created project: ${project.title}',
        project.createdBy,
      );
    } catch (e) {
      print('Error creating project: $e');
      rethrow;
    }
  }

  Future<void> updateProject(Project project) async {
    await _database.ref('projects/${project.id}').update(project.toJson());
    await _logActivity(
      'project_updated',
      'Updated project: ${project.title}',
      project.createdBy,
    );
  }

  Future<void> deleteProject(String projectId, String userId) async {
    // Проверяем, принадлежит ли проект пользователю
    final projectSnapshot = await _database.ref('projects/$projectId').get();
    
    if (!projectSnapshot.exists) return;
    
    final projectData = projectSnapshot.value as Map<dynamic, dynamic>;
    if (projectData['createdBy'] != userId) {
      throw Exception('Unauthorized: Project does not belong to the user');
    }

    // Удаляем проект и все связанные задачи
    await Future.wait([
      _database.ref('projects/$projectId').remove(),
      _deleteProjectTasks(projectId),
    ]);
  }

  Future<void> _deleteProjectTasks(String projectId) async {
    final tasksSnapshot = await _database.ref('tasks').orderByChild('projectId').equalTo(projectId).get();
    
    if (!tasksSnapshot.exists) return;
    
    final tasks = tasksSnapshot.value as Map<dynamic, dynamic>;
    await Future.wait(
      tasks.keys.map((key) => _database.ref('tasks/$key').remove()),
    );
  }

  // Tasks
  Future<void> createTask(Task task) async {
    await _database.ref('tasks').push().set(task.toJson());
    await _logActivity(
      'task_created',
      'Created task: ${task.title}',
      task.assignedTo,
    );
  }

  Future<void> updateTask(Task task) async {
    await _database.ref('tasks/${task.id}').update(task.toJson());
    await _logActivity(
      'task_updated',
      'Updated task: ${task.title}',
      task.assignedTo,
    );
  }

  Future<void> deleteTask(String taskId, String userId) async {
    // Проверяем, принадлежит ли задача пользователю
    final taskSnapshot = await _database.ref('tasks/$taskId').get();
    
    if (!taskSnapshot.exists) return;
    
    final taskData = taskSnapshot.value as Map<dynamic, dynamic>;
    if (taskData['assignedTo'] != userId) {
      throw Exception('Unauthorized: Task does not belong to the user');
    }

    await _database.ref('tasks/$taskId').remove();
    await _logActivity(
      'task_deleted',
      'Deleted task',
      userId,
    );
  }

  // Attachments
  Future<String> uploadTaskAttachment(String taskId, File file) async {
    final fileName = DateTime.now().millisecondsSinceEpoch.toString() + '_' + file.path.split('/').last;
    final ref = _storage.ref('task_attachments/$taskId/$fileName');
    
    await ref.putFile(file);
    final downloadUrl = await ref.getDownloadURL();
    
    await _database.ref('tasks/$taskId/attachments').push().set({
      'name': fileName,
      'url': downloadUrl,
      'path': 'task_attachments/$taskId/$fileName',
      'uploadedAt': DateTime.now().toIso8601String(),
    });

    return downloadUrl;
  }

  // Activity Logging
  Future<void> _logActivity(String type, String description, String userId) async {
    final activity = Activity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      description: description,
      userId: userId,
      timestamp: DateTime.now(),
    );

    await _database.ref('activities/${activity.id}').set(activity.toJson());
  }

  // Analytics
  Future<List<Activity>> getUserActivity(String userId, {DateTime? startDate, DateTime? endDate}) async {
    var query = _database.ref('activities').orderByChild('userId').equalTo(userId);
    
    if (startDate != null) {
      query = query.startAt(startDate.millisecondsSinceEpoch);
    }
    if (endDate != null) {
      query = query.endAt(endDate.millisecondsSinceEpoch);
    }

    final snapshot = await query.get();
    final List<Activity> activities = [];

    if (snapshot.value != null) {
      final Map<dynamic, dynamic> activitiesMap = snapshot.value as Map<dynamic, dynamic>;
      activitiesMap.forEach((key, value) {
        activities.add(Activity.fromJson(Map<String, dynamic>.from(value)));
      });
    }

    return activities.where((activity) {
      if (startDate == null && endDate == null) return true;
      final activityDate = activity.timestamp;
      if (startDate != null && activityDate.isBefore(startDate)) return false;
      if (endDate != null && activityDate.isAfter(endDate)) return false;
      return true;
    }).toList();
  }

  // Stream getters for real-time updates
  Stream<List<Project>> getProjects(String userId) {
    return _database
        .ref('projects')
        .orderByChild('createdBy')
        .equalTo(userId)
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];
      
      print('Retrieved projects for user $userId: ${data.length} projects');
      return data.entries
          .map((e) => Project.fromJson({'id': e.key, ...Map<String, dynamic>.from(e.value)}))
          .toList();
    });
  }

  Stream<List<Task>> getProjectTasks(String projectId) {
    return _database
        .ref('tasks')
        .orderByChild('projectId')
        .equalTo(projectId)
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];
      
      print('Retrieved tasks for project $projectId: ${data.length} tasks');
      return data.entries
          .map((e) => Task.fromJson({'id': e.key, ...Map<String, dynamic>.from(e.value)}))
          .toList();
    });
  }
} 