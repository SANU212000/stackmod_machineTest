import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stackmod_test/controller/todo_controller.dart';
import 'package:stackmod_test/controller/user_controller.dart';
import 'package:stackmod_test/screens/loginpage.dart';
import 'package:uuid/uuid.dart';

class AuthMethods {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _firebaseAuth.currentUser;
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(email);
  }

  bool isValidPassword(String password) {
    return password.isNotEmpty && password.length >= 6;
  }

  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      UserCredential result = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!result.user!.emailVerified) {
        showDialog(
          context: context,
          builder:
              (_) => AlertDialog(
                title: const Text("Email Not Verified"),
                content: const Text("Please verify your email to continue."),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("OK"),
                  ),
                ],
              ),
        );

        await signOut(context);

        return null;
      }

      String newSessionId = const Uuid().v4();
      await _firestore.collection('users').doc(result.user!.uid).update({
        'sessionId': newSessionId,
      });

      UserController userController = Get.find<UserController>();
      await userController.fetchUserDetails();

      print(
        "✅ User logged in: ${userController.username.value}, userId: ${userController.userId.value}",
      );

      return result;
    } catch (e) {
      if (e is FirebaseAuthException) {
        if (e.code == 'wrong-password') {
          showDialog(
            context: context,
            builder:
                (_) => AlertDialog(
                  title: const Text("Incorrect Password"),
                  content: const Text("The password you entered is incorrect."),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text("OK"),
                    ),
                  ],
                ),
          );
        } else {
          showDialog(
            context: context,
            builder:
                (_) => AlertDialog(
                  title: const Text("Error"),
                  content: Text(
                    e.message ?? "An error occurred during sign-in.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text("OK"),
                    ),
                  ],
                ),
          );
        }
      } else {
        showDialog(
          context: context,
          builder:
              (_) => AlertDialog(
                title: const Text("Error"),
                content: const Text("An error occurred during sign-in."),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("OK"),
                  ),
                ],
              ),
        );
      }

      print('Error during sign-in: $e');
      return null;
    }
  }

  Future<UserCredential?> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
    required BuildContext context,
    required String phoneNumber,
  }) async {
    try {
      if (!isValidEmail(email)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invalid email address.')));
        return null;
      }

      if (!isValidPassword(password)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password must be at least 6 characters long.'),
          ),
        );
        return null;
      }

      UserCredential result = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      await sendEmailVerification(result.user!);

      await saveUserData(
        uid: result.user!.uid,
        email: email,
        username: username,
        phoneNumber: phoneNumber,
        verified: false,
        profileImageUrl: '',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Account created successfully! Please check your email for verification.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
        ),
      );

      return result;
    } catch (e) {
      print('Error during sign-up: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign-up failed. Please try again.')),
      );
      return null;
    }
  }

  Future<void> resetPassword({
    required String email,
    required BuildContext context,
  }) async {
    if (email.isEmpty || !isValidEmail(email)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid email address.')));
      return;
    }

    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset email sent to $email.')),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
    }
  }

  Future<void> sendEmailVerification(User user) async {
    try {
      await user.sendEmailVerification();
      print('Verification email sent to ${user.email}');

      await Future.delayed(const Duration(seconds: 2));
      await user.reload();
      user = FirebaseAuth.instance.currentUser!;

      if (user.emailVerified) {
        await updateEmailVerifiedStatus();
      }
    } catch (e) {
      print('Error sending verification email: $e');
    }
  }

  Future<void> updateEmailVerifiedStatus() async {
    User? user = _firebaseAuth.currentUser;
    if (user != null && user.emailVerified) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'verified': true,
        });
        print('User verification status updated.');
      } catch (e) {
        print('Error updating verification status: $e');
      }
    }
  }

  Future<void> saveUserData({
    required String uid,
    required String email,
    required String username,
    required String phoneNumber,
    required bool verified,
    required String profileImageUrl,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'username': username,
        'phoneNumber': phoneNumber,
        'verified': verified,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print("User data saved successfully.");
    } catch (e) {
      print("Error saving user data: $e");
    }
  }

  Future<void> signOut(BuildContext context) async {
    try {
      bool? confirmSignOut = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Confirm Sign-Out'),
            content: const Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Sign Out'),
              ),
            ],
          );
        },
      );

      if (confirmSignOut == true) {
        await _firebaseAuth.signOut();
        Get.find<TodoController>().todos.clear();

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.remove('auth_token');
        await prefs.remove('userId');

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully signed out.')),
        );
      }
    } catch (e) {
      print('Error during sign-out: $e');
    }
  }
}
