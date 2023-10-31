import 'package:flutter/material.dart';

class ObservationPage extends StatefulWidget {
  final String studyName;
  final String serverResponse;
  final List<String> phenotypeNames;
  final List<String> traits;

  ObservationPage({
    required this.studyName,
    required this.serverResponse,
    required this.phenotypeNames,
    required this.traits,
  });

  @override
  _ObservationPageState createState() => _ObservationPageState();
}

class _ObservationPageState extends State<ObservationPage> {
  String? accession;

  @override
  void initState() {
    super.initState();
    _parseServerResponse();
  }

  TextEditingController measurementController = TextEditingController();
  String? selectedTrait;
  DateTime? selectedDate;
  DateTime? selectedEndDate;

  // Parse the serverResponse to extract the Accession value
  void _parseServerResponse() {
    final matches = RegExp(r'Accession: ([^\n]+)').allMatches(widget.serverResponse);
    if (matches.isNotEmpty && matches.first.groupCount >= 1) {
      accession = matches.first.group(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Observation')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Study Name: ${widget.studyName}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              Text('Details: ${widget.serverResponse}', textAlign: TextAlign.center),

              DropdownButtonFormField<String>(
                value: selectedTrait,
                hint: Text("List of traits in study"),
                onChanged: (newValue) {
                  setState(() {
                    selectedTrait = newValue!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a trait';
                  }
                  return null;
                },
                items: List<DropdownMenuItem<String>>.generate(
                  widget.phenotypeNames.length,
                  (index) => DropdownMenuItem<String>(
                    value: widget.phenotypeNames[index],
                    child: Text(
                      widget.traits[index],
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                  ),
                ),
              ),

              TextFormField(
                controller: measurementController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: "Add measurement",
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a measurement';
                  }
                  return null;
                },
              ),

              // Date Picker inputs for start and end date would go here ...

              SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  // Handle form submission logic here
                },
                child: Text('Submit Observation'),
              )
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(context);
        },
        child: Icon(Icons.arrow_back),
      ),
    );
  }
}
