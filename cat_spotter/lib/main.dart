import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme.dart';
import 'screens/home/home_screen.dart';
import 'widgets/achievement_popup.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: CatSpotterApp(),
    ),
  );
}

final _navigatorKey = GlobalKey<NavigatorState>();

class CatSpotterApp extends StatelessWidget {
  const CatSpotterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cat Spotter',
      theme: AppTheme.lightTheme,
      navigatorKey: _navigatorKey,
      builder: (context, child) => AchievementListener(
        navigatorKey: _navigatorKey,
        child: child!,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
