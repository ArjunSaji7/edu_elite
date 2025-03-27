import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edu_elite/screens/screen_exam.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/firestore_service.dart';


class ScreenCourseStructure extends StatefulWidget {
  final String courseId;
  const ScreenCourseStructure({super.key, required this.courseId});

  @override
  State<ScreenCourseStructure> createState() => _ScreenCourseStructureState();
}

class _ScreenCourseStructureState extends State<ScreenCourseStructure> {
  String? userId = FirebaseAuth.instance.currentUser?.uid;
  late Future<DocumentSnapshot<Map<String, dynamic>>> _courseFuture;
  VideoPlayerController? _videoController;
  bool _isLoadingVideo = false;
  String? _currentVideoUrl;
  final Map<String, double> _videoProgress = {}; // Track progress per video
  final FirestoreService firestoreService = FirestoreService(); // Create instance



  @override
  void initState() {
    super.initState();
    _courseFuture = getCourseDetails();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getCourseDetails() {
    return FirebaseFirestore.instance.collection('courses').doc(widget.courseId).get();
  }

  Future<String> getVideoUrl(String fileName) async {
    try {
      return await FirebaseStorage.instance.ref(fileName).getDownloadURL();
    } catch (e) {
      debugPrint("Error fetching video URL: $e");
      return '';
    }
  }

  void _playVideo(String courseId, String videoId) async {
    setState(() {
      _isLoadingVideo = true;
    });

    String videoUrl = await getVideoUrl(videoId);
    if (videoUrl.isEmpty) {
      setState(() {
        _isLoadingVideo = false;
      });
      return;
    }

    if (_currentVideoUrl == videoUrl) return;

    setState(() {
      _currentVideoUrl = videoUrl;
    });

    _videoController?.dispose();
    _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));

    // Fetch last saved progress before initializing the player
    double lastProgress = await getLastSavedProgress(courseId, videoId);

