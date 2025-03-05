import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
// import 'package:stackmod_test/services/notification_services.dart';
import '../model/todo_list.dart';
import 'package:table_calendar/table_calendar.dart';

class TodoController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  var todos = <Todo>[].obs;
  var isLoading = false.obs;
  var pendingCount = 0.obs;
  var inProgressCount = 0.obs;
  var completedCount = 0.obs;
  var overdueCount = 0.obs;
  var selectedDate = DateTime.now().obs;
  var filteredTasks = <Todo>[].obs;

  Future<void> fetchTodos(String userId) async {
    todos.clear();
    isLoading(true);
    try {
      if (userId.isEmpty) return;

      final querySnapshot =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('todos')
              .get();

      todos.value =
          querySnapshot.docs.map((doc) => Todo.fromJson(doc.data())).toList();
      updateTaskStatistics();
      filterTasksByDate(selectedDate.value);
    } catch (e) {
      print('Error fetching todos: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> addTodo({
    required String userId,
    required String title,
    required String description,
    required Timestamp dueDate,
    required TaskPriority priority,
  }) async {
    if (userId.isEmpty) return;

    try {
      final newTodo = Todo(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        description: description,
        dueDate: dueDate,
        priority: priority,
        status: TaskStatus.Pending,
        userId: userId,
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('todos')
          .doc(newTodo.id)
          .set(newTodo.toJson());

      fetchTodos(userId);

      print("✅ Task added successfully: ${newTodo.title}");
    } catch (e) {
      print('❌ Error adding todo: $e');
    }
  }

  Future<void> updateTodo({
    required String userId,
    required String id,
    String? title,
    String? description,
    Timestamp? dueDate,
    TaskPriority? priority,
    TaskStatus? status,
  }) async {
    if (userId.isEmpty) return;

    try {
      final updateData = <String, dynamic>{};
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (dueDate != null) updateData['dueDate'] = dueDate;
      if (priority != null)
        updateData['priority'] = priority.toString().split('.').last;
      if (status != null)
        updateData['status'] = status.toString().split('.').last;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('todos')
          .doc(id)
          .update(updateData);

      fetchTodos(userId);
      filterTasksByDate(selectedDate.value);
    } catch (e) {
      print('Error updating todo: $e');
    }
  }

  Future<void> removeTodo(String userId, String id) async {
    try {
      if (userId.isEmpty) return;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('todos')
          .doc(id)
          .delete();

      fetchTodos(userId);
    } catch (e) {
      print('Error removing todo: $e');
    }
  }

  Future<void> updateTaskStatus(
    String userId,
    String id,
    TaskStatus newStatus,
  ) async {
    try {
      if (userId.isEmpty) return;

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('todos')
          .doc(id)
          .update({'status': newStatus.toString().split('.').last});

      fetchTodos(userId);
    } catch (e) {
      print('Error updating task status: $e');
    }
  }

  void updateTaskStatistics() {
    int pending = 0;
    int inProgress = 0;
    int completed = 0;
    int overdue = 0;

    DateTime now = DateTime.now();

    for (var task in todos) {
      switch (task.status) {
        case TaskStatus.Pending:
          pending++;
          break;
        case TaskStatus.InProgress:
          inProgress++;
          break;
        case TaskStatus.Completed:
          completed++;
          break;
      }

      if (task.dueDate.toDate().isBefore(now) && task.status != "Completed") {
        overdue++;
      }
    }

    pendingCount.value = pending;
    inProgressCount.value = inProgress;
    completedCount.value = completed;
    overdueCount.value = overdue;
  }

  void filterTasksByDate(DateTime date) {
    selectedDate.value = date;
    filteredTasks.value =
        todos.where((task) {
          return isSameDay(task.dueDate.toDate(), date);
        }).toList();
  }

  Future<void> markTasksAsCompleted(List<String> taskIds, String userId) async {
    if (taskIds.isEmpty || userId.isEmpty) return;

    WriteBatch batch = _firestore.batch();

    try {
      for (String taskId in taskIds) {
        DocumentReference taskRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('todos')
            .doc(taskId);

        batch.update(taskRef, {
          'status': TaskStatus.Completed.toString().split('.').last,
        });
      }

      await batch.commit();
      fetchTodos(userId);

      print("✅ Successfully marked tasks as completed!");
    } catch (e) {
      print("❌ Error marking tasks as completed: $e");
    }
  }

  void clearTodos() {
    todos.clear();
    pendingCount.value = 0;
    inProgressCount.value = 0;
    completedCount.value = 0;
    overdueCount.value = 0;
    filteredTasks.clear();
  }
}
