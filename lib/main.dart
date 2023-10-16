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
        primarySwatch:
            Colors.blue, // You can keep this as the default blue or choose another color for other parts of your app
        primaryColor: Color(0xFF2c3e50),
      ),
      //home: const QRReaderScreen(),
      home: HomePage(),
    );
  }
}
