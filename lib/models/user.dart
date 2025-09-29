class User {
  final String id;
  final String name;
  final DateTime createdAt;
  final String? email;
  final String? avatarUrl;

  User({
    required this.id,
    required this.name,
    required this.createdAt,
    this.email,
    this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      email: json['email'],
      avatarUrl: json['avatarUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'email': email,
      'avatarUrl': avatarUrl,
    };
  }

  User copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    String? email,
    String? avatarUrl,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'User{id: $id, name: $name, createdAt: $createdAt}';
  }
}
