import 'package:grassroots_field_trials/api_requests.dart';

import 'package:flutter/material.dart';

class StringLabel {
  String name;
  String id;

  StringLabel (this.name, this.id);
}

typedef StringEntry = DropdownMenuEntry <StringLabel>;

