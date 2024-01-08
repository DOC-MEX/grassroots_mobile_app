import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:typed_data'; // Import this for Uint8List

class FullSizeImageScreenFile extends StatelessWidget {
  final File? imageFile;

  FullSizeImageScreenFile({this.imageFile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Full-Size Image'),
      ),
      body: Center(
        child: Hero(
          tag: 'imageHero',
          child: imageFile != null ? Image.file(imageFile!, fit: BoxFit.cover) : Container(),
        ),
      ),
    );
  }
}

class FullSizeImageScreenUint8List extends StatelessWidget {
  final Uint8List? imageBytes;

  FullSizeImageScreenUint8List({this.imageBytes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Full-Size Image'),
      ),
      body: Center(
        child: Hero(
          tag: 'imageHero',
          child: imageBytes != null ? Image.memory(imageBytes!, fit: BoxFit.cover) : Container(),
        ),
      ),
    );
  }
}
