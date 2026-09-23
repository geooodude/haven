import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:havennyc/app.dart';
import 'package:havennyc/core/constants/app_flavor.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Production flavor is defined but not yet wired to live Firebase (see P0-002).
  runApp(
    const ProviderScope(
      child: HavenApp(flavor: AppFlavor.production),
    ),
  );
}
