

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grassroots_field_trials/caching.dart';
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
  bool _is_loading = true;
  List <Map <String, String>> _trials = []; // Store both name and ID

  MeasuredVariableSearchDelegate _measured_variables_search = MeasuredVariableSearchDelegate ("search new phenotypes");
  
  MeasuredVariablesModel _model = MeasuredVariablesModel("Selected Phenotypes List");

  
  String? _name;
  int _num_rows = 1;
  int _num_columns = 1;

  @override
  void initState () {
    super.initState ();

    fetchTrials ();
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

                      TextField (
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

                      // Number of plot rows
                      TextField (
                        decoration: new InputDecoration (
                          labelText: "Number of rows of plots"
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
                                _num_rows = c;
                                print ("set rows to ${_num_rows}");
                              });
                            }
                          }
                        },                
                      ),

                      SizedBox (height: 10),

                      // Number of plot columns
                      TextField (
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


  void fetchTrials() async {
    bool healthy_flag = await ApiRequests.isServerHealthy ();  

    /*
     * If the server are online then get the live data
     */
    if (healthy_flag) {
      setState(() {
        _is_loading  = true;
      });

      try {
        var trials_data = await backendRequests.fetchAllTrials ();
        if (mounted) {
          setState(() {
            _trials = trials_data;

            print ("got ${_trials.length} trials");
            _is_loading = false;
          });
        }
      } catch (e) {
        print('Error fetching trials: $e');
        if (mounted) {
          setState(() {
            _is_loading = false;
          });
        }
      }

    } else {
      /* Use any cached data */
      var box = await Hive.openBox <IdName> (CACHE_STUDIES);

      final int num_entries = box.length;
      List <Map <String, String>> trials_data = [];

      for (int i = 0; i < num_entries; i ++) {
        Map <String, String> entry = Map <String, String> ();
        IdName? study = box.getAt (i);

        if (study != null) {
          entry ["name"] = study.name;
          entry ["id"] = study.id;

          String date_str = "";
          if (study.date != null) {
            date_str = study.date.toString ();
          }
 
          //print ("using cached study ${entry ["name"]}, ${entry ["id"]} from ${date_str}");

          trials_data.add (entry);        
  
        }
      }

      _is_loading = true;
      _trials = trials_data;
      /*
      print ("Got ${_trials.length} cached trials");
      print ("BEGIN _trials");
      print ("${_trials}");
      print ("END _trials");
      */
      _is_loading = false;
    }

  }



  List <StringEntry> GetTrialsAsList () {
    List <StringEntry> l = [];

    print ("in GetTrialsAsList ()"); 
    print ("Num trials ${_trials}"); 
  
    for (final e in _trials) {
      var trial = e;

      //print ("TRIAL: ${trial}");
      var id = trial ['id'];

      if (id != null) {
        StringLabel sl = StringLabel (trial['name'] ?? 'Unknown Trial', id);

        StringEntry se = StringEntry(
          label: trial['name'] ?? 'Unknown Trial', 
          value: sl,
          style: ButtonStyle (
            foregroundColor: WidgetStateProperty.all(Theme.of(context).primaryColor),
          ),
        );
        
        l.add (se);            
      } else {
        print ("no id in ${trial}");
      }

    }

    print ("num StringEntries for Studies ${l.length}");
    return l;
  }

}
