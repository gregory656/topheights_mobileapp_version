import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../app/top_heights_theme.dart';

class BrandIntro extends StatefulWidget {
  const BrandIntro({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<BrandIntro> createState() => _BrandIntroState();
}

class _BrandIntroState extends State<BrandIntro> {
  VideoPlayerController? _controller;
  Timer? _finishTimer;
  bool _ready = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    try {
      final controller = VideoPlayerController.asset(
        'assets/top_heights_intro.mp4',
      );
      _controller = controller;
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setPlaybackSpeed(2.0);
      await controller.play();
      if (!mounted) return;
      setState(() => _ready = true);
      _finishTimer = Timer(const Duration(seconds: 4), _finish);
    } catch (_) {
      if (!mounted) return;
      // Keep the intro surface video only; show a loading state if playback
      // cannot initialize instead of substituting the static logo image.
      _finishTimer = Timer(const Duration(seconds: 4), _finish);
    }
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    widget.onFinished();
  }

  @override
  void dispose() {
    _finishTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: BrandColors.forestDeep,
    body: Center(
      child: _ready && _controller != null
          ? SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller!.value.size.width,
                  height: _controller!.value.size.height,
                  child: VideoPlayer(_controller!),
                ),
              ),
            )
          : const CircularProgressIndicator(color: Colors.white70),
    ),
  );
}
