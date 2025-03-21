
import 'package:flutter/material.dart';
import 'package:grassroots_field_trials/backend_request.dart';

import 'package:flutter_html/flutter_html.dart';

/*
  "unit": {
    "so:name": "cm",
    "so:sameAs": "ROTH_UNIT:000456"
  },
  "so:name": "<b>Height</b>",
  "@type": "Grassroots:MeasuredVariable",
  "variable": {
    "so:name": "StbHt_Fh_cm",
    "so:sameAs": "ROTH_VARIABLE:000160"
  },
  "trait": {
    "so:name": "Stubble <b>height</b>",
    "so:sameAs": "ROTH_TRAIT:000160",
    "so:description": "<b>Height</b> of stubble after harvesting",
    "abbreviation": "StbHt"
  },
  "id": "6095037102700f511f5e5111",
  "type_description": "Measured Variable",
  "measurement": {
    "so:name": "<b>Height</b>",
    "so:sameAs": "ROTH_MEAS:000482",
    "so:description": "Stubble <b>height</b>, measured from ground to top of stubble, if stubble lodged, then the true length of the stubble, measured at the angle of the stubble."
  },
*/
class MeasuredVariable {
  String id;
  String unit_name;
  String trait_name;
  String? trait_descrption;
  String measurement_name;
  String? measurement_description;
  String variable_name;
  
  MeasuredVariable (this.id, this.unit_name, this.trait_name, this.trait_descrption, this.measurement_name, this.measurement_description, this.variable_name);

  factory MeasuredVariable.fromJson (Map <String, dynamic> json) {

    print (">>> json ${json}");

    String mv_id = json ["id"];

    print ("id ${mv_id}");

    if (mv_id != "") {
      var child = json ["unit"];

      print ("unit ${child}");

      if (child != null) {
        String mv_unit_name = child ["so:name"];
      
        print ("mv_unit_name ${mv_unit_name}");

        if (mv_unit_name != "") {
          child = json ["trait"];

           print ("trait ${child}"); 

          if (child != null) {
            String mv_trait_name = child ["so:name"];

            print ("mv_trait_name ${mv_trait_name}");

            if (mv_trait_name != "") {
              String? mv_trait_descrption = child ["so:description"];

              if (mv_trait_descrption == "") {
                mv_trait_descrption = null;
              }

              print ("mv_trait_descrption ${mv_trait_descrption}");

              child = json ["measurement"];

              print ("measurement ${child}"); 

              if (child != null) {
                String mv_measurement_name = child ["so:name"];
                
                print ("mv_measurement_name ${mv_measurement_name}");

                if (mv_measurement_name != "") {
                  String? mv_measurement_description = child ["so:description"];

                  if (mv_measurement_description == "") {
                    mv_measurement_description = null;
                  }

                  print ("mv_measurement_description ${mv_measurement_description}");

                  child = json ["variable"];

                  print ("variable ${child}"); 

                  if (child != null) {
                    String mv_variable_name = child ["so:name"];

                    print ("mv_variable_name ${mv_variable_name}");

                    if (mv_variable_name != "") {
                      return MeasuredVariable (mv_id, mv_unit_name, mv_trait_name, mv_trait_descrption, mv_measurement_name, mv_measurement_description, mv_variable_name);

                    }
                  }
                }

              }
            }
          }
        }
      }
    }

    throw Exception ();
  }
}


class MeasuredVariableSearchDelegate extends SearchDelegate <MeasuredVariable> {
  Map <String, String> _selected_entries = {};

  MeasuredVariableSearchDelegate (
  );

  @override
  List <Widget>? buildActions (BuildContext context) {
    return <Widget>[];
  }

  /*A widget to display before the current query in the AppBar. */
  @override
  Widget? buildLeading (BuildContext context) {
    return IconButton(
      icon: const Icon (Icons.arrow_back),
      onPressed: () => Navigator.of(context).pop(),
    );
  }

  /* The results shown after the user submits a search from the search page. */
  @override
  Widget buildResults (BuildContext context) {
    
  
    return FutureBuilder <List <MeasuredVariable>> (
      future: _search (),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {

          List <MeasuredVariable>? results = snapshot.data;

          if (results != null) {
            
            print ("measured variables search found ${results.length} hits");
            print ("results: ${results}");

            return ListView.builder (
              itemCount: results.length,

              itemBuilder: (context, index) {
                final result = results [index];
                Color c;
                String item_subtitle = result.trait_name + " - " + result.measurement_name + " - " +result.unit_name;

                if (_selected_entries.containsKey (result.variable_name)) {
                  c = Colors.red;
                } else {
                  c = Theme.of(context).colorScheme.primary;
                }


                return ListTile (                 
                  title: Text (result.variable_name),
                  subtitle: Html (data: item_subtitle),
                  leading: Icon (Icons.list),
                  tileColor: _selected_entries.containsKey (result.variable_name) ? Colors.red : Theme.of(context).colorScheme.surface,
                  textColor: _selected_entries.containsKey (result.variable_name) ? Colors.green : Theme.of(context).colorScheme.primary,
                  onTap: () {
                   // setState () {
                      print ("clicked on ${result.variable_name} - ${result.id}");
                    
                      if (_selected_entries.containsKey (result.variable_name)) {
                        print ("removing ${result.variable_name}");
                        _selected_entries.remove (result.variable_name);
                      } else {
                        print ("adding ${result.variable_name}");
                        _selected_entries [result.variable_name] = result.id;
                        
                      }
                  //  }                    
                  },
                    
                );
                
              },

            );
          
          } else {
            return Text ("Error searching");
          }
        } else {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
    
    


    }

  /* 
   * Suggestions shown in the body of the search page while 
   * the user types a query into the search field.
   */
  @override
  Widget buildSuggestions (BuildContext context) {
    return Container ();
  }



 Future <List <MeasuredVariable>> _search() async {
    Future <List <MeasuredVariable>> results = backendRequests.searchMeasuredVariables (query);
    
    return results;
  }

}

class _SearchMeasuredVariables {
  
   
}