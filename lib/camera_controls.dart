import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// New CameraScreen class
class CameraScreen extends StatelessWidget {
  final MobileScannerController cameraController;
  final Function(String) onQRDetected;

  CameraScreen({
    required this.cameraController,
    required this.onQRDetected,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Point to QR Code'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                onQRDetected(barcodes.first.rawValue!);
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
          ),
          Positioned(
            top: 10, // Adjust as needed
            left: 10, // Adjust as needed
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route
                    .isFirst); // Navigates to the first screen in the navigator stack (i.e., home screen).
              },
              child: Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class QRReaderScreen extends StatefulWidget {
  const QRReaderScreen({Key? key}) : super(key: key);

  @override
  QRReaderScreenState createState() => QRReaderScreenState();
}

class QRReaderScreenState extends State<QRReaderScreen> {
  String? qrString; // To store the detected QR string

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('point to QR code---')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (qrString != null) // If QR string detected, display it
              Expanded(
                child: Center(
                  child: Text(
                    'Detected QR String: $qrString',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ElevatedButton(
              onPressed: () {
                final cameraController = MobileScannerController();

                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => CameraScreen(
                    cameraController: cameraController,
                    onQRDetected: (detectedValue) {
                      setState(() {
                        qrString = detectedValue;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("QR code detected!")),
                      );
                    },
                  ),
                ));
              },
              child: const Text("Open Camera"),
            ),
          ],
        ),
      ),
    );
  }
}
