import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'welcome_message.dart';
import 'grassroots_studies.dart';
import 'api_requests.dart';

import 'package:hive/hive.dart';
import 'models/observation.dart';
import 'models/photo_submission.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String djangoStatus = 'unknown';
  String mongoStatus = 'unknown';

  @override
  void initState() {
    super.initState();
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
      final healthStatus = await ApiRequests.fetchHealthStatus();
      setState(() {
        djangoStatus = healthStatus['django'] ?? 'unknown';
        mongoStatus = healthStatus['mongo'] ?? 'unknown';
      });
      print('Django: $djangoStatus, Mongo: $mongoStatus');
      // Show snackbar if server is unhealthy
      if (djangoStatus != 'running' || mongoStatus != 'available') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Warning: There is a problem with the server connection.',
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
        djangoStatus = 'error';
        mongoStatus = 'error';
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

  @override
  Widget build(BuildContext context) {
    bool isServerHealthy = djangoStatus == 'running' && mongoStatus == 'available';

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
                  child: Stack(
                    children: [
                      // Welcome message
                      WelcomeMessageWidget(),

                      // Exit button
                      Positioned(
                        bottom: 15,
                        left: 10,
                        child: ElevatedButton(
                          onPressed: () {
                            SystemNavigator.pop();
                          },
                          child: Text('Exit'),
                        ),
                      ),

                      // Browse all studies button
                      Positioned(
                        bottom: 15,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: ElevatedButton(
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
                        ),
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
}
