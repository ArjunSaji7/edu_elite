import 'package:edu_elite/screens/screen_course_details.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:material_floating_search_bar_2/material_floating_search_bar_2.dart';

class ScreenSearch extends StatefulWidget {
  const ScreenSearch({super.key});

  @override
  State<ScreenSearch> createState() => _ScreenSearchState();
}

class _ScreenSearchState extends State<ScreenSearch> {
  List<Map<String, dynamic>> allCourses = [];
  List<Map<String, dynamic>> filteredCourses = [];
  bool isLoading = true;
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    fetchCourses();
  }

  Future<void> fetchCourses() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('courses').get();
      final courses = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'courseId': doc.id,
          'name': data['name'] ?? 'Untitled Course',
          'category': data['category'] ?? 'General',
          'duration': data['duration'] ?? 'N/A',
          'price': data['price'] ?? 'N/A',
          'image': data['image'] ?? 'https://via.placeholder.com/150',
        };
      }).toList();

      setState(() {
        allCourses = courses;
        filteredCourses = courses; // Initially show all courses
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching courses: $e");
      setState(() => isLoading = false);
    }
  }

  void filterCourses(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 100),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredCourses.isEmpty
                ? const Center(child: Text("No courses found."))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredCourses.length,
              itemBuilder: (context, index) {
                final course = filteredCourses[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 3,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        course['image'],
                        width: 80,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Image.network('https://via.placeholder.com/150', width: 80, height: 60),
                      ),
                    ),
                    title: Text(course['name'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold
                    ),
                    ),
                    subtitle: Text('${course['category']} | ${course['duration']} weeks | ₹${course['price']}'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ScreenCourseDetails(courseId: course['courseId']),
                        ),
                      );
                      debugPrint("Tapped on ${course['name']}");
                    },
                  ),
                );
              },
            ),
          ),
          buildFloatingSearchBar(),
        ],
      ),
    );
  }

  Widget buildFloatingSearchBar() {
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    return FloatingSearchBar(
      hint: 'Search courses or categories...',
      scrollPadding: const EdgeInsets.only(top: 16, bottom: 56),
      borderRadius: BorderRadius.circular(20),
      backgroundColor: Colors.blue.shade100,
      border:BorderSide(color: Colors.blue.shade400),
      transitionDuration: const Duration(milliseconds: 800),
      transitionCurve: Curves.easeInOut,
      physics: const BouncingScrollPhysics(),
      axisAlignment: isPortrait ? 0.0 : -1.0,
      openAxisAlignment: 0.0,
      width: isPortrait ? 600 : 500,
      height: 60,
      debounceDelay: const Duration(milliseconds: 300),
      onQueryChanged: (query) => filterCourses(query),
      transition: CircularFloatingSearchBarTransition(),
      actions: [
        FloatingSearchBarAction.searchToClear(
          showIfClosed: true,
          size: 30,
          color: Colors.blue.shade900,
        ),
      ],
        builder: (context, transition) {
          final List<Map<String, dynamic>> searchResults = allCourses.where((course) {
            final name = (course['name'] as String).toLowerCase();
            final category = (course['category'] as String).toLowerCase();
            return name.contains(searchQuery) || category.contains(searchQuery);
          }).toList();

          if (searchQuery.isEmpty) {
            return Container(); // Hide when the search bar is empty
          }

          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Material(
              color: Colors.white,
              elevation: 4.0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: searchResults.isEmpty
                    ? [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Lottie.asset(
                          'assets/lottie/no_results.json',
                          width: 150,
                          height: 150,
                          fit: BoxFit.fill,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "No courses found!",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.red.shade200),
                        ),
                      ],
                    ),
                  ),
                ]
                    : searchResults
                    .take(5)
                    .map((course) => ListTile(
                  title: Text(course['name']),
                  subtitle: Text(course['category']),
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(course['image']),
                    backgroundColor: Colors.grey.shade200,
                  ),
                  onTap: () {
                    // debugPrint("Selected ${course['name']}");
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ScreenCourseDetails(courseId: course['courseId']),
                      ),
                    );                 },
                ))
                    .toList(),
              ),
            ),
          );
        },
    );
  }
}
