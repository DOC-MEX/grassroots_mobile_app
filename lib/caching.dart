import 'package:flutter/material.dart';
import 'package:grassroots_field_trials/global_variable.dart';
import 'package:hive/hive.dart';


class StudyDetails
{
  StudyDetails ({required this.sd_name, required this.sd_id, required this.sd_date});

  factory StudyDetails.fromJson (Map <String, dynamic> json) {
    StudyDetails study;
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

    study = StudyDetails (sd_name: json ["name"], sd_id: json['id'], sd_date: d);

    return study;
  }
    
  String sd_name;
  String sd_id;
  DateTime sd_date;


}

class StudyAdapter extends TypeAdapter <StudyDetails> {
  @override
  int get typeId => 2;

  @override
  StudyDetails read (BinaryReader reader) {
    final name = reader.readString ();
    final id = reader.readString ();
    String date_str = reader.readString ();

    DateTime d = DateTime.parse (date_str);

    return StudyDetails (sd_name: name, sd_id: id, sd_date: d);
  }

  @override
  void write (BinaryWriter writer, StudyDetails obj) {
    writer.writeString (obj.sd_name);
    writer.writeString (obj.sd_id);
    
    String date_str = obj.sd_date.toString ();
    writer.writeString (date_str); 
  }
}


class StudiesCache {

  static final String sc_name = "studies_cache";

  static Future <void> cacheStudies (List<Map<String, String>> studies) async {
    DateTime d = DateTime.now ();
    
    for (final entry in studies) {
      String? name = entry ['name'];

      if (name != null) {
        String? id = entry ['id'];

        if (id != null) {     
          final study = StudyDetails (sd_name: name, sd_id: id, sd_date: d);
          var box = await Hive.openBox <StudyDetails> (sc_name);

          //print ("caching ${study.sd_name} ${study.sd_id}");
          box.put (study.sd_name, study);
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

