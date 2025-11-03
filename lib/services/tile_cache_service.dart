import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'tile_cache_database.dart';

/// Serviço para gerenciar cache de tiles offline
class TileCacheService {
  static const String _osmUrlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  
  // Callbacks para progresso
  static Function(int current, int total, double percent)? onProgress;
  static Function(String message)? onStatus;
  
  /// Calcula quantos tiles são necessários para uma área
  static int calculateTileCount({
    required int zoomMin,
    required int zoomMax,
    required double latMin,
    required double latMax,
    required double lonMin,
    required double lonMax,
  }) {
    int total = 0;
    
    for (int z = zoomMin; z <= zoomMax; z++) {
      int xMin = _lonToTile(lonMin, z);
      int xMax = _lonToTile(lonMax, z);
      int yMin = _latToTile(latMax, z);
      int yMax = _latToTile(latMin, z);
      
      int tilesAtZoom = (xMax - xMin + 1) * (yMax - yMin + 1);
      total += tilesAtZoom;
    }
    
    return total;
  }

  /// Calcula espaço estimado em MB
  static double estimateSize({required int tileCount}) {
    // Média de 60KB por tile
    return (tileCount * 60) / 1024;
  }

  /// Inicia download de tiles em background
  static Future<void> downloadOfflineMap({
    required int zoomMin,
    required int zoomMax,
    required double latMin,
    required double latMax,
    required double lonMin,
    required double lonMax,
  }) async {
    try {
      final cacheDir = await _getCacheDirectory();
      int downloaded = 0;
      int total = calculateTileCount(
        zoomMin: zoomMin,
        zoomMax: zoomMax,
        latMin: latMin,
        latMax: latMax,
        lonMin: lonMin,
        lonMax: lonMax,
      );

      onStatus?.call('🔄 Iniciando download de $total tiles...');

      for (int z = zoomMin; z <= zoomMax; z++) {
        int xMin = _lonToTile(lonMin, z);
        int xMax = _lonToTile(lonMax, z);
        int yMin = _latToTile(latMax, z);
        int yMax = _latToTile(latMin, z);

        for (int x = xMin; x <= xMax; x++) {
          for (int y = yMin; y <= yMax; y++) {
            try {
              await _downloadTile(z, x, y, cacheDir);
              downloaded++;
              
              final percent = (downloaded / total * 100).toStringAsFixed(1);
              onProgress?.call(downloaded, total, downloaded / total);
              onStatus?.call('⬇️ $downloaded/$total tiles (${percent}%)');
            } catch (e) {
              print('Erro ao baixar tile z=$z x=$x y=$y: $e');
              // Continuar com próximo tile
            }
          }
        }
      }

      onStatus?.call('✅ Download concluído! $downloaded/$total tiles salvos');
    } catch (e) {
      onStatus?.call('❌ Erro no download: $e');
      rethrow;
    }
  }

  /// Download de um tile individual
  static Future<void> _downloadTile(int z, int x, int y, Directory cacheDir) async {
    final url = _osmUrlTemplate
        .replaceAll('{z}', '$z')
        .replaceAll('{x}', '$x')
        .replaceAll('{y}', '$y');

    final tileFile = File('${cacheDir.path}/$z/$x/$y.png');

    // Skip se já existe
    if (await tileFile.exists()) {
      return;
    }

    try {
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        // Criar diretórios se não existirem
        await tileFile.parent.create(recursive: true);
        // Salvar arquivo
        await tileFile.writeAsBytes(response.bodyBytes);
        
        // 🔑 IMPORTANTE: Registrar no banco de dados para o CachedTileProvider encontrar!
        await TileCacheDatabase.addCachedTile(
          z: z,
          x: x,
          y: y,
          filePath: tileFile.path,
          fileSize: response.bodyBytes.length,
        );
      }
    } catch (e) {
      print('Erro ao fazer request do tile: $e');
      rethrow;
    }
  }

  /// Obter diretório de cache
  /// ✅ Usa ApplicationSupportDirectory (mesmo que CachedTileProvider)
  static Future<Directory> _getCacheDirectory() async {
    final appDir = await getApplicationSupportDirectory();
    final cacheDir = Directory('${appDir.path}/tile_cache');
    
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    
    return cacheDir;
  }

  /// Converter longitude para X (tile)
  static int _lonToTile(double lon, int z) {
    return ((lon + 180.0) / 360.0 * (1 << z)).toInt();
  }

  /// Converter latitude para Y (tile)
  static int _latToTile(double lat, int z) {
    final latRad = lat * pi / 180.0;
    final sinLat = sin(latRad);
    final y2 = (1.0 - sinLat / (1.0 + sinLat)) / 2.0 * (1 << z);
    return y2.toInt();
  }

  /// Obter tamanho total do cache em bytes
  static Future<int> getCacheSize() async {
    try {
      final cacheDir = await _getCacheDirectory();
      return _getDirectorySize(cacheDir);
    } catch (e) {
      print('Erro ao calcular tamanho do cache: $e');
      return 0;
    }
  }

  /// Calcular tamanho de um diretório recursivamente
  static int _getDirectorySize(Directory dir) {
    int size = 0;
    try {
      final entities = dir.listSync(recursive: true);
      for (final entity in entities) {
        if (entity is File) {
          size += entity.lengthSync();
        }
      }
    } catch (e) {
      print('Erro ao calcular tamanho do diretório: $e');
    }
    return size;
  }

  /// Limpar cache
  static Future<void> clearCache() async {
    try {
      final cacheDir = await _getCacheDirectory();
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        onStatus?.call('✅ Cache limpo com sucesso');
      }
    } catch (e) {
      onStatus?.call('❌ Erro ao limpar cache: $e');
      rethrow;
    }
  }

  /// Formatar bytes para MB
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
