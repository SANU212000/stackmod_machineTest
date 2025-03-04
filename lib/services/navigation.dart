import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:stackmod_test/controller/theme_contoller.dart';
import 'package:stackmod_test/controller/todo_controller.dart';
import 'package:stackmod_test/screens/addnewusers.dart';
import 'package:stackmod_test/screens/intro.dart';
import 'package:stackmod_test/screens/loginpage.dart';
import 'package:stackmod_test/screens/todoscreen.dart';

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themechanger = Get.put(ThemeChanger());

    return Obx(
      () => GetMaterialApp(
        title: 'Todo App',
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: themechanger.themeMode.value,
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        getPages: [
          GetPage(name: '/', page: () => const IntroScreen()),
          GetPage(name: '/userScreen', page: () => const LoginScreen()),
          GetPage(name: '/home', page: () => TodoScreen()),
          GetPage(
            name: '/TodoScreen',
            page: () => TodoScreen(),
            binding: BindingsBuilder(() {
              Get.put(TodoController());
            }),
          ),
          GetPage(name: '/register', page: () => AddNewUser()),
        ],
      ),
    );
  }
}
