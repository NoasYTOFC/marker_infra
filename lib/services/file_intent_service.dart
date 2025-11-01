import 'package:flutter/services.dart';
import 'dart:io';

class FileIntentService {
  static const platform = MethodChannel('com.example.marker_infra/files');

  /// Obtém o arquivo compartilhado quando o app é aberto via intent
  static Future<File?> getSharedFile() async {
    try {
      print('🔌 FileIntentService: Chamando método nativo getSharedFile...');
      final String? filePath = await platform.invokeMethod<String?>('getSharedFile');
      print('📱 Resposta nativa: $filePath');
      
      if (filePath != null && filePath.isNotEmpty) {
        // Se for uma URI, converter para caminho real
        final actualPath = _convertUriToPath(filePath);
        print('🔄 Caminho convertido: $actualPath');
        final file = File(actualPath);
        
        final exists = await file.exists();
        print('📁 Arquivo existe? $exists');
        
        if (exists) {
          print('✅ Retornando arquivo: ${file.path}');
          return file;
        } else {
          print('❌ Arquivo não encontrado: $actualPath');
        }
      } else {
        print('❌ FilePath vazio ou null');
      }
      return null;
    } catch (e) {
      print('❌ Erro ao obter arquivo compartilhado: $e');
      return null;
    }
  }

  /// Converte uma URI Android para um caminho de arquivo
  static String _convertUriToPath(String uri) {
    if (uri.startsWith('content://')) {
      // URI content provider - tentar extrair o caminho
      return uri.replaceAll('content://', '');
    } else if (uri.startsWith('file://')) {
      return uri.replaceAll('file://', '');
    } else {
      return uri;
    }
  }

  /// Verifica se é um arquivo KML ou KMZ
  static bool isValidKmlFile(String? filePath) {
    if (filePath == null) return false;
    return filePath.toLowerCase().endsWith('.kml') || 
           filePath.toLowerCase().endsWith('.kmz');
  }
}
