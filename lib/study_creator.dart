

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:grassroots_field_trials/caching.dart';
import 'package:grassroots_field_trials/grassroots_request.dart';
import 'package:grassroots_field_trials/measured_variables.dart';
import 'package:grassroots_field_trials/search_phenotypes.dart';
import 'package:hive/hive.dart';

import 'package:grassroots_field_trials/api_requests.dart';
import 'package:grassroots_field_trials/backend_request.dart';

import 'global_variable.dart';

import 'server.dart';



class NewStudyPage extends StatefulWidget {
  String? study_name;

  NewStudyPage ({
    this.study_name,
  });



  @override
  _NewStudyPageState createState () => _NewStudyPageState ();
}


class _NewStudyPageState extends State <NewStudyPage> {
  final TextEditingController _trials_controller = TextEditingController();
  final TextEditingController _locations_controller = TextEditingController();
  bool _is_loading = true;
  List <Map <String, String>> _trials = []; // Store both name and ID

  List <Map <String, String>> _locations = []; // Store both name and ID

  MeasuredVariableSearchDelegate _measured_variables_search = MeasuredVariableSearchDelegate ("search new phenotypes");
  
  MeasuredVariablesModel _model = MeasuredVariablesModel("Selected Phenotypes List");

  
  String? _name;
  int _num_rows = 1;
  int _num_columns = 1;

  @override
  void initState () {
    super.initState ();

    fetchTrials ();
    fetchLocations ();
  }

  @override
  void dispose () {
    // Dispose of your controllers here

    // Call the dispose method of the superclass at the end
    super.dispose();
  }

  void updateMeasuredVariablesList (MeasuredVariablesModel model) {
    setState(() {
      _model = model;
    });
  }