    _videoController!.initialize().then((_) {
      setState(() => _isLoadingVideo = false);

      // Resume from last saved progress
      Duration lastPosition = Duration(seconds: (lastProgress * _videoController!.value.duration.inSeconds).toInt());
      _videoController!.seekTo(lastPosition);

      _videoController!.play();

      // Update progress periodically
      _videoController!.addListener(() {
        final duration = _videoController!.value.duration;
        final position = _videoController!.value.position;

        if (duration.inSeconds > 0) {
          double progress = position.inSeconds / duration.inSeconds;
          updateVideoProgress(courseId, videoId, progress);
        }
      });
    }).catchError((error) {
      debugPrint("Video error: $error");
      setState(() => _isLoadingVideo = false);
    });
  }

  Future<double> getLastSavedProgress(String courseId, String videoId) async {
    try {
      DocumentSnapshot progressSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('purchased_courses')
          .doc(courseId)
          .collection('videos')
          .doc(videoId)
          .get();

      if (progressSnapshot.exists) {
        var data = progressSnapshot.data() as Map<String, dynamic>;
        return (data['progress'] ?? 0) / 100.0; // Convert back to decimal
      }
    } catch (e) {
      debugPrint("Error fetching progress: $e");
    }
    return 0.0; // Default to 0 if no progress found
  }

  Future<void> updateVideoProgress(String courseId, String videoId, double progress) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('purchased_courses')
          .doc(courseId)
          .collection('videos')
          .doc(videoId)
          .get();

      double savedProgress = 0.0;
      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;
        savedProgress = (data['progress'] ?? 0) / 100.0;
      }

      // Update only if new progress is higher
      if (progress > savedProgress) {
        bool isCompleted = progress >= 1.0; // Mark video as completed if progress is 100%

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('purchased_courses')
            .doc(courseId)
            .collection('videos')
            .doc(videoId)
            .set({
          'progress': (progress * 100).toInt(),
          'isCompleted': isCompleted,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint("Error updating progress: $e");
    }
  }



  void _openFullScreen() {
    if (_videoController == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenVideoPlayer(controller: _videoController!, videoUrl: _currentVideoUrl.toString(),),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        title: const Text(
          "Course Content",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Stop and dispose the video before exiting
            if (_videoController != null) {
              _videoController!.pause();
              _videoController!.dispose();
            }
            Navigator.pop(context);
          },
        ),
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _courseFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading course"));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Course not found"));
          }

          var course = snapshot.data!.data()!;
          String image = course['image'] ?? "https://projects-static.raspberrypi.org/collections/assets/python_placeholder.png";
          List<dynamic> lessons = course['lessons'] ?? [];

          return Column(
            children: [
              // Video Player Section
              if (_currentVideoUrl == null)
                _buildCourseHeader(image)
              else
                VideoPlayerWidget(
                  controller: _videoController!,
                  isLoading: _isLoadingVideo,
                  openFullScreen: _openFullScreen,
                  videoUrl: _currentVideoUrl.toString(),
                ),

              // Content List
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: SizedBox(height: 16)),

                    // Lessons List
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          Map<String, dynamic> lesson = lessons[index];
                          String title = lesson['title'] ?? "Untitled Lesson";
                          List<dynamic> videos = lesson['videos'] ?? [];

                          return FutureBuilder<List<Map<String, dynamic>>>(
                            future: _getVideoCompletionData(videos),
                            builder: (context, snapshot) {
                              int completedCount = 0;
                              int totalVideos = videos.length;

                              if (snapshot.hasData) {
                                completedCount = snapshot.data!.where((v) => v['isCompleted']).length;
                              }

                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: ExpansionTile(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  tilePadding: const EdgeInsets.symmetric(horizontal: 20),
                                  leading: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.deepPurple.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        "Week ${index + 1}",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.deepPurple,
                                        ),
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "$completedCount/$totalVideos videos completed",
                                    style: TextStyle(
                                      color: completedCount == totalVideos ? Colors.green : Colors.grey[600],
                                    ),
                                  ),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Column(
                                        spacing: 10,
                                        children: [
                                          ...videos.map((video) => _buildVideoItem(video)),
                                          if (totalVideos!= 0 && completedCount == totalVideos) // Add exams after last lesson
                                            GestureDetector(
                                              onTap: () async {
                                                 // await firestoreService.addQuestionsToFirestore("9hBw9cWas1r0IaNVM4s7", "week2");

                                                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => ScreenExam(courseId: widget.courseId, weekId: 'week${index + 1}'),));

                                              },
                                              child: Container(
                                                height: 50,
                                                decoration:BoxDecoration(
                                                  borderRadius: BorderRadius.circular(10),
                                                  color: Colors.blue
                                                ),
                                                child: Center(child: Text('Week ${index +1} Exam')),
                                              ),
                                            )
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        childCount: lessons.length,
                      ),
                    ),
                    SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }


  Widget _buildCourseHeader(String imageUrl) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.3), BlendMode.darken),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            Text("Tap a video to start learning",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                )),
          ],
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getVideoCompletionData(List<dynamic> videoIds) async {
    List<Map<String, dynamic>> results = [];

    for (var videoId in videoIds) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('purchased_courses')
            .doc(widget.courseId)
            .collection('videos')
            .doc(videoId)
            .get();

        if (doc.exists) {
          var data = doc.data() as Map<String, dynamic>;
          results.add({
            'isCompleted': data['isCompleted'] ?? false,
            'progress': data['progress'] ?? 0,
          });
        } else {
          results.add({'isCompleted': false, 'progress': 0});
        }
      } catch (e) {
        results.add({'isCompleted': false, 'progress': 0});
      }
    }

    return results;
  }

  Widget _buildVideoItem(String videoId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('purchased_courses')
          .doc(widget.courseId)
          .collection('videos')
          .doc(videoId)
          .snapshots(), // ✅ Listen for real-time updates
      builder: (context, snapshot) {
        bool isCompleted = false;
        double progress = 0;

        if (snapshot.hasData && snapshot.data!.exists) {
          var data = snapshot.data!.data() as Map<String, dynamic>;
          isCompleted = data['isCompleted'] ?? false;
          progress = (data['progress'] ?? 0) / 100.0;
        }

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted ? Colors.green.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                isCompleted ? Icons.check : Icons.play_arrow,
                color: isCompleted ? Colors.green : Colors.blue,
              ),
            ),
          ),
          title: Text(
            videoId,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.none,
              color: isCompleted ? Colors.grey : Colors.black,
            ),
          ),
          subtitle: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            color: isCompleted ? Colors.green : Colors.blue,
            minHeight: 2,
          ),
          trailing: Icon(Icons.chevron_right, color: Colors.grey),
          onTap: () => _playVideo(widget.courseId, videoId),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          focusColor: Color(0xFFDAB1DA),
        );
      },
    );
  }

}
// 📌 Video Player Widget (Main Screen)


