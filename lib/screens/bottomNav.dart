import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:edu_elite/screens/screen_home.dart';
import 'package:edu_elite/screens/screen_my_course.dart';
import 'package:edu_elite/screens/screen_profile.dart';
import 'package:edu_elite/screens/screen_search.dart';
import 'package:flutter/material.dart';

class Bottomnav extends StatefulWidget {
  const Bottomnav({super.key});

  @override
  State<Bottomnav> createState() => _BottomnavState();
}

class _BottomnavState extends State<Bottomnav> {
  int _pageIndex = 0;

  final List<Widget> _pages = [
    ScreenHome(),
    ScreenSearch(),
    ScreenMyCourse(),
    ScreenProfile(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_pageIndex],
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.white,
        color: Colors.blueAccent.shade400,
        buttonBackgroundColor: Colors.blueAccent.shade400,
        height: 60,
        animationCurve: Curves.easeIn,
        animationDuration: Duration(milliseconds: 400),
        items: [
          Icon(Icons.home, size: 40, color: Colors.white),
          Icon(Icons.search, size: 40, color: Colors.white),
          Icon(Icons.book, size: 40, color: Colors.white),
          Icon(Icons.person, size: 40, color: Colors.white),
        ],
        onTap: (index) {
          setState(() {
            _pageIndex = index;
          });
        },
      ),
    );
  }
}
