//name: NewObservationPage  (new_observation.dart)
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

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
  File? _image;
  String? studyID;
  int? plotNumber;

  @override
  void initState() {
    super.initState();
    _extractPhenotypeDetails();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  // Function to pick an image from the gallery
  Future<void> _pickImageFromGallery() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadImage() async {
    try {
      var uri = Uri.parse('https://grassroots.tools/photo_receiver/upload/');
      var request = http.MultipartRequest('POST', uri);

      // Attach the image file
      //request.files.add(await http.MultipartFile.fromPath('image', _image!.path));

      // Generate the new filename using plotNumber
      String newFileName = 'photo_plot_${plotNumber.toString()}.jpg'; // Assuming the image is a JPEG file

      // Attach the image file with the new filename
      request.files.add(await http.MultipartFile.fromPath(
        'image',
        _image!.path,
        filename: newFileName,
      ));

      // Add the subfolder field
      request.fields['subfolder'] = studyID ?? 'defaultFolder';

      // Send the request
      var response = await request.send();
      // Read response
      //final responseBody = await response.stream.bytesToString();
      ///print('Response: $responseBody');

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload successful')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      //print error
      print('Error: $e');
    }
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
    print('Traits: $traits');
    print('Units: $units');
    print('Scales: $scales');
    // Extract the studyID
    try {
      studyID = widget.studyDetails['results'][0]['results'][0]['data']['_id']['\$oid'];
      //  print('Extracted Study ID: $studyID');
    } catch (e) {
      print('Error extracting Study ID: $e');
    }
    //Extract the plotNumber (['study_index'])
    try {
      plotNumber = widget.plotDetails['rows'][0]['study_index'];
      print('Extracted Plot Number: $plotNumber');
    } catch (e) {
      print('Error extracting Plot Number: $e');
    }
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
        child: SingleChildScrollView(
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
                ////////////////////////////////////////////////////////
                SizedBox(height: 20),
                // put take picture button and select from gallery button in the same row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _pickImage();
                        },
                        child: Text('Take a picture'),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _pickImageFromGallery,
                        child: Text('Select from gallery'),
                      ),
                    ),
                  ],
                ),
                ////////////////////////////////////////////////////////
                // Conditional rendering of the image and the upload button
                if (_image != null)
                  Container(
                    height: 200,
                    width: double.infinity, // Adjust width as needed
                    child: Image.file(_image!, fit: BoxFit.cover),
                  ),
                if (_image != null)
                  ElevatedButton(
                    onPressed: _uploadImage,
                    child: Text('Upload Image'),
                  ),
              ],
            ),
          ), //Form
        ),
      ),
    );
  }
}
