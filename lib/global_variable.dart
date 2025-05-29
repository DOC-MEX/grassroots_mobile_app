// global_variables.dart
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:global_configuration/global_configuration.dart';


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

final int LOG_INFO = 10;
final int LOG_FINE = 20;
final int LOG_FINER = 30;
final int LOG_FINEST = 40;


class GrassrootsConfig {

  static int log_level = LOG_FINE;


  static Future <void> LoadConfig () async {
    await GlobalConfiguration ().loadFromAsset ("config");

    /* Load any custom config if it exists */
    try {
      await GlobalConfiguration ().loadFromAsset ("custom_config");
    } catch (e) {
      if (GrassrootsConfig.log_level >= LOG_FINEST) {
        print ("custom_config.json not found");
      }
    }
  }


  static String? GetPublicBackendURL () {
    return _GetBackendURL ("public");
  }

  static String? GetPrivateBackendURL () {
    return _GetBackendURL ("private");
  }

  static String? GetAdminBackendURL () {
    return _GetBackendURL ("queen_bee");
  }


  static String? GetPhotoReceiverURL () {
    return _GetBackendURL ("photo_receiver");
  }

  static String? GetHost () {
    return GlobalConfiguration().getValue ("host");
  }


  static String? _GetBackendURL (String key) {
    String? url = null;
    String? host = GetHost ();

    if (host != null) {
      Map <String, dynamic> ? host_config = GlobalConfiguration ().getValue (host);

      if (host_config != null) {
        String? sub_url = host_config [key];

        if (sub_url != null) {
          if (host.endsWith ("/")) {
            url = "${host}${sub_url}";
          } else {
            url = "${host}/${sub_url}";
          }
        }
      }
    }

    return url;
  }


  static Map <String, dynamic> ? _GetHostConfig () {
    Map <String, dynamic> ? host_config = null;
    String? host = GetHost ();

    if (host != null) {
      host_config = GlobalConfiguration ().getValue (host);
    }

    return host_config;
  }



}
