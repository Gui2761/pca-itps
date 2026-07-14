import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';

import 'package:flutter/foundation.dart';

Future<void> _startBackendIfNeeded() async {
  if (kIsWeb) return; // Web cannot start the local backend
  try {
    // Verifica se o backend já está rodando
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 2);
    final request = await client.getUrl(Uri.parse('http://localhost:8000/docs'));
    final response = await request.close();
    client.close();
    if (response.statusCode == 200) {
      print('Backend já está rodando.');
      return;
    }
  } catch (_) {
    // Backend não está rodando, iniciar
    print('Iniciando servidor backend...');
    try {
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      // Procura backend.exe na pasta backend/ ao lado do app
      final backendExe = File('$exeDir\\backend\\backend.exe');
      final backendPy = File('$exeDir\\..\\..\\backend\\main.py');
      
      if (await backendExe.exists()) {
        await Process.start(
          backendExe.path, [],
          mode: ProcessStartMode.detached,
          workingDirectory: backendExe.parent.path,
        );
        print('Backend.exe iniciado com sucesso.');
      } else if (await backendPy.exists()) {
        await Process.start(
          'python', [backendPy.path],
          mode: ProcessStartMode.detached,
          workingDirectory: backendPy.parent.path,
        );
        print('Backend iniciado via python.');
      }
      // Aguarda o backend ficar pronto
      await Future.delayed(const Duration(seconds: 3));
    } catch (e) {
      print('Não foi possível iniciar o backend: $e');
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
