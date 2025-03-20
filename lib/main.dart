import 'package:edu_elite/screens/bottomNav.dart';
import 'package:edu_elite/screens/screen_home.dart';
import 'package:edu_elite/screens/screen_splash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Future<void> main () async {
  WidgetsFlutterBinding.ensureInitialized();
  var firebaseOptions = FirebaseOptions(
    apiKey: 'AIzaSyAoRRf1JDHzIUWH84TZ0igj6UXigGwQ4rw',
    authDomain: 'travelbasecom.firebaseapp.com',
    projectId: 'travelbasecom',
    storageBucket: 'travelbasecom.appspot.com',
    messagingSenderId: '937267774107',
    appId: '1:937267774107:android:86ab096ad53e0858227c3e',
  );

  await Firebase.initializeApp(options: firebaseOptions);
  runApp(
      MyApp()
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ScreenSplash(),
      debugShowCheckedModeBanner: false,
    );
  }
}
