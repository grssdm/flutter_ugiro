import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'home_page.dart';

PackageInfo? packageInfo;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  packageInfo = await PackageInfo.fromPlatform();

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
      home: HomePage(packageInfo!),
      debugShowCheckedModeBanner: false,
    );
  }
}
