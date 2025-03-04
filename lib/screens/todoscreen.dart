import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stackmod_test/controller/auth_fb.dart';
import 'package:stackmod_test/screens/constants.dart';
import 'package:stackmod_test/controller/todo_controller.dart';
import 'package:stackmod_test/controller/user_controller.dart';
import 'package:stackmod_test/model/todo_list.dart';
import 'package:stackmod_test/screens/add_task.dart';
import 'package:stackmod_test/screens/calendar_screen.dart';
import 'package:stackmod_test/screens/profile_screen.dart';

class TodoScreen extends StatelessWidget {
  final UserController userController = Get.put(UserController());
  final TodoController todoController = Get.put(TodoController());

  final Rx<TaskPriority?> selectedPriority = Rx<TaskPriority?>(null);
  final Rx<TaskStatus?> selectedStatus = Rx<TaskStatus?>(null);
  final RxBool sortByDueDate = true.obs;
  TodoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100,
        title: Obx(
          () => Text(
            'Hey, ${userController.username.value}',
            style: const TextStyle(
              color: kPrimaryColor,
              fontFamily: 'intro',
              fontSize: 30,
            ),
          ),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfileScreen()),
            );
          },
          icon: const Icon(
            Icons.account_circle,
            color: kPrimaryColor,
            size: 65,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await AuthMethods().signOut(context);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
        backgroundColor: Colors.white,
        elevation: 0.0,
      ),
      body: Column(
        children: [
          Obx(
            () => Column(
              children: [
                Card(
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Column(
                      children: [
                        Text(
                          "Task Statistics",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildTaskStat(
                              "Pending",
                              todoController.pendingCount.value,
                              Colors.orange,
                            ),
                            _buildTaskStat(
                              "In Progress",
                              todoController.inProgressCount.value,
                              Colors.blue,
                            ),
                            _buildTaskStat(
                              "Completed",
                              todoController.completedCount.value,
                              Colors.green,
                            ),
                            _buildTaskStat(
                              "Overdue",
                              todoController.overdueCount.value,
                              Colors.red,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Obx(
                  () => DropdownButton<TaskPriority?>(
                    hint: const Text("Filter by Priority"),
                    value: selectedPriority.value,
                    items:
                        [null, ...TaskPriority.values].map((priority) {
                          return DropdownMenuItem<TaskPriority?>(
                            value: priority,
                            child: Text(priority?.name ?? "All"),
                          );
                        }).toList(),
                    onChanged: (TaskPriority? newValue) {
                      selectedPriority.value = newValue;
                    },
                  ),
                ),

                Obx(
                  () => DropdownButton<TaskStatus?>(
                    hint: const Text("Filter by Status"),
                    value: selectedStatus.value,
                    items:
                        [null, ...TaskStatus.values].map((status) {
                          return DropdownMenuItem<TaskStatus?>(
                            value: status,
                            child: Text(status?.name ?? "All"),
                          );
                        }).toList(),
                    onChanged: (TaskStatus? newValue) {
                      selectedStatus.value = newValue;
                    },
                  ),
                ),

                Obx(
                  () => IconButton(
                    icon: Icon(
                      sortByDueDate.value ? Icons.calendar_today : Icons.sort,
                      color: kPrimaryColor,
                    ),
                    onPressed: () {
                      sortByDueDate.toggle();
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (todoController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              List<Todo> filteredTodos = _filterAndSortTasks(
                todoController.todos,
              );

              if (filteredTodos.isEmpty) {
                return const Center(
                  child: Text(
                    'No tasks found!',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: filteredTodos.length,
                itemBuilder: (context, index) {
                  final todo = filteredTodos[index];
                  return Dismissible(
                    key: Key(todo.id),
                    direction: DismissDirection.horizontal,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(left: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const Text(
                            "Delete",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.delete, color: Colors.white),
                        ],
                      ),
                    ),
                    secondaryBackground: Container(
                      color: Colors.blue,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(right: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Icon(Icons.edit, color: Colors.white),
                          const SizedBox(width: 10),
                          const Text(
                            "Edit",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.endToStart) {
                        _showEditTaskDialog(context, todo);
                        return false;
                      } else if (direction == DismissDirection.startToEnd) {
                        return await showDialog(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: const Text('Delete Task'),
                                content: const Text(
                                  'Are you sure you want to delete this task?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                        );
                      }
                      return false;
                    },
                    onDismissed: (direction) {
                      if (direction == DismissDirection.startToEnd) {
                        todoController.removeTodo(todo.userId, todo.id);
                        Get.snackbar(
                          'Task Deleted',
                          '${todo.title} has been removed.',
                          snackPosition: SnackPosition.TOP,
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                        );
                      }
                    },
                    child: buildTaskTile(todo, context),
                  );
                },
              );
            }),
          ),
        ],
      ),
      floatingActionButton: Stack(
        children: [
          Positioned(
            bottom: 16,
            left: 30,
            child: FloatingActionButton(
              heroTag: "calendar",
              backgroundColor: Colors.blue,
              onPressed: () {
                Get.to(() => CalendarScreen());
              },
              child: const Icon(Icons.calendar_today, color: Colors.white),
            ),
          ),

          Positioned(
            bottom: 16,
            right: 1,
            child: FloatingActionButton(
              heroTag: "addTask",
              backgroundColor: kPrimaryColor,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TaskListScreen()),
                );
              },
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  List<Todo> _filterAndSortTasks(List<Todo> todos) {
    return todos
        .where(
          (task) =>
              (selectedPriority.value == null ||
                  task.priority == selectedPriority.value) &&
              (selectedStatus.value == null ||
                  task.status == selectedStatus.value),
        )
        .toList()
      ..sort(
        (a, b) =>
            sortByDueDate.value
                ? a.dueDate.compareTo(b.dueDate)
                : a.id.compareTo(b.id),
      );
  }

  Widget buildTaskTile(Todo todo, BuildContext context) {
    Color priorityColor;
    switch (todo.priority) {
      case TaskPriority.High:
        priorityColor = Colors.red;
        break;
      case TaskPriority.Medium:
        priorityColor = Colors.orange;
        break;
      case TaskPriority.Low:
        priorityColor = Colors.green;
        break;
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: CircleAvatar(
          backgroundColor: priorityColor,
          child: Icon(Icons.priority_high, color: Colors.white),
        ),

        title: Text(
          todo.title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              todo.description,
              style: const TextStyle(color: Colors.black54),
            ),
            Text(
              "Due: ${todo.dueDate.toDate()}",
              style: const TextStyle(color: Colors.black45, fontSize: 12),
            ),
            Text(
              "Status: ${todo.status.name}",
              style: TextStyle(color: _getStatusColor(todo.status)),
            ),
          ],
        ),
        trailing: Checkbox(
          value: todo.status == TaskStatus.Completed,
          onChanged: (bool? value) {
            todoController.updateTaskStatus(
              todo.userId,
              todo.id,
              value! ? TaskStatus.Completed : TaskStatus.InProgress,
            );
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.0),
          ),
          activeColor: Colors.white,
          checkColor: Colors.black,
        ),
      ),
    );
  }

  Color _getStatusColor(TaskStatus status) {
    return status == TaskStatus.Completed ? Colors.green : Colors.blue;
  }
}

void _showEditTaskDialog(BuildContext context, Todo todo) {
  final TodoController todoController = Get.find<TodoController>();

  TextEditingController titleController = TextEditingController(
    text: todo.title,
  );
  TextEditingController descriptionController = TextEditingController(
    text: todo.description,
  );

  Rx<DateTime?> selectedDueDate = Rx<DateTime?>(todo.dueDate.toDate());
  Rx<TaskPriority> selectedPriority = Rx<TaskPriority>(todo.priority);
  Rx<TaskStatus> selectedStatus = Rx<TaskStatus>(todo.status);

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Edit Task"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 10),

            Obx(
              () => ListTile(
                title: Text(
                  selectedDueDate.value == null
                      ? "Pick Due Date"
                      : "Due Date: ${selectedDueDate.value!.toLocal()}",
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: selectedDueDate.value ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    selectedDueDate.value = pickedDate;
                  }
                },
              ),
            ),
            const SizedBox(height: 10),
            Obx(
              () => DropdownButton<TaskPriority>(
                value: selectedPriority.value,
                items:
                    TaskPriority.values.map((TaskPriority priority) {
                      return DropdownMenuItem<TaskPriority>(
                        value: priority,
                        child: Text(priority.name),
                      );
                    }).toList(),
                onChanged: (TaskPriority? newValue) {
                  if (newValue != null) {
                    selectedPriority.value = newValue;
                  }
                },
              ),
            ),
            const SizedBox(height: 10),
            Obx(
              () => DropdownButton<TaskStatus>(
                value: selectedStatus.value,
                items:
                    TaskStatus.values.map((TaskStatus status) {
                      return DropdownMenuItem<TaskStatus>(
                        value: status,
                        child: Text(status.name),
                      );
                    }).toList(),
                onChanged: (TaskStatus? newValue) {
                  if (newValue != null) {
                    selectedStatus.value = newValue;
                  }
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              todoController.updateTodo(
                userId: todo.userId,
                id: todo.id,
                title: titleController.text,
                description: descriptionController.text,
                dueDate: Timestamp.fromDate(selectedDueDate.value!),
                priority: selectedPriority.value,
                status: selectedStatus.value,
              );

              Get.snackbar(
                'Success',
                'Task Updated!',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );

              Navigator.pop(context);
            },
            child: const Text("Update Task"),
          ),
        ],
      );
    },
  );
}

Widget _buildTaskStat(String label, int count, Color color) {
  return Column(
    children: [
      Text(
        "$count",
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      Text(label),
    ],
  );
}
