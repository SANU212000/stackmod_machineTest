import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stackmod_test/controller/auth_fb.dart';
import 'package:stackmod_test/screens/constants.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final obscureText = true.obs;
    final isLoading = false.obs;

    InputDecoration buildInputDecoration(String label) {
      return InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: kPrimaryColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kPrimaryColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock, size: 80, color: Colors.white),
                  const SizedBox(height: 20),
                  const Text(
                    'Welcome to Pandora',
                    style: TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: "intro",
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.all(25.0),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 30,
                      child: Padding(
                        padding: const EdgeInsets.all(26.0),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: emailController,
                              decoration: buildInputDecoration('Email'),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                final emailRegex = RegExp(
                                  r'^[^@]+@[^@]+\.[^@]+',
                                );
                                if (!emailRegex.hasMatch(value)) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            Obx(() {
                              return TextFormField(
                                controller: passwordController,
                                decoration: buildInputDecoration(
                                  'Password',
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      obscureText.value
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                    onPressed: () {
                                      obscureText.value = !obscureText.value;
                                    },
                                  ),
                                ),
                                obscureText: obscureText.value,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  return null;
                                },
                              );
                            }),
                            const SizedBox(height: 20),
                            Obx(() {
                              return isLoading.value
                                  ? const CircularProgressIndicator()
                                  : ElevatedButton(
                                    onPressed: () async {
                                      if (formKey.currentState!.validate()) {
                                        isLoading.value = true;
                                        final result = await AuthMethods()
                                            .signInWithEmailAndPassword(
                                              email: emailController.text,
                                              password: passwordController.text,
                                              context: context,
                                            );
                                        isLoading.value = false;

                                        if (result != null) {
                                          Navigator.pushReplacementNamed(
                                            context,
                                            '/TodoScreen',
                                          );
                                        } else {
                                          // You can uncomment the Snackbar here if needed
                                          // ScaffoldMessenger.of(context).showSnackBar(
                                          //   const SnackBar(
                                          //     content: Text(
                                          //       'Invalid email or password',
                                          //     ),
                                          //   ),
                                          // );
                                        }
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      iconColor: kWhiteColor,
                                      backgroundColor: kPrimaryColor,
                                      elevation: 10,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                        horizontal: 44,
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    child:
                                        isLoading.value
                                            ? const CircularProgressIndicator(
                                              color: Colors.white,
                                            )
                                            : const Text(
                                              'Sign In',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                  );
                            }),
                            TextButton(
                              onPressed: () async {
                                String email = emailController.text.trim();
                                print('Reset password email: $email');

                                if (email.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please enter your email to reset password',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                AuthMethods authMethods = AuthMethods();
                                await authMethods.resetPassword(
                                  email: email,
                                  context: context,
                                );
                              },
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/register');
                              },
                              child: const Text(
                                'New User? Register here',
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
