// qr_code_processor.dart

import 'qr_code_service.dart';
//import 'package:mobile_scanner/mobile_scanner.dart';

class QRCodeProcessor {
  final QRCodeService qrCodeService;

  QRCodeProcessor({required this.qrCodeService});

  Future<Map<String, dynamic>> fetchDataFromQR(String qrCode) async {
    return await qrCodeService.fetchDataFromQR(qrCode);
  }

  Future<ParsedData> parseResponseData(Map<String, dynamic> responseData) async {
    return qrCodeService.parseResponseData(responseData);
  }

//  String? processCapture(BarcodeCapture capture) {
//    return qrCodeService.processDetectedQR(capture);
//  }
}
