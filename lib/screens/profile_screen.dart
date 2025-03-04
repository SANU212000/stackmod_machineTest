import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stackmod_test/controller/profile_controller.dart';
import 'package:stackmod_test/controller/theme_contoller.dart';
import 'package:stackmod_test/controller/user_controller.dart';
import 'package:stackmod_test/screens/constants.dart';

class ProfileScreen extends StatelessWidget {
  final UserController userController = Get.put(UserController());
  final ProfileController profileController = Get.put(ProfileController());

  ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        title: const Text("Profile"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => userController.editUserName(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => userController.signOut(),
          ),
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () {
              final themeProvider = Get.find<ThemeChanger>();

              if (themeProvider.themeMode.value == ThemeMode.light) {
                themeProvider.setTheme(ThemeOption.dark);
              } else {
                themeProvider.setTheme(ThemeOption.light);
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Obx(
                () => Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage:
                          userController.profileImageUrl.isNotEmpty
                              ? NetworkImage(
                                userController.profileImageUrl.value,
                              )
                              : null,
                      backgroundColor: kPrimaryColor,
                      child:
                          userController.profileImageUrl.isEmpty
                              ? const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.white,
                              )
                              : null,
                    ),
                    if (profileController.isUploading.value)
                      const Positioned.fill(
                        child: Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              Obx(
                () => Text(
                  userController.username.value.isNotEmpty
                      ? userController.username.value
                      : "Guest User",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Obx(
                () => Text(
                  userController.email.value.isNotEmpty
                      ? userController.email.value
                      : "No Email",
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ),
              const SizedBox(height: 10),
              Obx(
                () => Text(
                  userController.joiningDate.value.isNotEmpty
                      ? "Joined: ${userController.joiningDate.value}"
                      : "Joining Date: Unknown",
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: profileController.pickAndUploadImage,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Change Photo"),
                  ),
                  const SizedBox(width: 10),
                  Obx(
                    () =>
                        userController.profileImageUrl.isNotEmpty
                            ? ElevatedButton.icon(
                              onPressed: profileController.deleteProfileImage,
                              icon: const Icon(Icons.delete, color: Colors.red),
                              label: const Text("Remove"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.red,
                              ),
                            )
                            : Container(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
