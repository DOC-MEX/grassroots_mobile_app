import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'home.dart';
import 'models/observation.dart';
import 'package:path_provider/path_provider.dart';
import 'models/photo_submission.dart'; 

void main() async{
  WidgetsFlutterBinding.ensureInitialized(); // Ensures Flutter is ready before Hive initialization
  await Hive.initFlutter(); // Initializes Hive for Flutter

  // Register all adapters
  Hive.registerAdapter(ObservationAdapter());
  Hive.registerAdapter(PhotoSubmissionAdapter());

  // Open boxes for models
  ////await Hive.deleteBoxFromDisk('observations'); // This will clear all old data
  await Hive.openBox<Observation>('observations');
  await Hive.openBox<PhotoSubmission>('photo_submissions');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grassroots app',
      theme: ThemeData(
        primaryColor: Color(0xFF2c3e50),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors
              .blueGrey, // Adjust to a swatch that matches your primary color if needed
        ).copyWith(
          secondary: Color(0xFF2c3e50),
          primary: Color(0xFF2c3e50),
          surface: Colors.white, // Set the background color to white
        ),
        scaffoldBackgroundColor: Colors
            .white, // Set the default background color for Scaffold widgets to white
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF2c3e50), // Set the AppBar color
          foregroundColor: Colors.white, // Set the AppBar icon and text color
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF2c3e50), // Button background color
            foregroundColor: Colors.white, // Text and icon color
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4.0),
            borderSide: BorderSide(color: Colors.grey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4.0),
            borderSide: BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4.0),
            borderSide: BorderSide(
                color:
                    Color(0xFF2c3e50)), // Use primary color for focused border
          ),
        ),
      ),
      home: HomePage(),
    );
  }
}
