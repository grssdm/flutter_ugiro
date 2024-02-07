import 'package:flutter/material.dart';

import 'home_page.dart';

void main() {
  runApp(const UgiroApp());
}

class UgiroApp extends StatelessWidget {
  const UgiroApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ugiro',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
