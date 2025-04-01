import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'screen_course_structure.dart';

class ScreenMyCourse extends StatefulWidget {
  const ScreenMyCourse({super.key});

  @override
  State<ScreenMyCourse> createState() => _ScreenMyCourseState();
}

class _ScreenMyCourseState extends State<ScreenMyCourse> {
  List<Map<String, dynamic>> purchasedCourses = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPurchasedCoursesForCurrentUser();
  }

  Future<void> fetchPurchasedCoursesForCurrentUser() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        debugPrint("User not logged in");
        setState(() => isLoading = false);
        return;
      }

      final userId = currentUser.uid;

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('purchased_courses')
          .get();

      final courses = snapshot.docs
          .where((doc) => doc.id != 'init') // 🔥 filter out 'init' doc
          .map((doc) {
        final data = doc.data();

        return {
          'courseId': doc.id,
          'courseName': data['courseName'] ?? 'Untitled Course',
          'duration': data['duration'] ?? 1,
          'price': data['price'] ?? 'N/A',
          'image': data['image'] ?? 'https://via.placeholder.com/150',
          'weeks': data['weeks'] ?? {},
        };
      }).toList();

      setState(() {
        purchasedCourses = courses;
        isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint("Error fetching user courses: $e");
      debugPrint("StackTrace: $stackTrace");
      setState(() => isLoading = false);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to load your courses. Please try again."),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "My Courses",
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
            ),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : Expanded(
              child: purchasedCourses.isEmpty
                  ? const Center(child: Text("No purchased courses found."))
                  : ListView.builder(
                itemCount: purchasedCourses.length,
                itemBuilder: (context, index) {
                  final course = purchasedCourses[index];
                  final duration = course['duration'] ?? 1;
                  final weeks = (course['weeks'] ?? {}) as Map<dynamic, dynamic>;
                  print(course);

                  int completedWeeks = 0;

                  for (var weekEntry in weeks.entries) {
                    final weekData = weekEntry.value;
                    if (weekData is Map<String, dynamic> && weekData['status'] == "Passed") {
                      completedWeeks++;
                    }
                  }

                  final progress = completedWeeks / duration;
                  print('progress $progress');
                  print("completedWeeks $completedWeeks");
                  print('duration $duration');
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ScreenCourseStructure(
                              courseId: course['courseId'],
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: ListTile(
                        leading: Container(
                          width: 100,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              fit: BoxFit.cover,
                              image: NetworkImage(course['image']),
                            ),
                          ),
                        ),
                        title: Text(course['courseName']),
                        subtitle: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${course['duration']} weeks'),
                            Text('₹${course['price']}'),
                          ],
                        ),
                          trailing: SizedBox(
                            width: 50,
                            height: 50,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: progress.clamp(0.0, 1.0),
                                  color: Colors.green,
                                  backgroundColor: Colors.grey.shade300,
                                  strokeWidth: 5,
                                ),
                                Text(
                                  "${(progress * 100).toInt()}%",
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Colors.grey.shade300)
                        )
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
