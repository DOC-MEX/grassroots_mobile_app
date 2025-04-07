
import 'package:flutter/material.dart';
import 'package:grassroots_field_trials/backend_request.dart';

import 'package:flutter_html/flutter_html.dart';
import 'package:grassroots_field_trials/global_variable.dart';

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

    if (GrassrootsConfig.debug_flag) {
      print (">>> json ${json}");
    }

    String mv_id = json ["id"];

    if (GrassrootsConfig.debug_flag) {
      print ("id ${mv_id}");
    }

    if (mv_id != "") {
      var child = json ["unit"];

      if (GrassrootsConfig.debug_flag) {
        print ("unit ${child}");
      }

      if (child != null) {
        String mv_unit_name = child ["so:name"];
      
        if (GrassrootsConfig.debug_flag) {
          print ("mv_unit_name ${mv_unit_name}");
        }

        if (mv_unit_name != "") {
          child = json ["trait"];

          if (GrassrootsConfig.debug_flag) {
             print ("trait ${child}"); 
          }

          if (child != null) {
            String mv_trait_name = child ["so:name"];

            if (GrassrootsConfig.debug_flag) {
              print ("mv_trait_name ${mv_trait_name}");
            }

            if (mv_trait_name != "") {
              String? mv_trait_descrption = child ["so:description"];

              if (mv_trait_descrption == "") {
                mv_trait_descrption = null;
              }

              if (GrassrootsConfig.debug_flag) {
                print ("mv_trait_descrption ${mv_trait_descrption}");
              }

              child = json ["measurement"];

              if (GrassrootsConfig.debug_flag) {
                print ("measurement ${child}"); 
              }

              if (child != null) {
                String mv_measurement_name = child ["so:name"];
                
                if (GrassrootsConfig.debug_flag) {
                  print ("mv_measurement_name ${mv_measurement_name}");
                }

                if (mv_measurement_name != "") {
                  String? mv_measurement_description = child ["so:description"];

                  if (mv_measurement_description == "") {
                    mv_measurement_description = null;
                  }

                  if (GrassrootsConfig.debug_flag) {
                    print ("mv_measurement_description ${mv_measurement_description}");
                  }

                  child = json ["variable"];

                  if (GrassrootsConfig.debug_flag) {
                    print ("variable ${child}"); 
                  }

                  if (child != null) {
                    String mv_variable_name = child ["so:name"];

                    if (GrassrootsConfig.debug_flag) {
                      print ("mv_variable_name ${mv_variable_name}");
                    }

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


class MeasuredVariablesModel with ChangeNotifier {
  final List <MeasuredVariable> _values = <MeasuredVariable> [];
  late String _name;

  MeasuredVariablesModel (String name) {
    _name = name;    
  }



  /* Make a copy each time */
  List <MeasuredVariable> get values => _values.toList ();

  int get length => _values.length;

  void add (MeasuredVariable mv) {
    _values.add (mv);
    notifyListeners ();
  }

  List <MeasuredVariable> getSelectedVariables () {
    List <MeasuredVariable> selected_vars = <MeasuredVariable> [];

    for (int i = 0; i < _values.length; ++ i) {
      if (_values [i].selected) {
        selected_vars.add (_values [i]);
      }    
    }

    return selected_vars;
  }

  MeasuredVariable at (int index) {
    return _values [index];
  }


  void setValues (List <MeasuredVariable> new_values) {
    bool force_notify_flag = false;

    if (_values.length > 0) {
      force_notify_flag = true;
      _values.clear ();
    }

    _addValues (new_values, force_notify_flag);
  }

  void addValues (List <MeasuredVariable> new_values) {
    _addValues (new_values, false);
  }


  void _addValues (List <MeasuredVariable> new_values, bool force_notify_flag) {
    bool added_flag = false;

    for (MeasuredVariable mv in new_values) {

      if (GrassrootsConfig.debug_flag) {
        print ("${_name} :: _addValues (): checking ${mv.variable_name}");
      }

      if (! (_values.contains (mv))) {
        _values.add (mv);
 
        if (GrassrootsConfig.debug_flag) {
          print ("${_name} :: _addValues (): adding ${mv.variable_name}");
        }

        if (!added_flag) {
          added_flag = true;
        }
      }
    } 

    if (added_flag) {
      if (GrassrootsConfig.debug_flag) {
        print ("${_name} :: _addValues (): about to call notifyListeners ()");
      }

      notifyListeners ();
    }
    
  }


}


class MeasuredVariableSearchDelegate extends SearchDelegate <List <MeasuredVariable>> {


  MeasuredVariableSearchDelegate (String name) {
    _list_widget = MeasuredVariablesListWidget (name, null);
  }

  late MeasuredVariablesListWidget _list_widget;

  void OnTap () {

  }


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
        
        MeasuredVariablesListWidget w = _list_widget;

        mvs = w.getSelectedVariables ();
          
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
            _list_widget.setValues (results);
          }

          return _list_widget;

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

    if (GrassrootsConfig.debug_flag) {
      if (results != null) {
        print ("getSelectedVariables () has ${results.length} entries");
      } else {
        print ("getSelectedVariables () has no entries");
      }
   
    }

    return results;
  }




}





class MeasuredVariablesListWidget extends StatefulWidget {

  MeasuredVariablesListWidget (String name, MeasuredVariablesModel? model) {
    _name = name;

    if (model != null) {
      
      if (GrassrootsConfig.debug_flag) {
        print ("USING EXISTING MODEL OF ${model.length} VALUES");
      }

      _model = model;
    } else {
      _model = MeasuredVariablesModel (_name);
    }

  }
  
  late MeasuredVariablesModel _model;

  late _MeasuredVariablesListWidgetState _state;

  late String _name;

  @override
  _MeasuredVariablesListWidgetState createState () {
    _state = _MeasuredVariablesListWidgetState ();
    return _state;
  } 

  void setValues (List <MeasuredVariable> new_values) {
    _model.setValues (new_values);
  }

  void addValues (List <MeasuredVariable> new_values) {
    _model.addValues (new_values);
  }


  List <MeasuredVariable> getSelectedVariables () {
    return _model.getSelectedVariables ();
  }

  MeasuredVariablesModel getModel () {
    return _model;
  }

}


class _MeasuredVariablesListWidgetState extends State <MeasuredVariablesListWidget>  {


  @override
  void initState () {
    super.initState ();
  }

  void _toggle (int index) {
    setState(() {
      final MeasuredVariable? mv = widget._model.at (index);

      if (mv != null) {
        mv.selected  = !mv.selected;
      }
    });
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
    final List  <MeasuredVariable> values = widget._model._values;

    if (GrassrootsConfig.debug_flag) {
      print ("building list of ${values.length} items for ${widget._name}");
    }

    if (values.length > 0) {
      final int count = values.length;

      if (GrassrootsConfig.debug_flag) {
        print ("LIST MODE ${count}");

        for (int i = 0; i < count; ++ i) {
          print ("About to add ${i} = ${values [i].variable_name}");
        }
      
      }

      return ListView.builder(
        shrinkWrap: true,
        itemCount: count,
        itemBuilder: (BuildContext context, int index) {
          MeasuredVariable mv = values [index];
          String item_subtitle = mv.trait_name + " - " + mv.measurement_name + " - " + mv.unit_name;

          if (GrassrootsConfig.debug_flag) {
            print ("ADDING ${index}: ${mv.variable_name}");
          }
         
          Widget trailing_widget = Checkbox(
              value: mv.selected,
              onChanged: (bool? x) => _toggle(index),
            );
        

          return ListTile (
            onTap: () => _toggle(index),
            trailing: trailing_widget,
            title: Text (mv.variable_name),
            subtitle: Html (data: item_subtitle),
          );
        },
      );
    } else {
      return Text ("");
    }
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