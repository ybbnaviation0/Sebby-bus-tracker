import 'package:flutter/material.dart';
import 'pages/map_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SebbyBusApp());
}

class SebbyBusApp extends StatelessWidget {
  const SebbyBusApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sebby Bus Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      home: const MapPage(),
    );
  }
}
