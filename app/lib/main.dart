import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';

Future<void> _startBackendIfNeeded() async {
  try {
    final client = HttpClient();
    client.connectionTimeout = const Duration(milliseconds: 500);
    final request = await client.getUrl(Uri.parse('http://localhost:8000/api/pca/config'));
    final response = await request.close();
    if (response.statusCode == 200) {
      print('Backend já está ativo na porta 8000.');
      return;
    }
  } catch (_) {
    try {
      await Process.start(
        'c:\\Users\\gnsilva\\BACKEND-ITPS-SITE\\venv\\Scripts\\python.exe',
        ['c:\\Users\\gnsilva\\pca\\backend\\main.py'],
        mode: ProcessStartMode.detached,
      );
      print('Servidor backend inicializado de forma silenciosa e em background!');
      // Espera um instante curto para que o servidor inicie antes do primeiro request do app
      await Future.delayed(const Duration(milliseconds: 800));
    } catch (e) {
      print('Erro ao iniciar backend automaticamente: $e');
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _startBackendIfNeeded();
  runApp(const PCAApp());
}

class PCAApp extends StatelessWidget {
  const PCAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PCA 2027 — ITPS',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0F19),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3B82F6),
          secondary: Color(0xFF10B981),
          surface: Color(0xFF131A2C),
        ),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.dark().textTheme,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF131A2C),
          elevation: 0,
          titleTextStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
