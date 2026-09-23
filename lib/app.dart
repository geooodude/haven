import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:havennyc/core/constants/app_flavor.dart';

/// Root application widget. Firebase wiring is added in P0-002.
class HavenApp extends ConsumerWidget {
  const HavenApp({required this.flavor, super.key});

  final AppFlavor flavor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: flavor.displayName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(title: Text(flavor.displayName)),
        body: Center(
          child: Text(
            '${flavor.name} flavor',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
      ),
    );
  }
}
