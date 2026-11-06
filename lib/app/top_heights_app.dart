import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Top Heights',
    debugShowCheckedModeBanner: false,
    theme: TopHeightsTheme.light,
    home: _introDone
        ? AppShell(profileRepository: _profileRepository)
        : BrandIntro(onFinished: () => setState(() => _introDone = true)),
  );
}
