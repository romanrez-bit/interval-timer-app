import 'package:flutter/material.dart';
import 'services/notification_service.dart';
import 'screens/setup_screen.dart';
import 'services/rest_recommendation_service.dart';
import 'services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  await RestRecommendationService.instance.init();
  await SettingsService.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Interval Timer',
      theme: ThemeData.dark(),
      home: const SetupScreen(),
    );
  }
}