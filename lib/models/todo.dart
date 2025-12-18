// File: lib/models/todo.dart
class Todo {
  String id;
  String title;
  String description;
  DateTime dueDate;
  bool isCompleted;
  DateTime createdAt;
  String userId;
  String priority; // 'low', 'medium', 'high'
  List<String> tags;
  
  Todo({
    this.id = '',
    required this.title,
    this.description = '',
    required this.dueDate,
    this.isCompleted = false,
    required this.createdAt,
    required this.userId,
    this.priority = 'medium',
    this.tags = const [],
  });
  
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'userId': userId,
      'priority': priority,
      'tags': tags,
    };
  }
  
  factory Todo.fromMap(String id, Map<String, dynamic> map) {
    return Todo(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      dueDate: DateTime.parse(map['dueDate']),
      isCompleted: map['isCompleted'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
      userId: map['userId'] ?? '',
      priority: map['priority'] ?? 'medium',
      tags: List<String>.from(map['tags'] ?? []),
    );
  }
}