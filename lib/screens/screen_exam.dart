import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'screen_course_structure.dart';

class ScreenExam extends StatefulWidget {
  final String courseId;
  final String weekId;

  const ScreenExam({super.key, required this.courseId, required this.weekId});

  @override
  State<ScreenExam> createState() => _ScreenExamState();
}

class _ScreenExamState extends State<ScreenExam> {
  List<Map<String, dynamic>> questions = [];
  int currentQuestionIndex = 0;
  bool isNextEnabled = false;
  bool isLoading = true;
  int score = 0;
  bool hasPassed = false;

  @override
  void initState() {
    super.initState();
    fetchQuestions();
  }

  Future<void> fetchQuestions() async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;

      // Fetch user's exam status
      DocumentSnapshot userCourse = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('purchased_courses')
          .doc(widget.courseId)
          .get();

      Map<String, dynamic>? userData =
          userCourse.data() as Map<String, dynamic>?;

      if (userData != null && userData.containsKey('weeks')) {
        Map<String, dynamic>? weekData = userData['weeks'][widget.weekId];

        if (weekData != null && weekData['status'] == 'Passed') {
          setState(() {
            hasPassed = true;
            isLoading = false;
          });
          return; // No need to fetch questions if the user has passed
        }
      }

      // Fetch exam questions
      final querySnapshot = await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.courseId)
          .collection('exams')
          .doc(widget.weekId)
          .collection('questions')
          .get();

      List<Map<String, dynamic>> fetchedQuestions =
          querySnapshot.docs.map((doc) {
        return {
          "id": doc.id,
          "question": doc["question"],
          "options": doc["options"],
          "correctAnswer": doc["correctAnswer"],
          "selectedAnswer": null, // Store user-selected answer
        };
      }).toList();

      setState(() {
        questions = fetchedQuestions;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching questions: $e");
    }
  }

  void selectAnswer(String option) {
    setState(() {
      questions[currentQuestionIndex]["selectedAnswer"] = option;
      isNextEnabled = true;
    });
  }

  void nextQuestion() {
    if (questions[currentQuestionIndex]["selectedAnswer"] ==
        questions[currentQuestionIndex]["correctAnswer"]) {
      score += 2; // Award 2 points if correct
    }

    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        isNextEnabled =
            questions[currentQuestionIndex]["selectedAnswer"] != null;
      });
    } else {
      // Show confirmation before submitting
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Submit Exam?"),
          content: const Text("Are you sure you want to submit your exam?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                submitExam();
              },
              child: const Text("Submit"),
            ),
          ],
        ),
      );
    }
  }

  void previousQuestion() {
    if (currentQuestionIndex > 0) {
      setState(() {
        currentQuestionIndex--;
        isNextEnabled =
            questions[currentQuestionIndex]["selectedAnswer"] != null;
      });
    }
  }

  Future<void> submitExam() async {
    if (hasPassed) return; // If already passed, do nothing

    String userId = FirebaseAuth.instance.currentUser!.uid;
    int totalMarks = questions.length * 2;
    bool isPassed = score >= (totalMarks / 2);

    try {
      DocumentReference userCourseRef = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('purchased_courses')
          .doc(widget.courseId);

      DocumentSnapshot userCourseDoc = await userCourseRef.get();
      Map<String, dynamic>? userData =
          userCourseDoc.data() as Map<String, dynamic>?;

      Map<String, dynamic> updatedWeeks = userData?['weeks'] ?? {};
      Map<String, dynamic> currentWeekData = updatedWeeks[widget.weekId] ?? {};

      if (!isPassed) {
        currentWeekData['marks'] = 0; // Reset marks if failed
      }

      currentWeekData['marks'] = score;
      currentWeekData['status'] = isPassed ? "Passed" : "Failed";

      updatedWeeks[widget.weekId] = currentWeekData;

      await userCourseRef.set({"weeks": updatedWeeks}, SetOptions(merge: true));

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(isPassed ? "Congratulations! 🎉" : "Exam Failed"),
          content: Text(
              "Your score: $score/$totalMarks\nYou have ${isPassed ? "Passed" : "Failed"} the exam."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (isPassed) {
                  Navigator.pop(context);
                } else {
                  resetExam(); // Restart the exam if the user failed
                }
              },
              child: Text(isPassed ? "Back" : "Try Again"),
            ),
          ],
        ),
      );
    } catch (e) {
      print("Error updating score: $e");
    }
  }

  void resetExam() {
    setState(() {
      score = 0;
      currentQuestionIndex = 0;
      isNextEnabled = false;
      questions = [];
      isLoading = true; // Show loading until questions are fetched again
    });
    fetchQuestions(); // Re-fetch questions from Firestore
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // ✅ If user already passed, show message instead of questions
    if (hasPassed) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.deepPurple,
          elevation: 0,
          title: const Text(
            "Exam Completed",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ScreenCourseStructure(courseId: widget.courseId),
                ),
              );            },
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 80),
                const SizedBox(height: 20),
                const Text(
                  "You have already passed this exam!",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ScreenCourseStructure(courseId: widget.courseId),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: const Text("Back"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ✅ If user has NOT passed, show questions
    final questionData = questions[currentQuestionIndex];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar:
          AppBar(title: Text("Exam - Question ${currentQuestionIndex + 1}")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (currentQuestionIndex + 1) / questions.length,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                minHeight: 10,
              ),
            ),
            Text(questionData["question"],
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Column(
              children: (questionData["options"] as Map<String, dynamic>)
                  .entries
                  .map((entry) {
                return GestureDetector(
                  onTap: () => selectAnswer(entry.key),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: questionData["selectedAnswer"] == entry.key
                          ? Colors.blueAccent
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black),
                    ),
                    child: Text("${entry.key}. ${entry.value}",
                        style: const TextStyle(fontSize: 16)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                    onPressed: previousQuestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade100, // Button color
                      foregroundColor: Colors.deepPurple, // Text color
                      padding: EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12), // Padding
                      elevation: 5, // Shadow effect
                    ),
                    child: const Text("Previous")),
                ElevatedButton(
                  onPressed: isNextEnabled ? nextQuestion : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple, // Button color
                    foregroundColor: Colors.white, // Text color
                    padding: EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12), // Padding
                    elevation: 5, // Shadow effect
                  ),
                  child: const Text("Next"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
