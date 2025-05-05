
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:grassroots_field_trials/api_requests.dart';
import 'package:http/http.dart' as http;

import 'global_variable.dart';

class StringLabel {
  String name;
  String id;

  StringLabel (this.name, this.id);
}

typedef StringEntry = DropdownMenuEntry <StringLabel>;


enum ServerStatus {
  SS_ONLINE,
  SS_OFFLINE,
  SS_UNKNOWN
}


class ServerConnection {
  static ServerStatus _django_online = ServerStatus.SS_UNKNOWN;
  static ServerStatus _mongo_online = ServerStatus.SS_UNKNOWN;

  static String latest_error = "";

  static bool IsOnline (bool refresh_flag) {
    if (refresh_flag) {
      _FetchHealthStatus ();
    }

    return ((_django_online == ServerStatus.SS_ONLINE) && (_mongo_online == ServerStatus.SS_ONLINE));
  }


  static Future <void> _FetchHealthStatus() async {
    try {
      final String base_url = ApiRequests.GetPhotoReceiverUrl ();

      final response = await http.get(Uri.parse('${base_url}online_check/'));

      if (GrassrootsConfig.debug_flag) {
        print ("called ${base_url}online_check/ got ${response.statusCode}");
      }

      if (response.statusCode == 200) {
        // Parse the JSON response and return it
        final jsonResponse = json.decode (response.body);

        String? s = jsonResponse ["django"];

        if (s != null) {
          if (s == "running") {
            _django_online = ServerStatus.SS_ONLINE;
          } else {
            _django_online = ServerStatus.SS_OFFLINE;
          }
        }

        s = jsonResponse ["mongo"];
        if (s != null) {
          if (s == "available") {
            _django_online = ServerStatus.SS_ONLINE;
          } else {
            _django_online = ServerStatus.SS_OFFLINE;
          }
        }
      } else {
        // Handle non-200 responses

        _django_online = ServerStatus.SS_OFFLINE;
        _mongo_online = ServerStatus.SS_OFFLINE;
      }

    } catch (e) {
      latest_error = e.toString ();
      // Handle errors like network issues
      _django_online = ServerStatus.SS_UNKNOWN;
      _mongo_online = ServerStatus.SS_UNKNOWN;
    }
  }
}