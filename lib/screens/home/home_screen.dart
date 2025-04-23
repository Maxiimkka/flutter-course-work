import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/project.dart';
import '../../models/task.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../services/analytics_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _projectTitleController = TextEditingController();
  final _projectDescriptionController = TextEditingController();
  final _taskTitleController = TextEditingController();
  final _taskDescriptionController = TextEditingController();
  final _analytics = AnalyticsService();
  DateTime? _sessionStartTime;

  @override
  void initState() {
    super.initState();
    _sessionStartTime = DateTime.now();
    _analytics.logScreenView('home_screen');
  }

  @override
  void dispose() {
    _projectTitleController.dispose();
    _projectDescriptionController.dispose();
    _taskTitleController.dispose();
    _taskDescriptionController.dispose();
    
    // Логируем время сессии при закрытии экрана
    if (_sessionStartTime != null) {
      final sessionDuration = DateTime.now().difference(_sessionStartTime!);
      _analytics.logUserEngagement(sessionDuration.inSeconds);
    }
    
    super.dispose();
  }

  Future<void> _showAddProjectDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Project'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _projectTitleController,
              decoration: const InputDecoration(
                labelText: 'Project Title',
                hintText: 'Enter project title',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _projectDescriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Enter project description',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (_projectTitleController.text.isNotEmpty) {
                final user = context.read<AuthProvider>().user;
                if (user != null) {
                  try {
                    print('Creating project in HomeScreen: ${_projectTitleController.text}');
                    final project = Project(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: _projectTitleController.text,
                      description: _projectDescriptionController.text.isEmpty
                          ? null
                          : _projectDescriptionController.text,
                      createdBy: user.id,
                      createdAt: DateTime.now(),
                    );
                    await context.read<TaskProvider>().addProject(project);
                    await _analytics.logProjectCreated(project.id, project.title);
                    print('Project created successfully in HomeScreen');
                    _projectTitleController.clear();
                    _projectDescriptionController.clear();
                    Navigator.pop(context);
                  } catch (e) {
                    print('Error creating project in HomeScreen: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error creating project: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddTaskDialog(String projectId) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _taskTitleController,
              decoration: const InputDecoration(
                labelText: 'Task Title',
                hintText: 'Enter task title',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _taskDescriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Enter task description',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (_taskTitleController.text.isNotEmpty) {
                final user = context.read<AuthProvider>().user;
                if (user != null) {
                  final task = Task(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: _taskTitleController.text,
                    description: _taskDescriptionController.text.isEmpty
                        ? ''
                        : _taskDescriptionController.text,
                    projectId: projectId,
                    assignedTo: user.id,
                    createdAt: DateTime.now(),
                    status: 'todo',
                  );
                  try {
                    await context.read<TaskProvider>().addTask(task);
                    await _analytics.logTaskCreated(task.id, task.title, projectId);
                    _taskTitleController.clear();
                    _taskDescriptionController.clear();
                    Navigator.pop(context);
                  } catch (e) {
                    print('Error creating task in HomeScreen: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error creating task: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please sign in to continue'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          CircleAvatar(
            backgroundImage: user.photoURL != null
                ? NetworkImage(user.photoURL!)
                : null,
            child: user.photoURL == null
                ? Text(user.email.substring(0, 1).toUpperCase())
                : null,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                context.read<AuthProvider>().signOut();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(user.name ?? 'User'),
              accountEmail: Text(user.email ?? 'No email'),
              currentAccountPicture: CircleAvatar(
                backgroundImage: user.photoURL != null
                    ? NetworkImage(user.photoURL!)
                    : null,
                child: user.photoURL == null
                    ? Text(user.email.substring(0, 1).toUpperCase())
                    : null,
              ),
            ),
            ...context.watch<TaskProvider>().projects.map(
              (project) => ListTile(
                title: Text(project.title),
                subtitle: project.description != null
                    ? Text(
                        project.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : null,
                selected: project.id == context.watch<TaskProvider>().selectedProjectId,
                onTap: () {
                  context.read<TaskProvider>().selectProject(project.id);
                  Navigator.pop(context);
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Add Project'),
              onTap: () {
                Navigator.pop(context);
                _showAddProjectDialog();
              },
            ),
          ],
        ),
      ),
      body: context.watch<TaskProvider>().selectedProjectId == null
          ? const Center(
              child: Text('Select a project to view tasks'),
            )
          : ListView.builder(
              itemCount: context.watch<TaskProvider>()
                  .getTasksForProject(context.watch<TaskProvider>().selectedProjectId!)
                  .length,
              itemBuilder: (context, index) {
                final task = context.watch<TaskProvider>()
                    .getTasksForProject(context.watch<TaskProvider>().selectedProjectId!)[index];
                return ListTile(
                  title: Text(task.title),
                  subtitle: task.description.isNotEmpty
                      ? Text(
                          task.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      context.read<TaskProvider>().deleteTask(task.id, user.id);
                    },
                  ),
                  onTap: () {
                    // TODO: Implement task details/edit screen
                  },
                );
              },
            ),
      floatingActionButton: context.watch<TaskProvider>().selectedProjectId != null
          ? FloatingActionButton(
              onPressed: () => _showAddTaskDialog(context.read<TaskProvider>().selectedProjectId!),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}