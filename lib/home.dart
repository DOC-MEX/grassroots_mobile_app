import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'welcome_message.dart';
import 'grassroots_studies.dart';
import 'api_requests.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    checkHealthStatus(); // Health check API call
  }

  // Health check function
  Future<void> checkHealthStatus() async {
    final healthStatus = await ApiRequests.fetchHealthStatus();
    print('Django Status: ${healthStatus['django']}');
    print('MongoDB Status: ${healthStatus['mongo']}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Grassroots Mobile App'),
      ),
      body: Stack(
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
    );
  }
}
