import 'package:flutter/material.dart';
import 'views/jacha_yachay_home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jacha Yachay',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4285F4),
          brightness: Brightness.dark,
        ),
      ),
      home: const JachaYachayHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

