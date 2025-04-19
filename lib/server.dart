
import 'package:flutter/material.dart';

class StringLabel {
  String name;
  String id;

  StringLabel (this.name, this.id);
}

typedef StringEntry = DropdownMenuEntry <StringLabel>;

