import 'package:flutter/material.dart';

import '../data/local_database.dart';
import '../data/profile_repository.dart';
import '../features/shell/app_shell.dart';
import '../features/shell/brand_intro.dart';
import 'top_heights_theme.dart';

class TopHeightsApp extends StatefulWidget {
  const TopHeightsApp({super.key});
  @override
  State<TopHeightsApp> createState() => _TopHeightsAppState();
}

class _TopHeightsAppState extends State<TopHeightsApp> {
  late final ProfileRepository _profileRepository = ProfileRepository();
  bool _introDone = false;
  Future<bool> _shouldShowIntro() async {
    final db = await LocalDatabase.instance.database;
    final rows = await db.query('app_settings', where: 'setting_key = ?', whereArgs: ['brand_intro_seen']);
    return rows.isEmpty;
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Top Heights',
    debugShowCheckedModeBanner: false,
    theme: TopHeightsTheme.light,
    home: FutureBuilder<bool>(
      future: _shouldShowIntro(),
      builder: (context, snapshot) {
        if (snapshot.data == true && !_introDone) return BrandIntro(onFinished: () => setState(() => _introDone = true));
        if (!snapshot.hasData && !_introDone) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        return AppShell(profileRepository: _profileRepository);
      },
    ),
  );
}
