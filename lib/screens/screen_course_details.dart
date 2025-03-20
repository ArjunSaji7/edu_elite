import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ScreenCourseDetails extends StatefulWidget {
  final String courseId;
  const ScreenCourseDetails({super.key, required this.courseId});

  @override
  State<ScreenCourseDetails> createState() => _ScreenCourseDetailsState();
}

class _ScreenCourseDetailsState extends State<ScreenCourseDetails> {
  Future<DocumentSnapshot<Map<String, dynamic>>> getCourseDetails() {
    return FirebaseFirestore.instance
        .collection('courses')
        .doc(widget.courseId)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.blueAccent, title: Text("Course Details", style: TextStyle(fontWeight: FontWeight.bold),)),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: getCourseDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error loading course"));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text("Course not found"));
          }

          var course = snapshot.data!.data()!;
          String name = course['name'] ?? "No Title";
          String category = course['category'] ?? "No Category";
          String description = course['description'] ?? "No Description";
          int duration = course['duration'] ?? 0;
          String image = course['image'] ??
              "https://projects-static.raspberrypi.org/collections/assets/python_placeholder.png";
          double price = (course['price'] as num?)?.toDouble() ?? 0.0;
          List<String> teachers = List<String>.from(course['teachers'] ?? []);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Course Image
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(image),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Course Title & Category
                      Text(name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      SizedBox(height: 5),
                      Row(
                        spacing: 10,
                        children: [
                          Text(category, style: TextStyle(fontSize: 16, color: Colors.grey)),
                          Text('${duration.toString()} Weeks', style: TextStyle(fontSize: 16, color: Colors.grey)),
                        ],
                      ),

                      // Pricing & Buy Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("₹$price",
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                            child: Text("Buy Course",
                              style: TextStyle(
                                color: Colors.white
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),

                      // Description
                      Text("About the Course", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 5),
                      Text(description, style: TextStyle(fontSize: 16)),
                      SizedBox(height: 15),

                      // Teachers
                      Text("Teachers", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 5),
                      Column(
                        children: teachers
                            .map((teacher) => ListTile(
                          leading: CircleAvatar(backgroundColor: Colors.deepPurple, child: Text(teacher[0])),
                          title: Text(teacher),
                          subtitle: Text("Experienced Instructor"),
                        ))
                            .toList(),
                      ),
                      SizedBox(height: 15),

                      // Course Features
                      Text("What will you learn?", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          _featureCard("Hands-on Projects", Icons.build),
                          SizedBox(width: 10),
                          _featureCard("Real-world Applications", Icons.computer),
                        ],
                      ),
                      SizedBox(height: 15),

                      // Reviews Placeholder
                      Text("Reviews", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 5),
                      _reviewCard("Sophia A.", "Great course, highly recommended!"),
                      _reviewCard("Ava M.", "Loved the hands-on approach!"),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _featureCard(String text, IconData icon) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.deepPurple.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: Colors.deepPurple),
            SizedBox(height: 5),
            Text(text, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _reviewCard(String user, String review) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: Colors.deepPurple, child: Text(user[0])),
        title: Text(user),
        subtitle: Text(review),
      ),
    );
  }
}
