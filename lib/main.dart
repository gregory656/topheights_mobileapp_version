import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'
    show databaseFactory, databaseFactoryFfi, sqfliteFfiInit;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart'
    show databaseFactoryFfiWebNoWebWorker;

import 'app/top_heights_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    // Phase 1 only performs small profile/settings queries, so the simpler
    // same-thread web factory avoids a generated shared-worker bundle.
    databaseFactory = databaseFactoryFfiWebNoWebWorker;
  } else if (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(const TopHeightsApp());
}
