import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'screen_course_structure.dart';

class ScreenCourseDetails extends StatefulWidget {
  final String courseId;
  const ScreenCourseDetails({super.key, required this.courseId});

  @override
  State<ScreenCourseDetails> createState() => _ScreenCourseDetailsState();
}

class _ScreenCourseDetailsState extends State<ScreenCourseDetails> {
  bool isPurchased = false;

  @override
  void initState() {
    super.initState();
    _isCoursePurchased();
  }

  // Function to check if the course is already purchased
  Future<void> _isCoursePurchased() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    String userId = auth.currentUser?.uid ?? "";

    if (userId.isNotEmpty) {
      DocumentSnapshot purchasedCourse = await firestore
          .collection('users')
          .doc(userId)
          .collection('purchased_courses')
          .doc(widget.courseId)
          .get();

      if (purchasedCourse.exists) {
        setState(() {
          isPurchased = true;
        });
      }
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getCourseDetails() {
    return FirebaseFirestore.instance
        .collection('courses')
        .doc(widget.courseId)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: Text(
          "Course Details",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
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
                    height: 250,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
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
                        Text(name, style: TextStyle(
                            fontSize: 26, fontWeight: FontWeight.bold)),
                        SizedBox(height: 5),
                        Row(
                          children: [
                            Chip(label: Text(category)),
                            SizedBox(width: 10),
                            Chip(label: Text('$duration Weeks')),
                          ],
                        ),
                        SizedBox(height: 15),

                        // Price & Buy Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isPurchased ? "Enrolled" : "₹$price",
                              style: TextStyle(fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                if (isPurchased) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ScreenCourseStructure(
                                              courseId: widget.courseId),
                                    ),
                                  );
                                } else {
                                  _buyCourse(
                                      context, widget.courseId, name, price, duration, image);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isPurchased
                                    ? Colors.green
                                    : Colors.deepPurple,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                              ),
                              child: Text(
                                isPurchased ? "Go to Course" : "Buy Course",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),

                        Text("About the Course", style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                        SizedBox(height: 5),
                        Text(description, style: TextStyle(fontSize: 16)
                        ),

                        Text("Instructors", style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                        SizedBox(height: 10),
                        Column(
                          children: teachers.map((teacher) =>
                              ListTile(
                                leading: CircleAvatar(
                                    backgroundColor: Colors.deepPurple,
                                    child: Text(teacher[0],
                                      style: TextStyle(color: Colors.white),)),
                                title: Text(teacher, style: TextStyle(
                                    fontWeight: FontWeight.bold)),
                                subtitle: Text("Expert Instructor"),
                              )).toList(),
                        ),
                        SizedBox(height: 20),

// Course Features
                        Text("Key Features", style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            _featureCard("Hands-on Projects", Icons.build),
                            SizedBox(width: 10),
                            _featureCard("Real-world Applications", Icons
                                .computer),
                          ],
                        ),
                        SizedBox(height: 20),

// Reviews
                        Text("Reviews", style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                        SizedBox(height: 10),
                        _reviewCard(
                            "Sophia A.", "Great course, highly recommended!"),
                        _reviewCard("Ava M.", "Loved the hands-on approach!"),
                        SizedBox(height: 20),
                      ],
                    ),

                  )
                ],
              )
          );
        }
        ),
          );
  }

  Widget _featureCard(String text, IconData icon) {
    return Expanded(
      child: Container(
        height: 120,
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.deepPurple.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.deepPurple),
            SizedBox(height: 5),
            Text(text, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          ],
        ),
      ),
    );
  }

  Widget _reviewCard(String user, String review) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: Colors.deepPurple, child: Text(user[0], style: TextStyle(color: Colors.white),)),
        title: Text(user, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        subtitle: Text(review),
      ),
    );
  }

  void _buyCourse(BuildContext context, String courseId, String courseName, double price, int duration, String image) {
    showDialog(
      context: context,
      builder: (modalContext) {
        return AlertDialog(
          title: Text("Confirm Purchase"),
          content: Text("Do you want to buy \"$courseName\" for ₹$price?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(modalContext),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                bool success = await _processPurchase(courseId, courseName, price, duration, image);
                if (success) {
                  Navigator.pop(modalContext);
                  setState(() {
                    isPurchased = true;
                  });
                  _showSuccessAnimation(context); // 🎉 Show Lottie animation
                }
              },
              child: Text("Confirm Purchase"),
            ),
          ],
        );
      },
    );
  }

// 🎬 Show Lottie Animation for Success
  void _showSuccessAnimation(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        Future.delayed(const Duration(seconds: 4), () {
          Navigator.pop(context); // Close after 4 seconds
        });

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🎬 Lottie Animation
                Lottie.asset(
                  "assets/lottie/payment_succes.json", // ✅ Ensure the correct path
                  repeat: false,
                  width: 200,
                  height: 200,
                ),
                const SizedBox(height: 10),

                // ✅ Success Message
                const Text(
                  "Purchase Successful!",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // 🛍️ Subtitle
                const Text(
                  "You have successfully purchased this course.\nEnjoy learning!",
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 15),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _processPurchase(String courseId, String courseName, double price, int duration, String image) async {
    try {
      FirebaseAuth auth = FirebaseAuth.instance;
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      String userId = auth.currentUser?.uid ?? "";

      if (userId.isEmpty) {
        throw Exception("User not logged in.");
      }

      // Add course to 'purchased_courses' subcollection inside the user document
      await firestore
          .collection('users')
          .doc(userId)
          .collection('purchased_courses')
          .doc(courseId)
          .set({
        'courseId': courseId,
        'courseName': courseName,
        'duration': duration,
        'price': price,
        'image':image,
        'purchasedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (error) {
      print("Error processing purchase: $error");
      return false;
    }
  }
}


