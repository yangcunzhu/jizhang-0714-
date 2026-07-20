import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/home/presentation/home_page.dart';

void main() {
  // 锁定中文 locale,DatePicker / BottomSheet 等 Material widget 默认渲染中文。
  // D22 修复:之前未配,导致 iOS 日期选择器显示英文(截图 244)。
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
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
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      locale: const Locale('zh', 'CN'),
      home: const HomePage(),
    );
  }
}