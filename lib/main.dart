import 'dart:ui';



import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:shared_preferences/shared_preferences.dart';



import 'firebase_options.dart';

import 'utils/theme_notifier.dart';

import 'utils/local_notifications.dart';

import 'screens/auth_screen.dart';



void main() async {

  WidgetsFlutterBinding.ensureInitialized();



  // Инициализация Firebase

  await Firebase.initializeApp(

    options: DefaultFirebaseOptions.currentPlatform,

  );



  // Инициализация локальных уведомлений

  await LocalNotifications.init();



  // Инициализация Supabase (Для медиа)

  await Supabase.initialize(

    url: 'https://qnsgjwweeuciithqmyhh.supabase.co',

    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFuc2dqd3dlZXVjaWl0aHFteWhoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODgyOTU3MDIsImV4cCI6MjEwMzg3MTcwMn0.MOoaS2iHxuA0kufqUokScyr6doYs-BSCG0R-t9bDuHY',

  );



  // Загружаем сохраненную тему до отрисовки приложения (теперь по умолчанию 'Тёмная')

  final prefs = await SharedPreferences.getInstance();

  final savedTheme = prefs.getString('appTheme') ?? 'Тёмная';

  appThemeNotifier.value = savedTheme;



  runApp(const MyApp());

}



ThemeData _getThemeData(String themeName) {

  if (themeName == 'Тёмная') {

    return ThemeData.dark(useMaterial3: true);

  } else if (themeName == 'Зомби') {

    return ThemeData(

      useMaterial3: true,

      brightness: Brightness.dark,

      scaffoldBackgroundColor: const Color(0xFF1a1c17),

      colorScheme: const ColorScheme.dark(

        primary: Color(0xFF6b8e23),

        secondary: Color(0xFF8b0000),

        surface: Color(0xFF25291f),

      ),

      appBarTheme: const AppBarTheme(

        backgroundColor: Color(0xFF11130e),

        foregroundColor: Color(0xFFa1b57d),

      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(

        backgroundColor: Color(0xFF8b0000),

        foregroundColor: Colors.white,

      ),

    );

  } else if (themeName == 'Серый узор') {

    return ThemeData(

      useMaterial3: true,

      brightness: Brightness.dark,

      scaffoldBackgroundColor: const Color(0xFF1E1E1E),

      colorScheme: const ColorScheme.dark(

        primary: Color(0xFF78909C),

        secondary: Color(0xFFB0BEC5),

        surface: Color(0xFF2C2C2C),

      ),

      appBarTheme: const AppBarTheme(

        backgroundColor: Color(0xFF121212),

        foregroundColor: Colors.white,

      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(

        backgroundColor: Color(0xFF78909C),

        foregroundColor: Colors.white,

      ),

    );

  } else if (themeName == 'Бордовый (Кровь)') {

    return ThemeData(

      useMaterial3: true,

      brightness: Brightness.dark,

      scaffoldBackgroundColor: const Color(0xFF180505),

      colorScheme: const ColorScheme.dark(

        primary: Color(0xFFA50000),

        secondary: Color(0xFFFF3333),

        surface: Color(0xFF330A0A),

      ),

      appBarTheme: const AppBarTheme(

        backgroundColor: Color(0xFF110000),

        foregroundColor: Color(0xFFFF5555),

      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(

        backgroundColor: Color(0xFFA50000),

        foregroundColor: Colors.white,

      ),

    );

  }



  return ThemeData.light(useMaterial3: true).copyWith(

    colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),

  );

}



class MyCustomScrollBehavior extends MaterialScrollBehavior {

  @override

  Set<PointerDeviceKind> get dragDevices => {

    PointerDeviceKind.touch,

    PointerDeviceKind.mouse,

    PointerDeviceKind.trackpad,

    PointerDeviceKind.stylus,

  };

}



class MyApp extends StatelessWidget {

  const MyApp({super.key});



  @override

  Widget build(BuildContext context) {

    return ValueListenableBuilder<String>(

      valueListenable: appThemeNotifier,

      builder: (context, themeName, child) {

        return MaterialApp(

          debugShowCheckedModeBanner: false,

          scrollBehavior: MyCustomScrollBehavior(),

          title: 'Мой Мессенджер',

          theme: _getThemeData(themeName),

          home: const AuthScreen(),

        );

      },

    );

  }

}



