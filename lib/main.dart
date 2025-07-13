import 'package:flutter/material.dart';
import 'package:motouber/screens/home_screen.dart';
import 'package:motouber/services/database_service.dart';
import 'package:motouber/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.instance.init();
  runApp(const MotouberApp());
}

class MotouberApp extends StatelessWidget {
  const MotouberApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Motouber - Controle Financeiro',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}