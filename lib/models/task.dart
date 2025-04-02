class Task {
  final String id;
  final String title;
  final String description;
  final String projectId;
  final String assignedTo;
  final DateTime createdAt;
  final DateTime? deadline;
  final String status;
  final List<Map<String, String>> attachments;
  final int priority;

  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.projectId,
    required this.assignedTo,
    required this.createdAt,
    this.deadline,
    required this.status,
    this.attachments = const [],
    this.priority = 0,
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? projectId,
    String? assignedTo,
    DateTime? createdAt,
    DateTime? deadline,
    String? status,
    List<Map<String, String>>? attachments,
    int? priority,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      projectId: projectId ?? this.projectId,
      assignedTo: assignedTo ?? this.assignedTo,
      createdAt: createdAt ?? this.createdAt,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      attachments: attachments ?? this.attachments,
      priority: priority ?? this.priority,
    );
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      projectId: json['projectId'] as String,
      assignedTo: json['assignedTo'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String)
          : null,
      status: json['status'] as String,
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((e) => Map<String, String>.from(e as Map))
          .toList() ??
          [],
      priority: json['priority'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'projectId': projectId,
      'assignedTo': assignedTo,
      'createdAt': createdAt.toIso8601String(),
      'deadline': deadline?.toIso8601String(),
      'status': status,
      'attachments': attachments,
      'priority': priority,
    };
  }
} 