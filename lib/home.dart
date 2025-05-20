import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grassroots_field_trials/global_variable.dart';
import 'welcome_message.dart';
import 'grassroots_studies.dart';
import 'api_requests.dart';

import 'package:hive/hive.dart';
import 'models/observation.dart';
import 'models/photo_submission.dart';
import 'study_creator.dart';


class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String hps_djangoStatus = 'unknown';
  String hps_mongoStatus = 'unknown';

  @override
  void initState() {
    super.initState();

    GrassrootsPageState.CheckAndUpdateAllowedStudyIDs ();
    checkHealthStatus();
    _printLocalObservations(); // Fetch and print local observations
    _printLocalPhotoSubmissions();
  }

  Future<void> _printLocalPhotoSubmissions() async {
    try {
      var box = Hive.box<PhotoSubmission>('photo_submissions'); // Open the Hive box
      List<PhotoSubmission> photoSubmissions = box.values.toList(); // Get all photo submissions
      print('Local Photo Submissions:');
      for (var photo in photoSubmissions) {
        print(photo.toJson()); // Print each photo submission as JSON
      }
    } catch (e) {
      print('Error reading local photo submissions: $e');
    }
  }

  // New method to fetch and print local observations
  Future<void> _printLocalObservations() async {
    try {
      var box = Hive.box<Observation>('observations'); // Open the Hive box
      List<Observation> observations = box.values.toList(); // Get all observations
      print('Local Observations:');
      for (var observation in observations) {
        print(observation.toJson()); // Print each observation as JSON
      }
    } catch (e) {
      print('Error reading local observations: $e');
    }
  }

  Future<void> checkHealthStatus() async {
    print("checkHealthStatus called");
    try {
      final bool old_health_status = _GetServerHealth (false);

      final healthStatus = await ApiRequests.fetchHealthStatus();
      setState(() {
        hps_djangoStatus = healthStatus['django'] ?? 'unknown';
        hps_mongoStatus = healthStatus['mongo'] ?? 'unknown';
      });

      bool new_health_status = _GetServerHealth (false);

      /* Are we back online? */
      if ((!old_health_status) && new_health_status) {
        /* Sync any locally-saved observations */
        SnackBar snack_bar = SnackBar (
          content: Text(
            'Syncing local data',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
        );

        ScaffoldMessenger.of (context).showSnackBar (snack_bar);
        await Observation.SyncLocalObservations ();
        ScaffoldMessenger.of (context).hideCurrentSnackBar ();
      }

      print('Django: $hps_djangoStatus, Mongo: $hps_mongoStatus');
      // Show snackbar if server is unhealthy
      if (hps_djangoStatus != 'running' || hps_mongoStatus != 'available') {
        final String app_url = ApiRequests.GetPhotoReceiverUrl();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Warning: There is a problem with the server connection to ${app_url}. Error ${ApiRequests.latest_error}',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print ('>>>>> e: $e');
      setState(() {
        hps_djangoStatus = 'error';
        hps_mongoStatus = 'error';
      });
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

  bool _GetServerHealth (bool refresh_flag) {
    return ((hps_djangoStatus == 'running') && (hps_mongoStatus == 'available'));
  }

  @override
  Widget build(BuildContext context) {
    bool isServerHealthy = _GetServerHealth (false);
    final String app_url =  ApiRequests.GetPhotoReceiverUrl();
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Grassroots App'),
            Row(
              children: [
                // LED Indicator
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isServerHealthy ? Colors.green : Colors.red,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  isServerHealthy ? 'Server OK' : 'Server Issue',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: checkHealthStatus, // Trigger health check
            tooltip: 'Refresh Server Status',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: checkHealthStatus, // Pull-to-refresh action
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(), // Enable pull-to-refresh
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // Welcome message
                      WelcomeMessageWidget(),

                      Expanded (
                          child: Align (
                            alignment: FractionalOffset.bottomCenter,

                            child: new Container(
                                padding: new EdgeInsets.all (16.0),
                                child: OverflowBar (
                                  spacing: 8,

                                  overflowSpacing: 4,

                                  overflowAlignment: OverflowBarAlignment.end,

                                  children: <Widget> [
                                    ElevatedButton (
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => GrassrootsStudies()),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(vertical: 3, horizontal: 20),
                                      ),
                                      child: Text(
                                        'Browse \n all studies',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),

                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => NewStudyPage ()),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(vertical: 3, horizontal: 20),
                                      ),
                                      child: Text(
                                        'Create Study',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),

                                    ElevatedButton(
                                      onPressed: () {
                                        SystemNavigator.pop();
                                      },
                                      child: Text('Exit'),
                                    ),

                                    /*
                                ElevatedButton(
                                  onPressed: () {
                                    EmptyBox (CACHE_TRIALS);
                                    EmptyBox (CACHE_LOCATIONS);
                                    EmptyBox (CACHE_STUDIES);
                                    EmptyBox (CACHE_MEASURED_VARIABLES);
                                    EmptyBox (CACHE_PROGRAMMES);
                                  },
                                  child: Text('Clear'),
                                ),
                                */

                                  ],

                                )
                            ),

                          )
                      ),

                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void EmptyBox (final String name) async {
    await Hive.deleteBoxFromDisk (name);
  }
}
