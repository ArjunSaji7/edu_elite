import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'dart:async';


class ScreenCourseStructure extends StatefulWidget {
  final String courseId;
  const ScreenCourseStructure({super.key, required this.courseId});

  @override
  State<ScreenCourseStructure> createState() => _ScreenCourseStructureState();
}

class _ScreenCourseStructureState extends State<ScreenCourseStructure> {
  late Future<DocumentSnapshot<Map<String, dynamic>>> _courseFuture;
  VideoPlayerController? _videoController;
  bool _isLoadingVideo = false;
  String? _currentVideoUrl;

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

  void _playVideo(String videoFileName) async {
    setState(() {
      _isLoadingVideo = true;
    });

    String videoUrl = await getVideoUrl(videoFileName);
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
    _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
      ..initialize().then((_) {
        setState(() => _isLoadingVideo = false);
        _videoController!.play();
      }).catchError((error) {
        debugPrint("Video error: $error");
        setState(() => _isLoadingVideo = false);
      });
  }

  void _openFullScreen() {
    if (_videoController == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenVideoPlayer(controller: _videoController!),
      ),
    );
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text("Lessons", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
          String image = course['image'] ??
              "https://projects-static.raspberrypi.org/collections/assets/python_placeholder.png";
          List<dynamic> lessons = course['lessons'] ?? [];

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // 📌 Video Section (or Image if no video)
                _currentVideoUrl == null
                    ? Container(
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                    image: DecorationImage(image: NetworkImage(image), fit: BoxFit.cover),
                  ),
                )
                    : VideoPlayerWidget(
                  controller: _videoController!,
                  isLoading: _isLoadingVideo,
                  openFullScreen: _openFullScreen,
                ),
                const SizedBox(height: 20),

                // 📌 Lessons List (Scrollable)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Column(
                    children: List.generate(lessons.length, (index) {
                      Map<String, dynamic> lesson = lessons[index];
                      String title = lesson['title'] ?? "No Title";
                      List<dynamic> videos = lesson['videos'] ?? [];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                              spreadRadius: 2,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                        child: ExpansionTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          title: Text(
                            'Week ${index + 1} : $title',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: videos.isEmpty
                                    ? [
                                  const Text("No videos available",
                                      style: TextStyle(color: Colors.red, fontSize: 14))
                                ]
                                    : videos.map((video) {
                                  return ListTile(
                                    leading: const Icon(Icons.play_circle_fill, color: Colors.green),
                                    title: Text(video.toString()),
                                    onTap: () => _playVideo(video),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// 📌 Video Player Widget (Main Screen)
class VideoPlayerWidget extends StatefulWidget {
  final VideoPlayerController controller;
  final bool isLoading;
  final VoidCallback openFullScreen;

  const VideoPlayerWidget({
    super.key,
    required this.controller,
    required this.isLoading,
    required this.openFullScreen,
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
          ],
        ),
      ),
    );
  }
}



class FullScreenVideoPlayer extends StatefulWidget {
  final VideoPlayerController controller;
  const FullScreenVideoPlayer({super.key, required this.controller});

  @override
  State<FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
  bool _showControls = true;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    _setLandscapeMode();
    _startHideTimer();
  }

  /// 🔄 Set Full-Screen Mode
  void _setLandscapeMode() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  /// 🔄 Reset to Portrait Mode BEFORE closing
  void _resetPortraitMode() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  /// 🎛 Toggle Controls
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

  /// ⏳ Auto-Hide Controls After 3 Secs
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

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    super.dispose();
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

            // 🎥 Play / Pause Button (Auto-hide)
            if (_showControls)
              AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      widget.controller.value.isPlaying
                          ? widget.controller.pause()
                          : widget.controller.play();
                      _startHideTimer();
                    });
                  },
                  child: Container(
                    decoration: const BoxDecoration(
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

            // ⏳ Video Progress (Bottom-Center)
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

            // ❌ Close Button (Auto-hide)
            if (_showControls)
              Positioned(
                top: 20,
                left: 20,
                child: AnimatedOpacity(
                  opacity: _showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: () {
                      _resetPortraitMode(); // ✅ Reset portrait BEFORE closing
                      Navigator.pop(context);

                      // ✅ Ensure UI rebuilds correctly after closing
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        setState(() {});
                      });
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}



