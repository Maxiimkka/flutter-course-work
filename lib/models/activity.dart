class Activity {
  final String id;
  final String type;
  final String description;
  final String userId;
  final DateTime timestamp;

  const Activity({
    required this.id,
    required this.type,
    required this.description,
    required this.userId,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'description': description,
      'userId': userId,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as String,
      type: json['type'] as String,
      description: json['description'] as String,
      userId: json['userId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
} 