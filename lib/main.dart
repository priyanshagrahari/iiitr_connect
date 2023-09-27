import 'package:flutter/material.dart';
import 'package:iiitr_connect/views/login.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IIITR Connect',
      theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 43, 45, 127)),
          fontFamily: 'Lato'
        ),
      home: const LoginPage(),
    );
  }
}
