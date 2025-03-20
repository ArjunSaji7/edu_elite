import 'package:flutter/material.dart';

class ScreenProfile extends StatefulWidget {
  const ScreenProfile({super.key});

  @override
  State<ScreenProfile> createState() => _ScreenProfileState();
}

class _ScreenProfileState extends State<ScreenProfile> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: Text('Profile')),
    );
  }
}
