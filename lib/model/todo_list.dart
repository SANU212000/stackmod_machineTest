import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskPriority { High, Medium, Low }
enum TaskStatus { Pending, InProgress, Completed }

class Todo {
  String id;
  String title;
  String description;
  Timestamp dueDate;
  TaskPriority priority;
  TaskStatus status;
  String userId;

  Todo({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.priority,
    required this.status,
    required this.userId,
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      dueDate: json['dueDate'] ?? Timestamp.now(),
      priority: TaskPriority.values.firstWhere(
        (e) => e.toString().split('.').last == json['priority'],
        orElse: () => TaskPriority.Medium,
      ),
      status: TaskStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => TaskStatus.Pending,
      ),
      userId: json['userId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate,
      'priority': priority.toString().split('.').last,
      'status': status.toString().split('.').last,
      'userId': userId,
    };
  }
}