  Future <MeasuredVariablesModel ?> _navigateAndDisplaySelection (BuildContext context) async {
    // Navigator.push returns a Future that completes after calling
    // Navigator.pop on the Selection Screen.
    final MeasuredVariablesModel? result = await Navigator.push(
      context,
      // Create the SelectionScreen in the next step.
      MaterialPageRoute(builder: (context) => SearchPhenotypesPage ()),
    );

    // When a BuildContext is used from a StatefulWidget, the mounted property
    // must be checked after an asynchronous gap.
    if (!context.mounted) {
      return null;
    }

    if (result != null) {
      List <MeasuredVariable> mvs = result.values;

      for (int i = 0; i < mvs.length; ++ i) {
        print (">>> _navigateAndDisplaySelection () returned ${i}: ${mvs [i].variable_name}");
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {

    MeasuredVariablesListWidget phenotypes_widget = MeasuredVariablesListWidget ("Selected Phenotypes List", _model);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            // Reset the image state
            setState(() {

            });

            // Pop the current route
            Navigator.of(context).pop();
          },
        ),
        title: Text('Create a Study'),
      ),
      body: 

      ListenableBuilder (
        listenable: _model, 
        builder: (BuildContext context, Widget? child) { 
          // We rebuild the ListView each time the list changes,
          // so that the framework knows to update the rendering. 
          final List <MeasuredVariable> values = _model.values; // copy the list



          return Padding (
              padding: EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Form(
                  child: Column(
                    children: <Widget>[

                      TextFormField (
                        style: TextStyle (color: Theme.of(context).primaryColor),
                        decoration: InputDecoration (
                          border: OutlineInputBorder (), 
                          labelText: 'Study name'
                        ),
                      
                        onChanged: (String? new_value) {
                          setState (() {
                            _name = new_value;
                            print ("set _name to ${_name}");
                          });
                        }
                      ),

                      SizedBox (height: 10),

                      // Trials menu
                      DropdownMenu (
                        expandedInsets: EdgeInsets.zero,  // full width
                        requestFocusOnTap: true,
                        dropdownMenuEntries: GetTrialsAsList (),
                        controller: _trials_controller,
                        enableFilter: true,
                        label: const Text ("Choose the Field Trial that this study is a part of..."),
                        helperText: "Select a Trial",
                        trailingIcon: Icon (
                          Icons.arrow_drop_down,
                          color: Theme.of(context).primaryColor,
                        ),
                        textStyle: TextStyle (color: Theme.of(context).primaryColor),
                        inputDecorationTheme: InputDecorationTheme (
                          labelStyle: TextStyle (color: Theme.of(context).primaryColor),
                          helperStyle: TextStyle (color: Theme.of(context).primaryColor),
                        ),

                        /*
                        inputDecorationTheme: InputDecorationTheme(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          constraints: BoxConstraints.tight(const 
                          Size.fromHeight(40)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        */

                        menuHeight: 500,
                        menuStyle: MenuStyle (
                          backgroundColor: WidgetStateProperty.all(Theme.of(context).canvasColor),
                        ),
                        
                      ),

                      SizedBox (height: 10),


                      // Locations menu
                      DropdownMenu (
                        expandedInsets: EdgeInsets.zero,  // full width
                        requestFocusOnTap: true,
                        dropdownMenuEntries: GetLocationsAsList (),
                        controller: _locations_controller,
                        enableFilter: true,
                        label: const Text ("Choose the Location for this study..."),
                        helperText: "Select a Location",
                        trailingIcon: Icon (
                          Icons.arrow_drop_down,
                          color: Theme.of(context).primaryColor,
                        ),
                        textStyle: TextStyle (color: Theme.of(context).primaryColor),
                        inputDecorationTheme: InputDecorationTheme (
                          labelStyle: TextStyle (color: Theme.of(context).primaryColor),
                          helperStyle: TextStyle (color: Theme.of(context).primaryColor),
                        ),

                        /*
                        inputDecorationTheme: InputDecorationTheme(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          constraints: BoxConstraints.tight(const 
                          Size.fromHeight(40)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        */

                        menuHeight: 500,
                        menuStyle: MenuStyle (
                          backgroundColor: WidgetStateProperty.all(Theme.of(context).canvasColor),
                        ),
                        
                      ),

                      SizedBox (height: 10),


                        // Number of plot rows
                        TextFormField (
                          style: TextStyle (color: Theme.of(context).primaryColor),
                          decoration: new InputDecoration (
                            labelText: "Number of rows of plots"
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly
                          ], // Only numbers can be entered

                          onSaved: (String? new_value) {
                            if (new_value != null) {
                              int? c = int.tryParse (new_value);

                              if (c != null) {
                                setState (() {
                                  _num_rows = c;
                                  print ("set rows to ${_num_rows}");
                                });
                              }
                            }
                          },
                          validator: _ValidateNumberField,

                        ),

                      SizedBox (height: 10),

                        // Number of plot columns
                        TextFormField (
                          style: TextStyle (color: Theme.of(context).primaryColor),
                          decoration: new InputDecoration (
                            labelText: "Number of columns of plots"
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly
                          ], // Only numbers can be entered

                        onChanged: (String? new_value) {
                          if (new_value != null) {
                            int? c = int.tryParse (new_value);
          
                            if (c != null) {
                              setState (() {
                                _num_columns = c;
                                print ("set columns to ${_num_columns}");
                              });
                            }
                          }
                        },

                      ),

                      SizedBox (height: 10),


                      IconButton (
                        icon: Icon (Icons.search),
                        onPressed: () async {
/*
                          MeasuredVariablesModel? m = await _navigateAndDisplaySelection (context);

                          if (m != null) {
                            print ("ABOUT TO SET STATE WITH ${m.length} values");
                            setState(() {
                              phenotypes_widget.addValues (m.values);
                            });
                          }
*/
                          
                          final List <MeasuredVariable>? selected_mvs = await showSearch <List <MeasuredVariable>> (
                            context: context,
                            delegate: _measured_variables_search,
                          );

                          if (selected_mvs != null) {
                            for (int i = 0; i < selected_mvs.length; ++ i) {
                              print ("${i}: ${selected_mvs [i].variable_name}");
                            }


                            setState (() {
                              // Call setState to refresh the page.
                              phenotypes_widget.addValues (selected_mvs); 
                            });
                          }
                          
                        },
                      ),

                      SizedBox (height: 10),

                      phenotypes_widget,

                    ]
                  )
                )
              )
            );
          }
        )
      );
  }


  String? _ValidateStringField (String? value) {
    String? res = null;

    print ("Value \"${value}\"");

    if ((value == null) || (value.trim ().length == 0)) {
      res = "This is required";
    }

    return res;
  }

  String? _ValidateNumberField (String? value) {
    if (value != null) {
      int? c = int.tryParse (value);

      if (c != null) {
        if (c > 0) {
          return null;
        } else {
          return "Value must be a number greater than 0";
        }
      } else {
        return "Value must be a number";
      }
    } else {
      return "This is required";
    }
  }

  void fetchTrials () async {
    setState(() {
      _is_loading  = true;
    });

    try {
      List <Map <String, String>> trials = await _FetchData (backendRequests.fetchAllTrials, CACHE_TRIALS, "Trial");

      if (mounted) {
        setState(() {
          _is_loading = true;
          _trials = trials;
          _is_loading = false;
        });
      }
    } catch (e) {
        print('Error fetching s: $e');
        if (mounted) {
          setState(() {
            _is_loading = false;
          });
        }
    }
  }


  void fetchLocations () async {
    setState(() {
      _is_loading  = true;
    });

    try {
      List <Map <String, String>> locations = await _FetchData (backendRequests.fetchAllLocations, CACHE_LOCATIONS, "Location");

      if (mounted) {
        setState(() {
          _is_loading = true;
          _locations = locations;
          _is_loading = false;
        });
      }
    } catch (e) {
        print('Error fetching s: $e');
        if (mounted) {
          setState(() {
            _is_loading = false;
          });
        }
    }
  }


  Future <List <Map <String, String>>> _FetchData (Future <List <Map <String, String>>> Function() rest_api_call,  final String cache_name, final String datatype) async {
    List <Map <String, String>> data = [];
    bool healthy_flag = await ApiRequests.isServerHealthy ();  

    /*
     * If the server are online then get the live data
     */
    if (healthy_flag) {
      data = await rest_api_call ();

    } else {
      /* Use any cached data */
      var box = await Hive.openBox <IdName> (cache_name);

      final int num_entries = box.length;

      for (int i = 0; i < num_entries; i ++) {
        Map <String, String> entry = Map <String, String> ();
        IdName? cached_item = box.getAt (i);

        if (cached_item != null) {
          entry ["name"] = cached_item.name;
          entry ["id"] = cached_item.id;

          String date_str = "";
          if (cached_item.date != null) {
            date_str = cached_item.date.toString ();
          }
          data.add (entry);        
  
        }
      }
    }

    return data;
  }



  List <StringEntry> GetTrialsAsList () {
    return _GetEntries (_trials, "Trial");
  }



  List <StringEntry> GetLocationsAsList () {
    return _GetEntries (_locations, "Location");
  }


  List <StringEntry> _GetEntries (List <Map <String, String>> mongo_obects, final String datatype) {
    List <StringEntry> l = [];

    print ("Num ${datatype}s: ${mongo_obects}"); 
  
    for (final e in mongo_obects) {
      var id = e ['id'];

      if (id != null) {
        StringLabel sl = StringLabel (e['name'] ?? 'Unknown ${datatype}', id);

        StringEntry se = StringEntry(
          label: e ['name'] ?? 'Unknown ${datatype}', 
          value: sl,
          style: ButtonStyle (
            foregroundColor: WidgetStateProperty.all(Theme.of(context).primaryColor),
          ),
        );
        
        l.add (se);            
      } else {
        print ("no id in ${e}");
      }

    }

    print ("num StringEntries for ${datatype}s ${l.length}");
    return l;
  }




  bool submitStudy (final String study_name, final String trial_id, final String location_id, final String user_email, final String user_name,
                    final int num_rows, final int num_cols, final List <MeasuredVariable> phenotypes) {
 
    StringBuffer mvs = StringBuffer ();

    for (int i = 0; i < phenotypes.length; ++ i) {
      MeasuredVariable phenotype = phenotypes [i];
      mvs.write ("\"");
      mvs.write (phenotype.variable_name);
      mvs.write ("\"");

      if (i < phenotypes.length - 1) {
        mvs.writeln (",");
      }
    }

    String requestString = jsonEncode ({
      "services": [{ 
        "so:name": "Submit Field Trial Study",
          "start_service": true,
          "parameter_set": {
            "level": "simple",
            "parameters": [{
                "param": "ST Name",
                "current_value": "${study_name}",
                "group": "Study"
              }, {
                "param": "Field Trials",
                "current_value": "${trial_id}",
                "group": "Study"
              }, {
                "param": "Locations",
                "current_value": "${location_id}",
                "group": "Study"
              }, {
                "param": "ST Curator name",
                "current_value": "{username}",
                "group": "Curator"
              }, {
                "param": "ST Curator email",
                "current_value": "${user_email}",
                "group": "Curator"
              }, {
                "param": "ST Curator role",
                "current_value": null,
                "group": "Curator"
              }, {
                "param": "ST Curator affiliation",
                "current_value": null,
                "group": "Curator"
              }, {
                "param": "ST Curator orcid",
                "current_value": null,
                "group": "Curator"
              }, {
                "param": "ST Description",
                "current_value": "",
                "group": "Study"
              }, {
                "param": "ST Design",
                "current_value": "",
                "group": "Study"
              }, {
                "param": "Photo",
                "current_value": null,
                "group": "Study"
              }, {
                "param": "ST Image Notes",
                "current_value": "",
                "group": "Study"
              }, {
                "param": "ST Num Rows",
                "current_value": "${num_rows}",
                "group": "Default Plots data"
              }, {
                "param": "ST Num Columns",
                "current_value": "${num_cols}",
                "group": "Default Plots data"
              }, {
                "param": "ST Measured Variables",
                "current_value": [
                  mvs
                ],
                "group": "Measured Variables"
              }
            ]
          }
        }]
      });

      return false;
    }
  }

