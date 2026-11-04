import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:sqflite/sqflite.dart';
import '../../app/top_heights_theme.dart';
import '../../data/local_database.dart';

class BrandIntro extends StatefulWidget {
  const BrandIntro({super.key, required this.onFinished});
  final VoidCallback onFinished;
  @override State<BrandIntro> createState() => _BrandIntroState();
}

class _BrandIntroState extends State<BrandIntro> {
  VideoPlayerController? _controller;
  bool _ready = false, _finished = false;
  @override void initState() { super.initState(); _prepare(); }
  Future<void> _prepare() async {
    try {
      final controller = VideoPlayerController.asset('assets/Top Heights Logo IntroPortrait.mp4');
      _controller = controller;
      await controller.initialize();
      await controller.setLooping(false);
      controller.addListener(() { if (mounted && controller.value.isInitialized && !controller.value.isPlaying && controller.value.position >= controller.value.duration && !_finished) _finish(); });
      await controller.play();
      if (mounted) setState(() => _ready = true);
    } catch (_) { if (mounted) setState(() => _ready = false); }
  }
  Future<void> _finish() async {
    if (_finished) return; _finished = true;
    final db = await LocalDatabase.instance.database;
    await db.insert('app_settings', {'setting_key': 'brand_intro_seen', 'setting_value': 'true', 'updated_at': DateTime.now().toUtc().toIso8601String()}, conflictAlgorithm: ConflictAlgorithm.replace);
    if (mounted) widget.onFinished();
  }
  @override void dispose() { _controller?.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Scaffold(backgroundColor: BrandColors.forestDeep, body: Stack(fit: StackFit.expand, children: [if (_ready && _controller != null) Center(child: AspectRatio(aspectRatio: _controller!.value.aspectRatio, child: VideoPlayer(_controller!))) else Center(child: Image.asset('assets/TopHeightsTransparent.png', width: 250, fit: BoxFit.contain)), Positioned(left: 22, right: 22, bottom: 28, child: Row(children: [const Expanded(child: Text('TOP HEIGHTS · POWERING WHAT MATTERS', style: TextStyle(color: Colors.white70, letterSpacing: 1.2, fontSize: 10, fontWeight: FontWeight.w700))), TextButton(onPressed: _finish, child: const Text('Skip intro', style: TextStyle(color: Colors.white)))]))]));
}
