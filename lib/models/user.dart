class User {
  final String id;
  final String email;
  final String? name;
  final String? photoURL;
  final String role;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.email,
    this.name,
    this.photoURL,
    required this.role,
    required this.createdAt,
  });

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? photoURL,
    String? role,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      photoURL: photoURL ?? this.photoURL,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'photoURL': photoURL,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      photoURL: json['photoURL'] as String?,
      role: json['role'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          name == other.name &&
          photoURL == other.photoURL &&
          role == other.role;

  @override
  int get hashCode => Object.hash(id, email, name, photoURL, role);
} 