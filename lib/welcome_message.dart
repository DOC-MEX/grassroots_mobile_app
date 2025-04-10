import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';

class WelcomeMessageWidget extends StatelessWidget {
  //final String _websiteUrl = "https://grassroots.tools";
  final Uri _websiteUrl = Uri.parse('https://grassroots.tools/documentation/mobile_app/');

  @override
  Widget build(BuildContext context) {
    return RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(fontSize: 16, color: Theme.of(context).primaryColor),
          children: [
            TextSpan(
              text: "Welcome to the Grassroots Field Trials App\n\n",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            //TextSpan(
            //   text: "Open the camera to start capturing QR codes.\n\n",
            //   style: TextStyle(fontSize: 18),
            // ),
            TextSpan(
              text: "Visit ",
              style: TextStyle(fontSize: 18),
            ),
            TextSpan(
              text: "https://grassroots.tools/documentation/mobile_app",
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
      );
  }
}
