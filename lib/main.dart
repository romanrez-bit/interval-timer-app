import 'package:flutter/material.dart';
import 'screens/setup_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Interval Timer',
      theme: ThemeData.dark(),
      home: const SetupScreen(),
    );
  }
}