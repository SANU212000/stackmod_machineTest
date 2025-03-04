import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stackmod_test/controller/todo_controller.dart';
import 'package:stackmod_test/model/todo_list.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatelessWidget {
  final TodoController todoController = Get.find<TodoController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Task Calendar")),
      body: Column(
        children: [
          Obx(
            () => TableCalendar(
              focusedDay: todoController.selectedDate.value,
              firstDay: DateTime.utc(2023, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              calendarFormat: CalendarFormat.month,
              selectedDayPredicate:
                  (day) => isSameDay(day, todoController.selectedDate.value),
              onDaySelected: (selectedDay, focusedDay) {
                todoController.selectedDate.value = selectedDay;
                todoController.filterTasksByDate(selectedDay);
              },
              eventLoader: (day) {
                return todoController.todos
                    .where((task) => isSameDay(task.dueDate.toDate(), day))
                    .toList();
              },
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: Obx(() {
              var selectedTasks = todoController.filteredTasks;
              return selectedTasks.isEmpty
                  ? const Center(child: Text("No tasks on this day."))
                  : ListView.builder(
                    itemCount: selectedTasks.length,
                    itemBuilder: (context, index) {
                      var task = selectedTasks[index];
                      return Card(
                        child: ListTile(
                          title: Text(task.title),
                          subtitle: Text("Due: ${task.dueDate.toDate()}"),
                        ),
                      );
                    },
                  );
            }),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    TextEditingController titleController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();
    final TodoController todoController = Get.find<TodoController>();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Add Task"),
            content: SingleChildScrollView(
              // ✅ Fix content overflow
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: "Title"),
                  ),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: "Description"),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
             
                onPressed: () {
                  if (titleController.text.isNotEmpty) {
                    String userId =
                        FirebaseAuth.instance.currentUser?.uid ?? "";

                    if (userId.isNotEmpty) {
                      todoController.addTodo(
                        userId: userId, // ✅ Correct userId
                        title: titleController.text,
                        description: descriptionController.text,
                        dueDate: Timestamp.fromDate(
                          todoController.selectedDate.value,
                        ),
                        priority: TaskPriority.Medium,
                      );
                      Navigator.pop(context);
                    } else {
                      Get.snackbar("Error", "User not found. Please log in.");
                    }
                  }
                },
                child: const Text("Add"),
              ),
            ],
          ),
    );
  }
}
