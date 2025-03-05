import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AWSS3Service {
  final String baseApiUrl = dotenv.env['BASE_API_URL'] ?? 'DEFAULT_VALUE_HERE';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> uploadFile(File file, String userId) async {
    try {
      if (!file.existsSync()) {
        print("❌ Error: File does not exist - ${file.path}");
        return null;
      }

      print("📤 Attempting to upload image: ${file.uri.pathSegments.last}");

      final response = await http.post(
        Uri.parse(baseApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"fileName": file.uri.pathSegments.last}),
      );

      if (response.statusCode != 200) {
        print("❌ Failed to get presigned URL. Response: ${response.body}");
        return null;
      }

      final data = jsonDecode(response.body);
      if (!data.containsKey("url") || !data.containsKey("uploadedFilePath")) {
        print("❌ Invalid response: Missing 'url' or 'uploadedFilePath'");
        return null;
      }

      final String uploadUrl = data["url"];
      final String fileUrl = data["uploadedFilePath"];
      print("🔗 Presigned URL Received: $uploadUrl");

      final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
      final uploadResponse = await http.put(
        Uri.parse(uploadUrl),
        headers: {'Content-Type': mimeType},
        body: await file.readAsBytes(),
      );

      if (uploadResponse.statusCode == 200) {
        print("✅ File successfully uploaded: $fileUrl");
        await _saveProfilePicture(userId, fileUrl);
        return fileUrl;
      } else {
        print(
          "❌ File upload failed. Status Code: ${uploadResponse.statusCode}",
        );
        print("❌ Response Body: ${uploadResponse.body}");
        return null;
      }
    } catch (e, stackTrace) {
      print("❌ Upload error: $e");
      print("Stack trace: $stackTrace");
      return null;
    }
  }

  Future<void> _saveProfilePicture(String userId, String imageUrl) async {
    if (userId.isEmpty || imageUrl.isEmpty) {
      print("❌ Error: User ID or image URL is empty");
      return;
    }

    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        await _firestore.collection('users').doc(userId).update({
          'profileImageUrl': imageUrl,
        });
        print("✅ Profile picture updated successfully");
      } else {
        await _firestore.collection('users').doc(userId).set({
          'username': 'New User',
          'profileImageUrl': imageUrl,
          'createdAt': FieldValue.serverTimestamp(),
        });
        print("✅ New user profile created with image");
      }
    } catch (e) {
      print('❌ Error saving profile picture: $e');
    }
  }

  Future<void> removeProfilePicture(String userId) async {
    if (userId.isEmpty) {
      print("❌ Error: User ID is empty");
      return;
    }

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        print("❌ User not found.");
        return;
      }

      String? imageUrl = userDoc.data()?['profileImageUrl'];
      if (imageUrl != null && imageUrl.isNotEmpty) {
        bool deleted = await deleteFile(imageUrl);
        if (deleted) {
          await _firestore.collection('users').doc(userId).update({
            'profileImageUrl': FieldValue.delete(),
          });
          print("✅ Profile picture removed successfully");
        } else {
          print("❌ Failed to delete file from S3");
        }
      }
    } catch (e) {
      print('❌ Error removing profile picture: $e');
    }
  }

  Future<bool> deleteFile(String fileUrl) async {
    try {
      final response = await http.delete(
        Uri.parse("https://filesapisample.stackmod.info/api/delete-file"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"fileUrl": fileUrl}),
      );

      if (response.statusCode == 200) {
        print("✅ File deleted successfully from AWS S3");
        return true;
      } else {
        print("❌ Failed to delete file. Response: ${response.body}");
        return false;
      }
    } catch (e) {
      print("❌ Error deleting file: $e");
      return false;
    }
  }

  Future<String?> fetchProfilePicture(String userId) async {
    if (userId.isEmpty) {
      print("❌ Error: User ID is empty");
      return null;
    }

    try {
      final docSnapshot =
          await _firestore.collection('users').doc(userId).get();
      if (docSnapshot.exists) {
        return docSnapshot.data()?['profileImageUrl'] as String?;
      }
      return null;
    } catch (e) {
      print('❌ Error fetching profile picture: $e');
      return null;
    }
  }
}
