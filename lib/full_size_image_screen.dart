import 'dart:io';
import 'package:flutter/material.dart';
//import 'dart:typed_data'; // Import this for Uint8List

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

class FullSizeImageScreen extends StatelessWidget {
  //final Uint8List? imageBytes;
  final String? imageUrl;
  final int? plotNumber;

  FullSizeImageScreen({this.imageUrl, this.plotNumber});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Photo of Plot ${plotNumber ?? 'Loading...'}'),
      ),
      body: Center(
        child: Hero(
          tag: 'imageHero',
          //child: imageBytes != null ? Image.memory(imageBytes!, fit: BoxFit.cover) : Container(),
          // Use Image.network to display the image from a URL
          child: imageUrl != null ? Image.network(imageUrl!, fit: BoxFit.cover) : Container(),
        ),
      ),
    );
  }
}
