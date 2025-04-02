import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../models/activity.dart';
import '../services/database_service.dart';
import '../models/user.dart';

class TaskProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  List<Project> _projects = [];
  List<Task> _tasks = [];
  String? _selectedProjectId;
  Stream<List<Project>>? _projectsStream;
  final User _user;

  List<Project> get projects => _projects;
  List<Task> get tasks => _tasks;
  String? get selectedProjectId => _selectedProjectId;

  TaskProvider(this._user) {
    _initializeListeners();
  }

  void _initializeListeners() {
    print('Initializing listeners in TaskProvider for user: ${_user.id}');
    // Инициализируем стрим проектов для текущего пользователя
    _projectsStream = _db.getProjects(_user.id);
    
    // Подписываемся на обновления проектов
    _projectsStream?.listen((projects) {
      print('Received projects update: ${projects.length} projects');
      _projects = projects;
      notifyListeners();
    }, onError: (error) {
      print('Error in projects stream: $error');
    });

    // Если есть выбранный проект, загружаем его задачи
    if (_selectedProjectId != null) {
      _loadProjectTasks(_selectedProjectId!);
    }
  }

  void _loadProjectTasks(String projectId) {
    print('Loading tasks for project: $projectId');
    _db.getProjectTasks(projectId).listen((tasks) {
      print('Received tasks update: ${tasks.length} tasks');
      // Фильтруем задачи только для текущего пользователя
      _tasks = tasks.where((task) => task.assignedTo == _user.id).toList();
      notifyListeners();
    }, onError: (error) {
      print('Error in tasks stream: $error');
    });
  }

  List<Task> getTasksForProject(String projectId) {
    return _tasks.where((task) => task.projectId == projectId && task.assignedTo == _user.id).toList();
  }

  void selectProject(String projectId) {
    _selectedProjectId = projectId;
    _loadProjectTasks(projectId);
    notifyListeners();
  }

  Future<void> addProject(Project project) async {
    try {
      print('Adding project in TaskProvider: ${project.title}');
      // Убеждаемся, что проект создается для текущего пользователя
      final projectWithUser = project.copyWith(createdBy: _user.id);
      await _db.createProject(projectWithUser);
      print('Project added successfully in TaskProvider');
    } catch (e) {
      print('Error adding project in TaskProvider: $e');
      rethrow;
    }
  }

  Future<void> updateProject(Project project) async {
    // Проверяем, что проект принадлежит текущему пользователю
    if (project.createdBy == _user.id) {
      await _db.updateProject(project);
    }
  }

  Future<void> deleteProject(String projectId, String userId) async {
    // Проверяем, что удаляем проект текущего пользователя
    if (userId == _user.id) {
      await _db.deleteProject(projectId, userId);
    }
  }

  Future<void> addTask(Task task) async {
    // Убеждаемся, что задача создается для текущего пользователя
    final taskWithUser = task.copyWith(assignedTo: _user.id);
    await _db.createTask(taskWithUser);
  }

  Future<void> updateTask(Task task) async {
    // Проверяем, что задача принадлежит текущему пользователю
    if (task.assignedTo == _user.id) {
      await _db.updateTask(task);
    }
  }

  Future<void> deleteTask(String taskId, String userId) async {
    // Проверяем, что удаляем задачу текущего пользователя
    if (userId == _user.id) {
      await _db.deleteTask(taskId, userId);
    }
  }

  Future<String> addTaskAttachment(String taskId, File file) async {
    return await _db.uploadTaskAttachment(taskId, file);
  }

  Future<List<Activity>> getUserActivity(String userId, {DateTime? startDate, DateTime? endDate}) async {
    return await _db.getUserActivity(userId, startDate: startDate, endDate: endDate);
  }
} 