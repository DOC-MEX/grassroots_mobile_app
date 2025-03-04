import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'home.dart';
import 'models/observation.dart';
import 'package:path_provider/path_provider.dart';
import 'models/photo_submission.dart'; 
import 'theme.dart';
import 'package:provider/provider.dart';
//import 'theme_notifier.dart';


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

  runApp(const MyApp ()
/*
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: MyApp(),
    ),
*/
  );

}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grassroots app',
      theme: light_theme,
      darkTheme: dark_theme,
      //themeMode: themeNotifier.themeMode,
      themeMode: ThemeMode.system,
      home: HomePage(),
    );

/*
    return Consumer<ThemeNotifier>(
      builder:  (context, themeNotifier, child) {
        return MaterialApp(
          title: 'Grassroots app',
          theme: light_theme,
          darkTheme: dark_theme,
          //themeMode: themeNotifier.themeMode,
          themeMode: ThemeMode.system,
          home: HomePage(),
        );
      },
    );

*/
  }

}

