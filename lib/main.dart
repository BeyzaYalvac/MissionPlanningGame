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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/login': (context) => Login(),
        '/register': (context) => Register(),

      },
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme(
            brightness: Brightness.light,
            primary: Color(0xff3B1E54),
            onPrimary: Color(0xff9B7EBD),
            secondary: Color(0xff3b5ef9),
            onSecondary: Color(0xffD4BEE4),
            error: Color(0xff28105b),
            onError: Color(0xff3b5ef9),
            surface: Color(0xffEEEEEE),
            onSurface: Color(0xff3b5ef9)),
        useMaterial3: true,
      ),
      home: Login(),
    );
  }
}


