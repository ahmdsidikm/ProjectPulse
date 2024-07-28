import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added this line
import 'package:text_recognition/homepage.dart';
import 'package:camera/camera.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Added this code to lock orientation to portrait
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  runApp(MaterialApp(
    home: HomePage(
      camera: firstCamera,
    ),
  ));
}
