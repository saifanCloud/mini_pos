import 'package:flutter/material.dart';
import 'features/cashier/presentation/home_screen.dart';

/// Root aplikasi — MaterialApp dengan tema Material 3.
/// Routing dan tema akan diperluas seiring tahapan berikutnya.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mini POS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1976D2), // biru utama
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

