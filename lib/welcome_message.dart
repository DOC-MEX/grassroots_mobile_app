import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';

class WelcomeMessageWidget extends StatelessWidget {
  //final String _websiteUrl = "https://grassroots.tools";
  final Uri _websiteUrl = Uri.parse('https://grassroots.tools/');

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 50.0,
      left: 3,
      right: 3,
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(fontSize: 16, color: Colors.black),
          children: [
            TextSpan(
              text: "Welcome to the QR reader for Grasstools.\n\n",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: "Open the camera to start capturing QR codes.\n\n",
              style: TextStyle(fontSize: 18),
            ),
            TextSpan(
              text: "Visit ",
              style: TextStyle(fontSize: 18),
            ),
            TextSpan(
              text: "grassroots.tools",
              style: TextStyle(
                fontSize: 18,
                decoration: TextDecoration.underline,
                color: Colors.blue,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () async {
                  if (!await launchUrl(_websiteUrl)) {
                    print('Could not launch $_websiteUrl');
                  }
                },
            ),
            TextSpan(
              text: " for more information.",
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
