import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';

Future<void> _startBackendIfNeeded() async {
  // No ambiente Web, não temos acesso a dart:io (HttpClient, Process).
  // O backend é gerenciado separadamente pelo servidor.
  if (kIsWeb) return;

  // Em modo Desktop, tenta iniciar o backend automaticamente.
  try {
    // Importação dinâmica não é possível no Flutter, então
    // esta função simplesmente não faz nada na Web.
    // Para desktop, a lógica original permanece no backend separado.
    return;
  } catch (e) {
    print('Backend check skipped: $e');
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
      title: 'Plano de Contratações Anual - ITPS',
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
