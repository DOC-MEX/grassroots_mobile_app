import 'package:flutter/material.dart';

final ThemeData light_theme = ThemeData(
  brightness: Brightness.light,
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
    backgroundColor: Colors.white, // Set the AppBar color
    foregroundColor: Color(0xFF2c3e50),  // Set the AppBar icon and text color
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.grey, // Button background color
      foregroundColor: Color(0xFF2c3e50), // Text and icon color
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4.0),
      borderSide: BorderSide(color: Color(0xFF2c3e50)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4.0),
      borderSide: BorderSide(color: Color(0xFF2c3e50)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4.0),
      borderSide: BorderSide(
          color:
              Color(0xFF2c3e50)
      ), // Use primary color for focused border
    ),
  ),
);


final ThemeData dark_theme = ThemeData(
  primaryColor: Colors.white,
  colorScheme: ColorScheme.fromSwatch(
    primarySwatch: Colors
      .blueGrey, // Adjust to a swatch that matches your primary color if needed
  ).copyWith(
    secondary: Colors.white,
    primary: Colors.white,
    surface: Color(0xFF2c3e50), // Set the background color to white
    brightness: Brightness.dark,
  ),
  scaffoldBackgroundColor: Colors.black, // Set the default background color for Scaffold widgets to white
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
      borderSide: BorderSide(color: Colors.white),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4.0),
      borderSide: BorderSide(color: Colors.white),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(4.0),
      borderSide: BorderSide(
          color: Colors.white, // Use primary color for focused border
      ),
    ),
  ),
);
