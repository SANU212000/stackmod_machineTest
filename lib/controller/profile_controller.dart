import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stackmod_test/services/awsserives.dart';
import 'package:stackmod_test/controller/user_controller.dart';

class ProfileController extends GetxController {
  final UserController userController = Get.find<UserController>();
  var isUploading = false.obs;

  Future<void> pickAndUploadImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile == null) return;

    File file = File(pickedFile.path);
    isUploading.value = true;

    try {
      String? uploadedUrl = await AWSS3Service().uploadFile(
        file,
        userController.userId.value,
      );
      if (uploadedUrl != null) {
        await userController.fetchUserDetails(); 
      }
    } catch (e) {
      print('❌ Error uploading image: $e');
    } finally {
      isUploading.value = false;
    }
  }

  Future<void> deleteProfileImage() async {
    if (userController.profileImageUrl.isEmpty) return;

    try {
      await AWSS3Service().removeProfilePicture(userController.userId.value);
      await userController.fetchUserDetails(); 
    } catch (e) {
      print('❌ Error deleting profile image: $e');
    }
  }

 
  void signOut(BuildContext context) {
    userController.signOut();
  }
}
