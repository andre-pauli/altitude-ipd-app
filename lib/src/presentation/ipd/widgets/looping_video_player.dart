import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class LoopingVideoPlayer extends StatefulWidget {
  final String videoPath;

  const LoopingVideoPlayer({Key? key, required this.videoPath})
      : super(key: key);

  @override
  State<LoopingVideoPlayer> createState() => _LoopingVideoPlayerState();
}

class _LoopingVideoPlayerState extends State<LoopingVideoPlayer> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.asset(widget.videoPath)
      ..setLooping(true) // Configura o loop infinito
      ..initialize().then((_) {
        _controller.play();
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose(); // Libera os recursos quando o widget é destruído
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: _controller.value.isInitialized
          ? AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            )
          : Center(child: CircularProgressIndicator()),
    );
  }
}
