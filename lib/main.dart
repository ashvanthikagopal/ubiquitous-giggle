import 'package:flutter/material.dart';
import 'screens/splash/splash_screen.dart';

void main() {
  runApp(const MakkalConnectAdmin());
}

class MakkalConnectAdmin extends StatelessWidget {
  const MakkalConnectAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Makkal Connect Admin',
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFFFF5A66),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF5A66),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}