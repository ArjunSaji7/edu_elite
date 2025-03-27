import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addQuestionsToFirestore(String courseId, String weekId) async {
    CollectionReference questionsRef = _firestore
        .collection('courses')
        .doc(courseId)
        .collection('exams')
        .doc(weekId)
        .collection('questions');

    List<Map<String, dynamic>> questions = [
      {
        "question": "What is the correct syntax to output 'Hello, World!' in Python?",
        "options": {
          "A": "print(\"Hello, World!\")",
          "B": "echo \"Hello, World!\"",
          "C": "printf(\"Hello, World!\")",
          "D": "System.out.println(\"Hello, World!\")"
        },
        "correctAnswer": "A"
      },
      {
        "question": "Which of the following is used to define a function in Python?",
        "options": {
          "A": "def",
          "B": "func",
          "C": "define",
          "D": "function"
        },
        "correctAnswer": "A"
      },
      {
        "question": "What will be the output of print(2 ** 3)?",
        "options": {
          "A": "5",
          "B": "6",
          "C": "8",
          "D": "9"
        },
        "correctAnswer": "C"
      },
      {
        "question": "What data type is the result of 3 / 2 in Python 3?",
        "options": {
          "A": "int",
          "B": "float",
          "C": "double",
          "D": "long"
        },
        "correctAnswer": "B"
      },
      {
        "question": "Which of the following is used to take user input in Python?",
        "options": {
          "A": "scanf()",
          "B": "cin",
          "C": "input()",
          "D": "gets()"
        },
        "correctAnswer": "C"
      }
    ];

    for (var question in questions) {
      await questionsRef.add(question);
    }

    print("Questions added successfully!");
  }
}
