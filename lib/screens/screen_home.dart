import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edu_elite/screens/screen_course_details.dart';
import 'package:flutter/material.dart';

class ScreenHome extends StatefulWidget {
  const ScreenHome({super.key});

  @override
  State<ScreenHome> createState() => _ScreenHomeState();
}

class _ScreenHomeState extends State<ScreenHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Image.asset(
                              'assets/icons/wave (1).png',
                              height: 30,
                              width: 30,
                              fit: BoxFit.fill,
                            ),
                            SizedBox(
                              width: 5,
                            ),
                            Text(
                              'Hello, Leo',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'What do you want to learn today?',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w300,
                              color: Colors.grey),
                        )
                      ],
                    ),
                    CircleAvatar(
                      backgroundImage: AssetImage('assets/images/messi-1805.jpg'),
                      radius: 30,
                    )
                  ],
                ),
                SizedBox(
                  height: 10,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Trending Courses',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 10,),
                Container(
                  height: 130,
                  child: StreamBuilder(
                    stream: FirebaseFirestore.instance.collection('courses').snapshots(),
                    builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
            
                      var courses = snapshot.data?.docs ?? [];
            
                      return ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: courses.length,
                        itemBuilder: (context, index) {
                          var course = courses[index].data() as Map<String, dynamic>;
            
                          return GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(builder: (context) => ScreenCourseDetails(courseId: courses[index].id),));
                            },
                            child: Stack(
                              children: [
                                Container(
                                  height: 150,
                                  width: 220,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Image.network(course['image'], fit: BoxFit.cover),
                                  ),
                                ),
                                Positioned(
                                  top: 10,
                                  left: 10,
                                  child: Container(
                                    decoration: BoxDecoration(
                                        color: Colors.white60,
                                        borderRadius: BorderRadius.circular(20)
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        course['name'] ?? 'No Title',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 10,
                                  left: 10,
                                  child: Row(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                            color: Colors.white60,
                                            borderRadius: BorderRadius.circular(20)
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: Text(
                                            course['category'] ?? 'Unknown',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 10,),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white60,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: Text(
                                            '${course['duration']} Weeks' ?? 'Unknown',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  bottom: 10,
                                  right: 10,
                                  child: Container(
                                    decoration: BoxDecoration(
                                        color: Colors.white60,
                                        borderRadius: BorderRadius.circular(20)
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Text(
                                        '₹${course['price'] ?? '0'}',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        separatorBuilder: (context, index) => SizedBox(width: 10),
                      );
                    },
                  ),
                ),
            
                SizedBox(
                  height: 20,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Suggested  for you',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 10,),
                Container(
                  height: 130,
                  child: StreamBuilder(
                    stream: FirebaseFirestore.instance.collection('courses').snapshots(),
                    builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
            
                      var courses = snapshot.data?.docs ?? [];
            
                      return ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: courses.length,
                        itemBuilder: (context, index) {
                          var course = courses[index].data() as Map<String, dynamic>;
            
                          return GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(builder: (context) => ScreenCourseDetails(courseId: courses[index].id),));
                            },
                            child: Stack(
                              children: [
                                Container(
                                  height: 150,
                                  width: 220,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Image.network(course['image'], fit: BoxFit.cover),
                                  ),
                                ),
                                Positioned(
                                  top: 10,
                                  left: 10,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white60,
                                      borderRadius: BorderRadius.circular(20)
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        course['name'] ?? 'No Title',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 10,
                                  left: 10,
                                  child: Row(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                            color: Colors.white60,
                                            borderRadius: BorderRadius.circular(20)
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: Text(
                                            course['category'] ?? 'Unknown',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 10,),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white60,
                                            borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: Text(
                                            '${course['duration']} Weeks' ?? 'Unknown',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  bottom: 10,
                                  right: 10,
                                  child: Container(
                                    decoration: BoxDecoration(
                                        color: Colors.white60,
                                        borderRadius: BorderRadius.circular(20)
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Text(
                                        '₹${course['price'] ?? '0'}',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        separatorBuilder: (context, index) => SizedBox(width: 10),
                      );
                    },
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
