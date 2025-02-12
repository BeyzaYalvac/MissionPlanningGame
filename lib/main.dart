import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:to_gram_grad_project/view/homepage.dart';
import 'package:to_gram_grad_project/view/login.dart';
import 'package:to_gram_grad_project/view/register.dart';

import 'firebase_options.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _changeTheme(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/login': (context) => Login(),
        '/register': (context) => Register(),

      },
      title: 'ToGram',

      home: Login(),
    );
  }
}


