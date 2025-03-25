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
      backgroundColor: Colors.grey[100], // Light background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Greeting
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
                            SizedBox(width: 5),
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

                SizedBox(height: 20),

                // Trending Courses Section
                sectionTitle("🔥 Trending Courses"),
                SizedBox(height: 10),
                courseList(),

                SizedBox(height: 20),

                // Suggested Courses Section
                sectionTitle("🎯 Suggested for You"),
                SizedBox(height: 10),
                courseList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Section Title Widget
  Widget sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // Course List Widget
  Widget courseList() {
    return SizedBox(
      height: 150,
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
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ScreenCourseDetails(courseId: courses[index].id),
                  ));
                },
                child: courseCard(course),
              );
            },
            separatorBuilder: (context, index) => SizedBox(width: 10),
          );
        },
      ),
    );
  }

  // Course Card Widget
  Widget courseCard(Map<String, dynamic> course) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [Colors.deepPurple, Colors.purpleAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(2, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Course Image
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.network(
              course['image'],
              width: 220,
              height: 150,
              fit: BoxFit.cover,
            ),
          ),

          // Course Name
          Positioned(
            top: 10,
            left: 10,
            child: textContainer(course['name'] ?? 'No Title', 16, FontWeight.bold),
          ),

          // Category & Duration
          Positioned(
            bottom: 10,
            right: 10,
            child: textContainer('${course['duration'] ?? 'Unknown'} Weeks', 12, FontWeight.w500),
          ),

        ],
      ),
    );
  }

  // Styled Text Container for Overlays
  Widget textContainer(String text, double size, FontWeight weight) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: size,
          fontWeight: weight,
        ),
        maxLines: 2,


      ),
    );
  }
}