class VideoPlayerWidget extends StatefulWidget {
  final VideoPlayerController controller;
  final bool isLoading;
  final VoidCallback openFullScreen;
  final String videoUrl; // URL of the video for downloading

  const VideoPlayerWidget({
    super.key,
    required this.controller,
    required this.isLoading,
    required this.openFullScreen,
    required this.videoUrl,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  bool _showControls = true;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    _startHideTimer();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });

    if (_showControls) {
      _startHideTimer();
    } else {
      _hideControlsTimer?.cancel();
    }
  }

  void _startHideTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        _showControls = false;
      });
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  Future<void> _downloadVideo() async {
    try {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Storage permission is required to download video")),
        );
        return;
      }

      // Define the directory path
      final directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      String savedDir = directory.path;

      // Extract filename from URL
      final uri = Uri.parse(widget.videoUrl);
      String filename = uri.pathSegments.lastOrNull ?? 'downloaded_video.mp4';
      String filePath = "$savedDir/$filename";

      // If file exists, rename it with (1), (2), etc.
      int count = 1;
      while (await File(filePath).exists()) {
        final fileExtension = filename.contains(".") ? filename.split(".").last : "mp4";
        final fileNameWithoutExt = filename.replaceAll(RegExp(r"\.[^.]*$"), ""); // Remove extension
        filename = "$fileNameWithoutExt ($count).$fileExtension";
        filePath = "$savedDir/$filename";
        count++;
      }

      // Start download
      final taskId = await FlutterDownloader.enqueue(
        url: widget.videoUrl,
        savedDir: savedDir,
        fileName: filename,
        showNotification: true,
        openFileFromNotification: true,
        requiresStorageNotLow: true,
      );

      if (taskId == null) {
        throw Exception('Download task could not be created');
      }

      // Listen for completion
      FlutterDownloader.registerCallback((id, status, progress) {
        if (id == taskId && status == DownloadTaskStatus.complete) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Download completed: $filename")),
          );
        }
      });

    } catch (e) {
      debugPrint("Download error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Download failed: ${e.toString()}")),
      );
    }
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleControls,
      child: AspectRatio(
        aspectRatio: widget.controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(widget.controller),
            if (widget.isLoading) const CircularProgressIndicator(color: Colors.white),

            // ⏯️ Pause / Play Button (Centered)
            if (_showControls)
              AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      widget.controller.value.isPlaying ? widget.controller.pause() : widget.controller.play();
                      _startHideTimer();
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      widget.controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                ),
              ),

            // 📺 Full-Screen Button (Bottom-Right)
            if (_showControls)
              Positioned(
                bottom: 10,
                right: 10,
                child: AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: IconButton(
                    icon: const Icon(Icons.fullscreen, color: Colors.white, size: 30),
                    onPressed: widget.openFullScreen,
                  ),
                ),
              ),

            // ⏳ Video Progress (Bottom-Center)
            if (_showControls)
              Positioned(
                bottom: 10,
                left: 10,
                child: ValueListenableBuilder(
                  valueListenable: widget.controller,
                  builder: (context, VideoPlayerValue value, child) {
                    final position = _formatDuration(value.position);
                    final duration = _formatDuration(value.duration);
                    return Text(
                      "$position / $duration",
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      textAlign: TextAlign.center,
                    );
                  },
                ),
              ),

            // ⬇️ Download Button (Bottom-Left)
            if (_showControls)
              Positioned(
                bottom: 10,
                right: 50,
                child: AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: IconButton(
                    icon: const Icon(Icons.download, color: Colors.white, size: 30),
                    onPressed: _downloadVideo,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class FullScreenVideoPlayer extends StatefulWidget {
  final VideoPlayerController controller;
  final String videoUrl;
  const FullScreenVideoPlayer({super.key, required this.controller, required this.videoUrl});

  @override
  State<FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
  bool _showControls = true;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setLandscapeMode();
    });
    _startHideTimer();
  }

  void _setLandscapeMode() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _resetPortraitMode() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown
    ]);
    //SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  @override
  void dispose() {
    _resetPortraitMode(); // Reset orientation when exiting full screen
    _hideControlsTimer?.cancel();
    super.dispose();
  }


  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });

    if (_showControls) {
      _startHideTimer();
    } else {
      _hideControlsTimer?.cancel();
    }
  }

  void _startHideTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        _showControls = false;
      });
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  Future<void> _downloadVideo() async {
    try {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Storage permission is required to download video")),
        );
        return;
      }

      final directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      String savedDir = directory.path;

      final uri = Uri.parse(widget.videoUrl);
      String filename = uri.pathSegments.lastOrNull ?? 'downloaded_video.mp4';
      String filePath = "$savedDir/$filename";
      int count = 1;
      while (await File(filePath).exists()) {
        final fileExtension = filename.contains(".") ? filename.split(".").last : "mp4";
        final fileNameWithoutExt = filename.replaceAll(RegExp(r"\.[^.]*$"), "");
        filename = "$fileNameWithoutExt ($count).$fileExtension";
        filePath = "$savedDir/$filename";
        count++;
      }

      final taskId = await FlutterDownloader.enqueue(
        url: widget.videoUrl,
        savedDir: savedDir,
        fileName: filename,
        showNotification: true,
        openFileFromNotification: true,
        requiresStorageNotLow: true,
      );

      if (taskId == null) {
        throw Exception('Download task could not be created');
      }

      FlutterDownloader.registerCallback((id, status, progress) {
        if (id == taskId && status == DownloadTaskStatus.complete) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Download completed: $filename")),
          );
        }
      });
    } catch (e) {
      debugPrint("Download error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Download failed: \${e.toString()}")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: widget.controller.value.aspectRatio,
                child: VideoPlayer(widget.controller),
              ),
            ),

            if (_showControls)
              GestureDetector(
                onTap: () {
                  setState(() {
                    widget.controller.value.isPlaying
                        ? widget.controller.pause()
                        : widget.controller.play();
                    _startHideTimer();
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    widget.controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ),

            if (_showControls)
              Positioned(
                bottom: 20,
                left: 20,
                child: ValueListenableBuilder(
                  valueListenable: widget.controller,
                  builder: (context, VideoPlayerValue value, child) {
                    final position = _formatDuration(value.position);
                    final duration = _formatDuration(value.duration);
                    return Text(
                      "$position / $duration",
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      textAlign: TextAlign.center,
                    );
                  },
                ),
              ),

            if (_showControls)
              Positioned(
                bottom: 20,
                right: 60,
                child: IconButton(
                  icon: const Icon(Icons.download, color: Colors.white, size: 40),
                  onPressed: _downloadVideo,
                ),
              ),

            if (_showControls)
              Positioned(
                bottom: 20,
                right: 10,
                child: IconButton(
                  icon: const Icon(Icons.fullscreen_exit, color: Colors.white, size: 40),
                  onPressed: () {
                    _resetPortraitMode();
                    Navigator.pop(context);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {});
                    });
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}




