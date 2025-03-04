
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeOption { light, dark }

class ThemeChanger extends GetxController {
  var themeMode = ThemeMode.system.obs;

  void setTheme(ThemeOption themeOption) {
    switch (themeOption) {
      case ThemeOption.light:
        themeMode.value = ThemeMode.light;
        break;
      case ThemeOption.dark:
        themeMode.value = ThemeMode.dark;
        break;
    }
    savetheme();
  }

  void savetheme() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    await pref.setString('themedata', themeMode.value.toString());
    print('Saved theme: ${themeMode.value}');
  }

  Future<void> loadtheme() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    final savedtheme = pref.getString('themedata');
    if (savedtheme != null) {
      themeMode.value = ThemeMode.values.firstWhere(
        (element) => element.toString() == savedtheme,
        orElse: () => ThemeMode.system,
      );
    }
    print('Loaded theme: ${themeMode.value}');
  }
}