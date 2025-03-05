import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stackmod_test/controller/theme_contoller.dart';
import 'package:stackmod_test/controller/todo_controller.dart';
import 'package:stackmod_test/services/firebase_options.dart';
import 'package:stackmod_test/services/navigation.dart';
import 'package:stackmod_test/controller/user_controller.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// import 'package:stackmod_test/services/notification_services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  print(dotenv.env); 
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  Get.put(UserController());
  Get.put(TodoController());

  final themeChanger = Get.put(ThemeChanger());
  await themeChanger.loadtheme();
  // await NotificationService.init();

  runApp(TodoApp());
}
