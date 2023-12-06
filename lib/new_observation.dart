//name: NewObservationPage  (new_observation.dart)
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NewObservationPage extends StatefulWidget {
  final Map<String, dynamic> studyDetails;
  final String plotId;
  final Map<String, dynamic> plotDetails;

  NewObservationPage({
    required this.studyDetails,
    required this.plotId,
    required this.plotDetails,
  });

  @override
  _NewObservationPageState createState() => _NewObservationPageState();
}

class _NewObservationPageState extends State<NewObservationPage> {
  Map<String, String> traits = {};
  Map<String, String> units = {};
  Map<String, String> scales = {};
  String? selectedTraitKey;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _textEditingController = TextEditingController();
  DateTime? selectedDate;
  //TextInputType _inputType = TextInputType.number;

  @override
  void initState() {
    super.initState();
    _extractPhenotypeDetails();
  }

  void _extractPhenotypeDetails() {
    if (widget.studyDetails['results'][0]['results'][0]['data'].containsKey('phenotypes')) {
      var phenotypes = widget.studyDetails['results'][0]['results'][0]['data']['phenotypes'] as Map<String, dynamic>;
      phenotypes.forEach((key, value) {
        if (value.containsKey('definition')) {
          var definition = value['definition'];
          traits[key] = definition['trait']['so:name'];
          units[key] = definition['unit']['so:name'];
          if (definition.containsKey('scale')) {
            scales[key] = definition['scale']['so:name'];
          }
        }
      });
    }
    //print plotID
    //print('Plot ID: ${widget.plotId}');
    //print plotDetails
    //print('Plot Details: ${widget.plotDetails}');
    print('Traits: $traits');
    print('Units: $units');
    print('Scales: $scales');
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2025),
    );
    if (picked != null && picked != DateTime.now()) {
      setState(() {
        _textEditingController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Observation'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              DropdownButtonFormField<String>(
                value: selectedTraitKey,
                hint: Text("Select a trait"),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedTraitKey = newValue;
                    // Retrieve scale and unit for the selected trait
                    //String? selectedScale = scales[selectedTraitKey];
                    String? selectedUnit = units[selectedTraitKey];

                    // Determine the appropriate input type
                    if (selectedUnit == 'day') {
                      // _inputType = TextInputType.datetime;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          duration: Duration(seconds: 3),
                          content: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.yellow),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Enter number of days or select a date",
                                  style: TextStyle(fontSize: 16.0),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    } // else {
                    //  _inputType = TextInputType.number;
                    // }
                  });

                  // Retrieve and print scale and unit for the selected trait
                  String? selectedScale = scales[selectedTraitKey];
                  String? selectedUnit = units[selectedTraitKey];
                  print('Selected Trait: $selectedTraitKey');
                  print('Scale: $selectedScale');
                  print('Unit: $selectedUnit');
                },
                items: traits.keys.map<DropdownMenuItem<String>>((String key) {
                  return DropdownMenuItem<String>(
                    value: key,
                    child: Text(traits[key] ?? 'Unknown'),
                  );
                }).toList(),
                validator: (value) => value == null ? 'Please select a trait' : null,
              ),
              SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end, // Align the TextFormField and Text vertically
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _textEditingController,
                      keyboardType: (units[selectedTraitKey] == 'day')
                          ? TextInputType.number
                          : TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Enter value',
                        hintText: (units[selectedTraitKey] == 'day')
                            ? 'Enter number of days or select a date'
                            : 'Enter value',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a value';
                        }
                        if (units[selectedTraitKey] == '%') {
                          final num? numberValue = num.tryParse(value);
                          if (numberValue == null) {
                            return 'Please enter a valid number';
                          }
                          if (numberValue < 0 || numberValue > 100) {
                            return 'Value must be between 0 and 100';
                          }
                        }
                        // Additional validation based on selected trait...
                        return null;
                      },
                    ),
                  ),
                  // Conditionally display the unit next to the TextFormField
                  if (units[selectedTraitKey] != null && units[selectedTraitKey]!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        units[selectedTraitKey] ?? '', // Display the unit
                        style: TextStyle(fontSize: 16), // Adjust styling as needed
                      ),
                    ),

                  if (units[selectedTraitKey] == 'day')
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0), // Add padding to left and right
                      child: IconButton(
                        icon: Icon(Icons.calendar_today),
                        onPressed: () => _selectDate(context),
                        iconSize: 30,
                      ),
                    ),
                ],
              ),
              //////////// Date Picker  //////////////
              SizedBox(height: 20),
              ListTile(
                title: Text("Select date"),
                subtitle: Text(
                  selectedDate != null ? '${selectedDate!.toLocal()}'.split(' ')[0] : 'No date chosen',
                ),
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2000), // Adjust the range as needed
                    lastDate: DateTime(2101),
                  );
                  if (picked != null && picked != selectedDate)
                    setState(() {
                      selectedDate = picked;
                    });
                },
              ),
              //////////// Date Picker  //////////////
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // If no date is selected, set it to the current date

                    //print selected date
                    print('Selected Date: ${DateFormat('yyyy-MM-dd').format(selectedDate ?? DateTime.now())}');
                    //print selected trait
                    print('Selected Trait: $selectedTraitKey');
                    //print entered value
                    print('Entered Value: ${_textEditingController.text}');

                    // Clear the form and reset the state
                    _formKey.currentState!.reset();
                    _textEditingController.clear();

                    // Optionally reset other state variables if needed
                    setState(() {
                      selectedTraitKey = null;
                      selectedDate = null;
                      // Reset other state variables if necessary
                    });

                    // Display a snackbar or message to indicate form submission
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Form submitted and cleared'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: Text('Submit Observation'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
