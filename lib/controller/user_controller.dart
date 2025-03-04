import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:stackmod_test/controller/todo_controller.dart';

class UserController extends GetxController {
  var userId = ''.obs;
  var email = ''.obs;
  var username = 'User'.obs;
  var profileImageUrl = ''.obs;
  var isLoggedIn = false.obs;
  var sessionId = ''.obs;
  var phoneNumber = ''.obs;
  var joiningDate = ''.obs;

  final box = GetStorage();

  @override
  void onInit() {
    super.onInit();
    fetchUserDetails();
  }

  Future<void> fetchUserDetails() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print("⚠️ No user logged in.");
      return;
    }

    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (userDoc.exists) {
        userId.value = user.uid;
        email.value = user.email ?? '';
        username.value = userDoc['username'] ?? 'User';
        profileImageUrl.value = userDoc['profileImageUrl'] ?? '';
        phoneNumber.value = userDoc['phoneNumber'] ?? '';
        sessionId.value = userDoc['sessionId'] ?? '';

        Timestamp? createdAt = userDoc['createdAt'] as Timestamp?;
        if (createdAt != null) {
          joiningDate.value =
              createdAt.toDate().toLocal().toString().split(' ')[0];
        } else {
          joiningDate.value = "Unknown";
        }

        print("✅ User logged in: ${username.value}, userId: ${userId.value}");

        if (Get.isRegistered<TodoController>()) {
          Get.find<TodoController>().fetchTodos(userId.value);
        }

        await _validateSession(sessionId.value);
      }
    } catch (e) {
      print('❌ Error fetching user details: $e');
    }
  }

  Future<void> _validateSession(String currentSessionId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedSessionId = prefs.getString('sessionId');

    if (storedSessionId != null && storedSessionId != currentSessionId) {
      print("❌ Session mismatch! Logging out...");
      await signOut();
      Get.offAllNamed('/userScreen');
      Get.snackbar(
        'Session Expired',
        'You have been logged out due to multiple logins.',
      );
    } else {
      await prefs.setString('sessionId', currentSessionId);
    }
  }

  Future<void> saveUserDetails(String name, String userEmail, String id) async {
    String newSessionId = const Uuid().v4();
    sessionId.value = newSessionId;

    try {
      await FirebaseFirestore.instance.collection('users').doc(id).set({
        'username': name,
        'email': userEmail,
        'sessionId': newSessionId,
      }, SetOptions(merge: true));

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('sessionId', newSessionId);

      print("✅ User details & session saved in Firestore.");
    } catch (e) {
      print('❌ Error saving user details: $e');
    }
  }

  Future<void> signOut() async {
    print("🚪 Signing out user...");
    await FirebaseAuth.instance.signOut();

    userId.value = '';
    email.value = '';
    username.value = 'Guest';
    profileImageUrl.value = '';
    phoneNumber.value = '';
    isLoggedIn.value = false;

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('sessionId');
    Get.find<TodoController>().todos.clear();
    _clearUserDetails();
    Get.offAllNamed('/userScreen');
  }

  void _clearUserDetails() {
    box.remove('username');
    box.remove('email');
    box.remove('userId');
    print("🗑 User details cleared from local storage.");
  }

  Future<void> editUserName(BuildContext context) async {
    TextEditingController _nameController = TextEditingController(
      text: username.value,
    );

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Edit Name"),
            content: TextField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: "Enter your name"),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  String newName = _nameController.text.trim();
                  if (newName.isNotEmpty) {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId.value)
                        .update({'username': newName});
                    username.value = newName;
                    Navigator.pop(context);
                  }
                },
                child: const Text("Save"),
              ),
            ],
          ),
    );
  }
}
