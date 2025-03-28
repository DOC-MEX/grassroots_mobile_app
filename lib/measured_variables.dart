
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
  bool selected; 

  MeasuredVariable (this.id, this.unit_name, this.trait_name, this.trait_descrption, this.measurement_name, this.measurement_description, this.variable_name, this.selected);

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
                      return MeasuredVariable (mv_id, mv_unit_name, mv_trait_name, mv_trait_descrption, mv_measurement_name, mv_measurement_description, mv_variable_name, false);

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


class MeasuredVariableSearchDelegate extends SearchDelegate <List <MeasuredVariable>> {

  MeasuredVariablesListWidget? _list_widget;
  
  void OnTap () {

  }
  
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
      onPressed: () {
        List <MeasuredVariable> mvs = [];
        
        MeasuredVariablesListWidget? w = _list_widget;

        if (w != null) {
         mvs = w.getSelectedVariables ();
        }
          
      //MeasuredVariable mv = _selected_entries.entries.first.value;
        close (context, mvs);
      },
    );
  }

  /* The results shown after the user submits a search from the search page. */
  @override
  Widget buildResults (BuildContext context) {
  
    return FutureBuilder <List <MeasuredVariable>> (
      future: _search (),
      builder: (BuildContext context, AsyncSnapshot <List <MeasuredVariable>> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {

          List <MeasuredVariable>? results = snapshot.data;

          if ((results != null) && (results.length > 0)) {
            _list_widget =  MeasuredVariablesListWidget (
              measured_variables: results, 
              isSelectionMode: true, 
            );

            final Widget? w = _list_widget;

            if (w != null) {
              return w;
            } else {
              return Text ("Error searching, please try again");
            }
          } else {
            return Text ("No hits found");
          }
        } else if ((snapshot.connectionState == ConnectionState.active) || (snapshot.connectionState == ConnectionState.waiting)) {
          return Center(
            child: CircularProgressIndicator (),
          );
        } else {
          return Text ("Idle");
        }
      }
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

  List <MeasuredVariable>? getSelectedVariables () {
/*
    List <MeasuredVariable> results =
    _selected_entries.entries.map ((entry) => entry.value).toList();
*/
    final MeasuredVariablesListWidget? m = _list_widget;

    List <MeasuredVariable>? results;

    if (m != null) {
      results = m.getSelectedVariables ();
    }

    if (results != null) {
      print ("getSelectedVariables () has ${results.length} entries");
    } else {
      print ("getSelectedVariables () has no entries");
    }

    return results;
  }




}





class MeasuredVariablesListWidget extends StatefulWidget {

  MeasuredVariablesListWidget({
      super.key,
      required this.measured_variables,
      required this.isSelectionMode,
  });
  
  final bool isSelectionMode;
  List <MeasuredVariable> measured_variables;

  late _MeasuredVariablesListWidgetState _state;

  @override
  _MeasuredVariablesListWidgetState createState() {
    _state = _MeasuredVariablesListWidgetState ();
    return _state;
  } 

  void updateValues (List <MeasuredVariable> vars) {
     measured_variables = vars;
  }

  List <MeasuredVariable> getSelectedVariables () {
    List <MeasuredVariable> selected_vars = [];

    for (int i = 0; i < measured_variables.length; ++ i) {
      if (measured_variables [i].selected) {
        selected_vars.add (measured_variables [i]);
      }    
    }

    return selected_vars;
  }

}


class _MeasuredVariablesListWidgetState extends State <MeasuredVariablesListWidget> {
  @override
  void initState () {
    super.initState ();
  }

  void _toggle (int index) {
    if (widget.isSelectionMode) {
      setState(() {
        final MeasuredVariable? mv = widget.measured_variables [index];

        if (mv != null) {
          mv.selected  = !mv.selected;
        }
      });
    }
  }

/*
  void setValues (List <MeasuredVariable> mvs) {
    setState(() {
      _selected_vars.clear ();

      for (int i = 0; i < mvs.length; ++ i) {
        MeasuredVariable mv = mvs [i];

        _selected_vars [i] = mv;
      }
    });
  }
 */

  @override
  Widget build(BuildContext context) {

    return ListView.builder(
      itemCount: widget.measured_variables.length,
      itemBuilder: (BuildContext context, int index) {
        MeasuredVariable mv = widget.measured_variables [index];
        String item_subtitle = mv.trait_name + " - " + mv.measurement_name + " - " + mv.unit_name;

        Widget trailing_widget;

        if (widget.isSelectionMode) {
          trailing_widget = Checkbox(
            value: mv.selected,
            onChanged: (bool? x) => _toggle(index),
          );
        } else {
          trailing_widget = const SizedBox.shrink ();
        }

        return ListTile (
          onTap: () => _toggle(index),
          trailing: trailing_widget,
          title: Text (mv.variable_name),
          subtitle: Html (data: item_subtitle),
        );
      },
    );

/*
    return ListView.builder (
      itemCount: widget.measured_variables.length,
      itemBuilder: (BuildContext context, int index) {
        final MeasuredVariable mv = widget.measured_variables [index];
        String item_subtitle = mv.trait_name + " - " + mv.measurement_name + " - " + mv.unit_name;

        return ListTile (
          onTap: () => _toggle(index),
          onLongPress: () {
            if (!widget.isSelectionMode) {
              setState(() {
                widget.selectedList[index] = true;
              });
              widget.onSelectionChange!(true);
            }
          },
          trailing:
              widget.isSelectionMode
                  ? Checkbox(
                    value: widget.selectedList[index],
                    onChanged: (bool? x) => _toggle(index),
                  )
                  : const SizedBox.shrink(),
          title: Text('item $index'),
        );

          title: Text (mv.variable_name),
          subtitle: Html (data: item_subtitle),
          secondary: Icon (Icons.list),
          value:  _selected_vars.containsKey (index),
          controlAffinity: ListTileControlAffinity.platform,
          onChanged: (bool? value) {
            setState () {
              if (value != null) {
                mv.selected = value;
              }
            }
          },                
        );
  
      },

    );
    */
  }

}


/*
class ListBuilder extends StatefulWidget {
  const ListBuilder({
    super.key,
    required this.selectedList,
    required this.isSelectionMode,
    required this.onSelectionChange,
  });

  final bool isSelectionMode;
  final List <MeasuredVariable> selectedList;
  final ValueChanged <MeasuredVariable>? onSelectionChange;

  @override
  State <ListBuilder> createState() => _ListBuilderState();
}

class _ListBuilderState extends State <ListBuilder> {
  void _toggle(int index) {
    if (widget.isSelectionMode) {
      setState(() {
        widget.selectedList [index] = !widget.selectedList[index];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
 
    return ListView.builder (
      itemCount: widget.measured_variables.length,
      itemBuilder: (BuildContext context, int index) {
        final MeasuredVariable mv = widget.measured_variables [index];
        String item_subtitle = mv.trait_name + " - " + mv.measurement_name + " - " + mv.unit_name;

        return CheckboxListTile (                 
          title: Text (mv.variable_name),
          subtitle: Html (data: item_subtitle),
          secondary: Icon (Icons.list),
          value:  _selected_vars.containsKey (mv.variable_name),
          controlAffinity: ListTileControlAffinity.platform,
          onChanged: (bool? value) {
            setState () {
              if (value != null) {
                mv.selected = value;
              }
            }
          },                
        );
  
      },

    );


 /*
    return ListView.builder(
      itemCount: widget.selectedList.length,
      itemBuilder: (_, int index) {
        return ListTile(
          onTap: () => _toggle(index),
          onLongPress: () {
            if (!widget.isSelectionMode) {
              setState(() {
                widget.selectedList[index] = true;
              });
              widget.onSelectionChange!(true);
            }
          },
          trailing:
              widget.isSelectionMode
                  ? Checkbox(
                    value: widget.selectedList[index],
                    onChanged: (bool? x) => _toggle(index),
                  )
                  : const SizedBox.shrink(),
          title: Text('item $index'),
        );
      },
    );
  */
  }
}
*/