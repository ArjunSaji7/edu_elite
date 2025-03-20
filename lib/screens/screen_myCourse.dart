import 'package:flutter/material.dart';

class ScreenMycourse extends StatefulWidget {
  const ScreenMycourse({super.key});

  @override
  State<ScreenMycourse> createState() => _ScreenMycourseState();
}

class _ScreenMycourseState extends State<ScreenMycourse> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: Text('My Courses')),

    );
  }
}
