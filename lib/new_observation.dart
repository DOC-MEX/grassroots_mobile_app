import 'package:flutter/material.dart';

class NewObservationPage extends StatelessWidget {
  final Map<String, dynamic> studyDetails;
  final String plotId;
  final Map<String, dynamic> plotDetails;

  NewObservationPage({
    required this.studyDetails,
    required this.plotId,
    required this.plotDetails,
  });

  @override
  Widget build(BuildContext context) {
    print('plot: $plotDetails');
    print('plotId: $plotId');
    return Scaffold(
      appBar: AppBar(
        title: Text('New Observation'),
      ),
      body: Center(
        child: Text('new logic here'),
      ),
    );
  }
}
