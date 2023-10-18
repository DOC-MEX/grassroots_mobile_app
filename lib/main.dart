import 'package:flutter/material.dart';
import 'home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Reader',
      theme: ThemeData(
        primaryColor: Color(0xFF2c3e50),
        colorScheme: ThemeData().colorScheme.copyWith(
              primary: Color(0xFF2c3e50),
              secondary: Color(0xFF2c3e50),
            ),
      ),
      home: HomePage(),
    );
  }
}
