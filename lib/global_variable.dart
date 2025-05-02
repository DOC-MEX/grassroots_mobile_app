// global_variables.dart
import 'dart:convert';

import 'package:flutter/services.dart';


List<String> allowedStudyIDs = [
  '64f1e4e77c486e019b4e3017',
  '63bfce1a86ff5b59175e1d66',   // Study 1. Testing/debugging
  '65a532e1536b7214e714a97f', // Glasshouse test study
];

final int HI_OBSERVATIONS = 1;
final int HI_PHOTOS = 2;
final int HI_STUDIES = 3;
final int HI_ALLOWED_IDS = 4;

final String CACHE_STUDIES = "studies_cache";
final String CACHE_TRIALS = "trials_cache";
final String CACHE_LOCATIONS = "locations_cache";
final String CACHE_PROGRAMMES = "programmes_cache";
final String CACHE_MEASURED_VARIABLES = "measured_variables_cache";
final String LOCAL_ALLOWED_STUDIES = "local_allowed_studies";
final String CACHE_SERVER_ALLOWED_STUDIES = "server_allowed_studies_cache";



class GrassrootsConfig {
  static Map <String, String>? _config;

  static bool debug_flag = false;

  static Future <Map <String, String>?> LoadConfig () async {
    if (_config == null) {
      final String config_path = "assets/config.json";

      try {
        final String config_data = await rootBundle.loadString (config_path);
        _config = json.decode (config_data);
    
      } on Exception {
        print ("Could not load ${config_path}");
      }
    }

    return _config;
  }


  static Future <String?> GetConfigValue (String key) async {
    Map <String, dynamic>? config = await LoadConfig ();

    if (config != null) {
      return config [key];
    } else {
      return null;
    }
  }

  static Future <String?> GetPublicBackendURL () {
    return GetConfigValue ("public");
  }

  static Future <String?> GetPrivateBackendURL () {
    return GetConfigValue ("private");
  }


}
