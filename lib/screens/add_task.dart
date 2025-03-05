import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stackmod_test/screens/constants.dart';
import 'package:stackmod_test/controller/todo_controller.dart';
import 'package:stackmod_test/controller/user_controller.dart';
import 'package:stackmod_test/model/todo_list.dart';

class TaskListScreen extends StatelessWidget {
  final TodoController controller = Get.find<TodoController>();

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  Rx<TaskPriority> selectedPriority = TaskPriority.Medium.obs;
  Rx<TaskStatus> selectedStatus = TaskStatus.Pending.obs;
  Rx<DateTime?> selectedDueDate = Rx<DateTime?>(null);

  TaskListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 80,
        backgroundColor: kPrimaryColor,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20.0)),
        ),
        flexibleSpace: Center(
          child: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 2,
                  offset: Offset(0, 0),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: kWhiteColor),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.only(top: 45.0, left: 16, right: 16),
          child: Column(
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter task title',
                ),
              ),
              const SizedBox(height: 10),

              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter task description',
                ),
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
                      initialDate: DateTime.now(),
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
                          child: Text(priority.toString().split('.').last),
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
                          child: Text(status.toString().split('.').last),
                        );
                      }).toList(),
                  onChanged: (TaskStatus? newValue) {
                    if (newValue != null) {
                      selectedStatus.value = newValue;
                    }
                  },
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  UserController userController = Get.find<UserController>();
                  String userId = userController.userId.value;

                  print("🟢 Adding todo for userId: $userId");

                  if (userId.isEmpty) {
                    Get.snackbar(
                      'Error',
                      'User not found!',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                    return;
                  }

                  if (titleController.text.isEmpty ||
                      descriptionController.text.isEmpty ||
                      selectedDueDate.value == null) {
                    Get.snackbar(
                      'Error',
                      'Please fill all fields!',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                    return;
                  }

                  controller.addTodo(
                    userId: userId,
                    title: titleController.text,
                    description: descriptionController.text,
                    dueDate: Timestamp.fromDate(selectedDueDate.value!),
                    priority: selectedPriority.value,
                  );

                  titleController.clear();
                  descriptionController.clear();
                  selectedDueDate.value = null;
                  selectedPriority.value = TaskPriority.Medium;
                  selectedStatus.value = TaskStatus.Pending;

                  Get.snackbar(
                    'Success',
                    'Task Added!',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                  );
                },
                child: const Text("Add Task"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
