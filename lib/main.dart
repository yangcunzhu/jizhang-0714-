import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/home/presentation/home_page.dart';

void main() {
  runApp(const ProviderScope(child: AuditorApp()));
}

class AuditorApp extends StatelessWidget {
  const AuditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '审计官',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E5BFF)),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}