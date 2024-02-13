import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:typed_data'; // Import this for Uint8List

class FullSizeImageScreenFile extends StatelessWidget {
  final File? imageFile;
  final int? plotNumber;

  FullSizeImageScreenFile({this.imageFile, this.plotNumber});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Photo of Plot ${plotNumber ?? 'Loading...'}'),
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
  final int? plotNumber;

  FullSizeImageScreenUint8List({this.imageBytes, this.plotNumber});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Photo of Plot ${plotNumber ?? 'Loading...'}'),
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
