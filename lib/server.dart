
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:grassroots_field_trials/api_requests.dart';
import 'package:http/http.dart' as http;

import 'global_variable.dart';
import 'models/observation.dart';

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


class ServerModel extends ChangeNotifier {
  ServerStatus _django_online = ServerStatus.SS_UNKNOWN;
  ServerStatus _mongo_online = ServerStatus.SS_UNKNOWN;

  bool _combined_state = false;

  String latest_error = "";

  ServerModel () {
    CheckStatus ();
  }



  Future <void> CheckStatus() async {
    final ServerStatus old_django_online = _django_online;
    final ServerStatus old_mongo_online = _mongo_online;

    await _FetchHealthStatus();

    if (GrassrootsConfig.log_level >= LOG_INFO) {
      print ("_django_online to ${_django_online}");
      print ("_mongo_online to ${_mongo_online}");
    }

    if ((old_mongo_online != _mongo_online) ||
        (old_django_online != _django_online)) {
      // This call tells the widgets that are listening to this model to rebuild.
      notifyListeners();
    }
  }


  bool GetCombinedState () {
    return ((_django_online == ServerStatus.SS_ONLINE) &&
        (_mongo_online == ServerStatus.SS_ONLINE));
  }



  Future <void> _FetchHealthStatus() async {
    try {
      final String base_url = ApiRequests.GetPhotoReceiverUrl();

      final response = await http.get(Uri.parse('${base_url}online_check/'));

      if (GrassrootsConfig.log_level >= LOG_FINER) {
        print("called ${base_url}online_check/ got ${response.statusCode}");
      }

      if (response.statusCode == 200) {
        // Parse the JSON response and return it
        final jsonResponse = json.decode(response.body);

        if (GrassrootsConfig.log_level >= LOG_FINER) {
          print("response: $jsonResponse");
        }

        String? s = jsonResponse ["django"];

        if (GrassrootsConfig.log_level >= LOG_FINER) {
          if (s != null) {
            print("django: ${s}");
          } else {
            print("django NULL");
          }
        }

        if (s != null) {
          if (s == "running") {
            _django_online = ServerStatus.SS_ONLINE;

            if (GrassrootsConfig.log_level >= LOG_FINER) {
              print("setting _django_online to SS_ONLINE");
            }
          } else {
            _django_online = ServerStatus.SS_OFFLINE;

            if (GrassrootsConfig.log_level >= LOG_FINER) {
              print("setting _django_online to SS_OFFLINE");
            }
          }
        }

        s = jsonResponse ["mongo"];

        if (GrassrootsConfig.log_level >= LOG_FINER) {
          if (s != null) {
            print("mongo: ${s}");
          } else {
            print("mongo NULL");
          }
        }

        if (s != null) {
          if (s == "available") {
            _mongo_online = ServerStatus.SS_ONLINE;

            if (GrassrootsConfig.log_level >= LOG_FINER) {
              print("setting _django_online to SS_ONLINE");
            }

          } else {
            _mongo_online = ServerStatus.SS_OFFLINE;

            if (GrassrootsConfig.log_level >= LOG_FINER) {
              print("setting _django_online to SS_OFFLINE");
            }

          }
        }
      } else {
        // Handle non-200 responses

        _django_online = ServerStatus.SS_OFFLINE;
        _mongo_online = ServerStatus.SS_OFFLINE;

        if (GrassrootsConfig.log_level >= LOG_FINER) {
          print("setting _mongo_online to SS_OFFLINE");
          print("setting _django_online to SS_OFFLINE");
        }

      }
    } catch (e) {
      latest_error = e.toString();
      // Handle errors like network issues
      _django_online = ServerStatus.SS_UNKNOWN;
      _mongo_online = ServerStatus.SS_UNKNOWN;

      if (GrassrootsConfig.log_level >= LOG_FINER) {
        print("setting _mongo_online to SS_UNKNOWN");
        print("setting _django_online to SS_UNKNOWN");
      }

    }
  }
}

class ServerConnectionWidget extends StatefulWidget implements PreferredSizeWidget {

  @override
  final Size preferredSize;

  @override
  ServerConnectionWidgetState createState() => ServerConnectionWidgetState ();

  ServerConnectionWidget(String title) :
    preferredSize = Size.fromHeight (kToolbarHeight) {

    //_scw_state.SetText (title);
  }

  Future <void> CheckHealthStatus () async {

  }


}


class ServerConnectionWidgetState extends State <ServerConnectionWidget> {


  static String latest_error = "";

  String _title = "";
  ServerModel _model = ServerModel();

  bool _combined_state = false;


  ServerConnectionWidgetState () {
    IsOnline (true);
  }

  Future <bool> IsOnline(bool refresh_flag) async {
    if (refresh_flag) {
      await _model.CheckStatus ();
      _combined_state = _model.GetCombinedState ();
    }

    if (GrassrootsConfig.log_level >= LOG_INFO) {
      print ("IsOnline () returning _combined_state ${_combined_state}");
    }
    return _combined_state;
  }



  void SetText(String text) {
    _title = text;
  }

  Widget build(BuildContext context) {

    if (GrassrootsConfig.log_level >= LOG_INFO) {
      print ("building with _combined_state ${_combined_state}");
    }

    return AppBar(
      title: Text(_title),
      actions: [
        // LED Indicator
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _combined_state ? Colors.green : Colors.red,
          ),
        ),
        SizedBox(width: 8),
        Text(
          _combined_state ? 'Server OK' : 'Server Issue',
          style: TextStyle(fontSize: 14),
        ),


        IconButton(
          icon: Icon(Icons.refresh),
          onPressed: () async {
            // Trigger health check

            print("pressed");
            _combined_state = await checkHealthStatus();
            print("pressed 2");
          },
          tooltip: 'Refresh Server Status',
        ),

      ],
    );
  }


  Future<bool> checkHealthStatus() async {
    if (mounted) {
      print("checkHealthStatus called");
      try {
        final bool old_health_status = await IsOnline (false);

        await IsOnline (true);

        /* Are we back online? */
        if ((!old_health_status) && _combined_state) {
          /* Sync any locally-saved observations */
          SnackBar snack_bar = SnackBar(
            content: Text(
              'Syncing local data',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          );

          ScaffoldMessenger.of(context).showSnackBar(snack_bar);
          await Observation.SyncLocalObservations();
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        }

        print('_combined_state: $_combined_state');
        // Show snackbar if server is unhealthy
        if (!_combined_state) {
          final String app_url = ApiRequests.GetPhotoReceiverUrl();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Warning: There is a problem with the server connection to ${app_url}. Error ${ApiRequests
                    .latest_error}',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      } catch (e) {
        print('>>>>> e: $e');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error checking server status. Please try again.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
    return IsOnline(false);
  }
}