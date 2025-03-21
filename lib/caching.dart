import 'package:flutter/material.dart';
import 'package:grassroots_field_trials/global_variable.dart';
import 'package:hive/hive.dart';


class IdName
{
  IdName ({required this.name, required this.id, required this.date});

  factory IdName.fromJson (Map <String, dynamic> json) {
    IdName entry;
    DateTime? d;

    if (json ["date"] != null) {
      try { 
        d = DateTime.parse (json ["date"]);
      } on FormatException  {

      }
    }

    if (d == null) {
      d = DateTime.now ();
    }

    entry = IdName (name: json ["name"], id: json['id'], date: d);

    return entry;
  }

  // The name of this object e.g. Study, Progamme, Trial, etc.  
  String name;
  
  // The MongoDB Id
  String id;

  // The datestamp for when this IdName was retrieved from the server
  DateTime date;
}

class IdNameAdapter extends TypeAdapter <IdName> {
  @override
  int get typeId => 2;

  @override
  IdName read (BinaryReader reader) {
    final obj_name = reader.readString ();
    final obj_id = reader.readString ();
    String date_str = reader.readString ();

    DateTime d = DateTime.parse (date_str);

    return IdName (name: obj_name, id: obj_id, date: d);
  }

  @override
  void write (BinaryWriter writer, IdName obj) {
    writer.writeString (obj.name);
    writer.writeString (obj.id);
    
    String date_str = obj.date.toString ();
    writer.writeString (date_str); 
  }
}


 class IdNamesCache {

  static Future <void> cache (List<Map<String, String>> studies, String cache_name) async {
    DateTime d = DateTime.now ();
    
    for (final entry in studies) {
      String? entry_name = entry ['name'];

      if (entry_name != null) {
        String? entry_id = entry ['id'];

        if (entry_id != null) {     
          final entry = IdName (name: entry_name, id: entry_id, date: d);
          var box = await Hive.openBox <IdName> (cache_name);

          //print ("caching ${entry.name} ${entry.id}");
          box.put (entry.name, entry);
        }

      }

    }

  }

}



class IdsList {
  IdsList ({required this.ids, required this.date});

  List <String> ids;
  DateTime date;
}


class IdsAdapter extends TypeAdapter <IdsList> {
  @override
  int get typeId => HI_ALLOWED_IDS;

  @override
  IdsList read (BinaryReader reader) {
    List <String> ids = reader.readStringList ();
    String date_str = reader.readString ();

    DateTime d = DateTime.parse (date_str);
    return IdsList (ids: ids, date: d);

  }

  @override
  void write (BinaryWriter writer, IdsList ids) {
    writer.writeStringList (ids.ids);

    String date_str = ids.date.toString ();
    writer.writeString (date_str); 
  }
}




class IdsCache {

  static final String ic_name = "ids_cache";

  static Future <void> cacheIds (List <String> ids) async {
    DateTime d = DateTime.now ();
    
    IdsList ids_list = IdsList (ids: ids, date: d);

    var box = await Hive.openBox <IdsList> (ic_name);


    int num_ids = ids.length; 

    print ("caching ids list of ${num_ids} ids");
    for (int i = 0; i < num_ids; ++ i) {
      print ("id $i = ${ids [i]}");
    }
    print ("caching ids done");

    box.add (ids_list);

  }
}




