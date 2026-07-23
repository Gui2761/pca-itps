import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';

class UpdateService {
  static const String repoOwner = 'Gui2761';
  static const String repoName = 'pca-itps';

  /// Retorna os detalhes da última versão se houver uma nova disponível.
  /// Retorna null se já estiver na versão mais recente.
  static Future<Map<String, dynamic>?> checkForUpdate() async {
    if (!kIsWeb && Platform.isWindows) {
      try {
        final packageInfo = await PackageInfo.fromPlatform();
        String currentVersion = packageInfo.version; 
        
        final response = await http.get(Uri.parse('https://api.github.com/repos/$repoOwner/$repoName/releases/latest'));
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          String latestTag = data['tag_name'] ?? '';
          
          if (latestTag.isNotEmpty) {
            String latestVersion = latestTag.replaceAll('v', '');
            if (_isNewerVersion(currentVersion, latestVersion)) {
              return data;
            }
          }
        }
      } catch (e) {
        debugPrint('Erro ao checar atualizações: $e');
      }
    }
    return null;
  }

  /// Baixa a atualização, extrai e executa o instalador mágico.
  static Future<void> downloadAndInstallUpdate(String downloadUrl) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final updateZipPath = '${tempDir.path}\\pca_update.zip';
      final extractDir = '${tempDir.path}\\pca_extracted';

      // 1. Download do zip
      final response = await http.get(Uri.parse(downloadUrl));
      if (response.statusCode == 200) {
        final file = File(updateZipPath);
        await file.writeAsBytes(response.bodyBytes);

        // 2. Extrair o zip
        final dir = Directory(extractDir);
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
        await dir.create();
        
        final bytes = file.readAsBytesSync();
        final archive = ZipDecoder().decodeBytes(bytes);
        
        for (final archiveFile in archive) {
          final filename = archiveFile.name;
          if (archiveFile.isFile) {
            final data = archiveFile.content as List<int>;
            File('${dir.path}\\$filename')
              ..createSync(recursive: true)
              ..writeAsBytesSync(data);
          } else {
            Directory('${dir.path}\\$filename').createSync(recursive: true);
          }
        }

        // 3. Criar script BAT para substituir arquivos
        final currentAppDir = File(Platform.resolvedExecutable).parent.path;
        final currentExePath = Platform.resolvedExecutable;
        
        final batPath = '${tempDir.path}\\update_pca.bat';
        final batContent = '''
@echo off
echo Aguardando o PCA fechar...
timeout /t 3 /nobreak > nul
echo Atualizando arquivos...
xcopy /s /y /q "$extractDir\\*" "$currentAppDir\\"
echo Reabrindo o PCA...
start "" "$currentExePath"
echo Limpando temporários...
rmdir /s /q "$extractDir"
del "$updateZipPath"
(goto) 2>nul & del "%~f0"
''';
        
        final batFile = File(batPath);
        await batFile.writeAsString(batContent);

        // 4. Executar script em modo desanexado e sair
        await Process.start('cmd', ['/c', batPath], mode: ProcessStartMode.detached);
        exit(0);
      }
    } catch (e) {
      debugPrint('Erro ao instalar atualização: $e');
    }
  }

  static bool _isNewerVersion(String current, String latest) {
    try {
      List<int> cParts = current.split('.').map(int.parse).toList();
      List<int> lParts = latest.split('.').map(int.parse).toList();
      
      for (int i = 0; i < 3; i++) {
        int c = i < cParts.length ? cParts[i] : 0;
        int l = i < lParts.length ? lParts[i] : 0;
        if (l > c) return true;
        if (l < c) return false;
      }
    } catch (e) {
      return false;
    }
    return false;
  }
}
