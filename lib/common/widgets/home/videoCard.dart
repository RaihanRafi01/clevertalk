import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoCard extends StatefulWidget {
  final String videoUrl;
  final VoidCallback onNextVideo;
  final VoidCallback onPreviousVideo;

  const VideoCard({
    required this.videoUrl,
    required this.onNextVideo,
    required this.onPreviousVideo,
    Key? key,
  }) : super(key: key);

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _isPlaying = false;
      } else {
        _controller.play();
        _isPlaying = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Video Player
          ClipRRect(
            borderRadius: BorderRadius.circular(16.0),
            child: AspectRatio(
              aspectRatio: _controller.value.isInitialized
                  ? _controller.value.aspectRatio
                  : 16 / 9,
              child: _controller.value.isInitialized
                  ? VideoPlayer(_controller)
                  : Center(child: CircularProgressIndicator()),
            ),
          ),

          // Center Play Button
          if (_controller.value.isInitialized)
            Positioned(
              child: GestureDetector(
                onTap: _togglePlayPause,
                child: Icon(
                  _isPlaying ? Icons.pause_circle : Icons.play_circle,
                  color: Colors.white,
                  size: 64.0,
                ),
              ),
            ),

          // Left Navigation Button
          Positioned(
            left: 8.0,
            child: GestureDetector(
              onTap: widget.onPreviousVideo,
              child: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.5),
                child: Icon(Icons.navigate_before, color: Colors.white),
              ),
            ),
          ),

          // Right Navigation Button
          Positioned(
            right: 8.0,
            child: GestureDetector(
              onTap: widget.onNextVideo,
              child: CircleAvatar(
                backgroundColor: Colors.black.withOpacity(0.5),
                child: Icon(Icons.navigate_next, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
