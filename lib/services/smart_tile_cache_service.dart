import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'tile_cache_database.dart';

/// Serviço inteligente de cache de tiles baseado em localização de elementos
class SmartTileCacheService {
  static const String _osmUrlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const double _defaultRadiusKm = 5.0; // Raio padrão: 5km ao redor de elementos (expandido com pyramid caching)
  static const int _defaultZoomLevel = 17; // Zoom padrão para cache
  
  // Pyramid Caching: zoom 14 em grande área (visão macro), zooms 15-17 em raio normal
  static const double _pyramidRadiusKm = 20.0; // Raio para zoom 14 de baixa resolução
  
  // Callbacks para progresso
  static Function(int current, int total, double percent)? onProgress;
  static Function(String message)? onStatus;
  
  // Controladores de limite
  static const int maxCacheSizeMb = 800; // Máximo 800MB
  static const int cleanOldTilesDays = 30; // Limpar tiles com mais de 30 dias
  
  /// Inicia cache automático para um elemento
  static Future<void> initCacheForElement({
    required String elementoId,
    required String elementoTipo,
    required LatLng posicao,
    double radiusKm = _defaultRadiusKm,
    int zoomLevel = _defaultZoomLevel,
  }) async {
    try {
      onStatus?.call('🔍 Preparando cache para $elementoTipo: $elementoId');
      
      // Registrar área de cache no banco
      await TileCacheDatabase.addCacheArea(
        elementoId: elementoId,
        elementoTipo: elementoTipo,
        latitude: posicao.latitude,
        longitude: posicao.longitude,
        radiusKm: radiusKm,
      );
      
      // Calcular bounds uma vez
      final bounds = _calculateBounds(posicao, radiusKm);
      
      // Pyramid Caching: Zoom 14 em grande área + Zooms 15-17 em raio normal
      final pyramidBounds = _calculateBounds(posicao, _pyramidRadiusKm);
      
      // Zoom 14: visão macro em grande raio (economiza espaço, ~100 tiles)
      // Zooms 15-17: detalhe completo em raio padrão
      int totalTilesToDownload = 0;
      
      // Calcular zoom 14 em grande área
      final zoom14Count = _calculateTileCount(
        14,
        pyramidBounds['latMin']!,
        pyramidBounds['latMax']!,
        pyramidBounds['lonMin']!,
        pyramidBounds['lonMax']!,
      );
      totalTilesToDownload += zoom14Count;
      
      // Calcular zooms 15-17 em raio normal
      for (int zoom in [15, 16, 17]) {
        final tileCount = _calculateTileCount(
          zoom,
          bounds['latMin']!,
          bounds['latMax']!,
          bounds['lonMin']!,
          bounds['lonMax']!,
        );
        totalTilesToDownload += tileCount;
      }
      
      onStatus?.call('📊 ~$totalTilesToDownload tiles para cache em 4 zooms (${(totalTilesToDownload * 60 / 1024).toStringAsFixed(2)}MB estimado)');
      
      // Iniciar download em background para todos os zooms
      // Zoom 14 em grande raio (pyramid caching)
      _downloadTilesForArea(
        elementoId: elementoId,
        bounds: pyramidBounds,
        zoomLevel: 14,
        totalTiles: zoom14Count,
      );
      
      // Zooms 15-17 em raio normal
      for (int zoom in [15, 16, 17]) {
        _downloadTilesForArea(
          elementoId: elementoId,
          bounds: bounds,
          zoomLevel: zoom,
          totalTiles: _calculateTileCount(
            zoom,
            bounds['latMin']!,
            bounds['latMax']!,
            bounds['lonMin']!,
            bounds['lonMax']!,
          ),
        );
      }
      
    } catch (e) {
      onStatus?.call('❌ Erro ao preparar cache: $e');
      debugPrint('Erro ao inicializar cache: $e');
    }
  }
  
  /// Remove cache de um elemento deletado
  static Future<void> removeCacheForElement(String elementoId) async {
    try {
      onStatus?.call('🗑️ Removendo cache para: $elementoId');
      
      // Remover área do banco
      await TileCacheDatabase.removeCacheArea(elementoId);
      
      // Verificar se há outros elementos próximos
      // Se não houver, tiles podem ser marcados para limpeza
      
      onStatus?.call('✅ Cache removido');
    } catch (e) {
      onStatus?.call('❌ Erro ao remover cache: $e');
      debugPrint('Erro ao remover cache: $e');
    }
  }
  
  /// Obtém caminho do arquivo de um tile (ou null se não está em cache)
  static Future<String?> getTilePath(int z, int x, int y) async {
    // Primeiro verificar se está em cache
    final path = await TileCacheDatabase.getTilePath(z, x, y);
    if (path != null && File(path).existsSync()) {
      return path;
    }
    
    // Se não existe, remover do banco
    if (path != null) {
      debugPrint('⚠️ Arquivo de tile não encontrado, removendo registro');
    }
    
    return null;
  }
  
  /// Obtém estatísticas do cache
  static Future<Map<String, dynamic>> getCacheStats() async {
    return await TileCacheDatabase.getCacheStats();
  }
  
  /// Limpa cache manualmente
  static Future<void> cleanCache() async {
    try {
      onStatus?.call('🧹 Limpando cache...');
      
      // Limpar tiles antigos
      await TileCacheDatabase.cleanOldTiles(daysOld: cleanOldTilesDays);
      
      // Limpar até atingir limite de tamanho
      await TileCacheDatabase.cleanUntilSizeLimit(maxSizeMb: maxCacheSizeMb);
      
      onStatus?.call('✅ Cache limpo');
    } catch (e) {
      onStatus?.call('❌ Erro ao limpar cache: $e');
      debugPrint('Erro ao limpar cache: $e');
    }
  }
  
  // ==================== PRIVADOS ====================
  
  /// Calcula bounds (latitude/longitude) a partir de uma posição e raio
  static Map<String, double> _calculateBounds(LatLng center, double radiusKm) {
    // 1 grau de latitude ≈ 111 km
    final latOffset = radiusKm / 111;
    // 1 grau de longitude ≈ 111 km * cos(latitude)
    final lonOffset = radiusKm / (111 * cos(center.latitude * pi / 180));
    
    return {
      'latMin': center.latitude - latOffset,
      'latMax': center.latitude + latOffset,
      'lonMin': center.longitude - lonOffset,
      'lonMax': center.longitude + lonOffset,
    };
  }
  
  /// Calcula quantos tiles são necessários
  static int _calculateTileCount(
    int zoom,
    double latMin,
    double latMax,
    double lonMin,
    double lonMax,
  ) {
    int xMin = _lonToTile(lonMin, zoom);
    int xMax = _lonToTile(lonMax, zoom);
    int yMin = _latToTile(latMax, zoom);
    int yMax = _latToTile(latMin, zoom);
    
    return (xMax - xMin + 1) * (yMax - yMin + 1);
  }
  
  /// Download assíncrono de tiles para uma área
  static void _downloadTilesForArea({
    required String elementoId,
    required Map<String, double> bounds,
    required int zoomLevel,
    required int totalTiles,
  }) {
    // Executar em background sem bloquear UI
    _downloadTilesAsync(
      elementoId: elementoId,
      bounds: bounds,
      zoomLevel: zoomLevel,
      totalTiles: totalTiles,
    );
  }
  
  /// Função assíncrona para download (sem await na chamada)
  static Future<void> _downloadTilesAsync({
    required String elementoId,
    required Map<String, double> bounds,
    required int zoomLevel,
    required int totalTiles,
  }) async {
    try {
      final cacheDir = await _getCacheDirectory();
      int downloaded = 0;
      int skipped = 0;
      
      final xMin = _lonToTile(bounds['lonMin']!, zoomLevel);
      final xMax = _lonToTile(bounds['lonMax']!, zoomLevel);
      final yMin = _latToTile(bounds['latMax']!, zoomLevel);
      final yMax = _latToTile(bounds['latMin']!, zoomLevel);
      
      onStatus?.call('⬇️ Iniciando download inteligente de tiles...');
      
      for (int x = xMin; x <= xMax; x++) {
        for (int y = yMin; y <= yMax; y++) {
          try {
            // Verificar se já está em cache
            final isCached = await TileCacheDatabase.isTileCached(zoomLevel, x, y);
            
            if (isCached) {
              skipped++;
            } else {
              // Fazer download do tile
              await _downloadAndCacheTile(
                z: zoomLevel,
                x: x,
                y: y,
                cacheDir: cacheDir,
              );
              downloaded++;
            }
            
            final total = downloaded + skipped;
            final percent = (total / totalTiles * 100).toStringAsFixed(1);
            
            onProgress?.call(total, totalTiles, total / totalTiles);
            onStatus?.call('⬇️ $total/$totalTiles ($skipped reutilizados) - ${percent}%');
            
            // Verificar limite de tamanho apenas a cada 200 tiles (menos operações)
            if ((downloaded + skipped) % 200 == 0) {
              await TileCacheDatabase.cleanUntilSizeLimit(maxSizeMb: maxCacheSizeMb);
            }
            
          } catch (e) {
            debugPrint('⚠️ Erro ao baixar tile z=$zoomLevel x=$x y=$y: $e');
            // Continuar com próximo
          }
        }
      }
      
      // Atualizar count de tiles
      await TileCacheDatabase.updateTileCount(elementoId, downloaded + skipped);
      
      // Fazer limpeza final após download completo
      await TileCacheDatabase.cleanUntilSizeLimit(maxSizeMb: maxCacheSizeMb);
      
      onStatus?.call('✅ Cache completo! $downloaded novos + $skipped reutilizados');
      debugPrint('✅ Cache para $elementoId: $downloaded novos tiles + $skipped reutilizados');
      
    } catch (e) {
      onStatus?.call('❌ Erro no download: $e');
      debugPrint('Erro no download de tiles: $e');
    }
  }
  
  /// Download e cache de um tile individual com retry logic
  static Future<void> _downloadAndCacheTile({
    required int z,
    required int x,
    required int y,
    required Directory cacheDir,
    int retries = 3,
  }) async {
    final url = _osmUrlTemplate
        .replaceAll('{z}', z.toString())
        .replaceAll('{x}', x.toString())
        .replaceAll('{y}', y.toString());
    
    http.Response? response;
    dynamic lastError;
    
    // Retry logic com backoff exponencial
    for (int attempt = 0; attempt < retries; attempt++) {
      try {
        response = await http.get(Uri.parse(url)).timeout(
          const Duration(seconds: 10),
        );
        
        if (response.statusCode == 200) {
          // Criar estrutura de diretórios
          final tilePath = '${cacheDir.path}/$z/$x/$y.png';
          final tileFile = File(tilePath);
          
          // Criar diretórios se não existem
          await tileFile.parent.create(recursive: true);
          
          // Salvar arquivo
          await tileFile.writeAsBytes(response.bodyBytes);
          
          // Registrar no banco de dados
          await TileCacheDatabase.addCachedTile(
            z: z,
            x: x,
            y: y,
            filePath: tilePath,
            fileSize: response.contentLength ?? response.bodyBytes.length,
          );
          
          return; // Sucesso!
        } else if (response.statusCode == 404) {
          // Tile não existe no servidor, não tentar retry
          debugPrint('⚠️ Tile 404 (não existe): z=$z x=$x y=$y');
          return;
        } else if (response.statusCode >= 500) {
          // Erro de servidor, tentar retry
          lastError = 'HTTP ${response.statusCode}';
          if (attempt < retries - 1) {
            await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
          }
        } else {
          // Erro cliente, não tentar retry
          debugPrint('⚠️ HTTP ${response.statusCode} ao baixar tile z=$z x=$x y=$y');
          return;
        }
        
      } on SocketException catch (e) {
        lastError = 'SocketException: ${e.message}';
        debugPrint('⚠️ SocketException em z=$z x=$x y=$y (tentativa ${attempt + 1}/$retries): $e');
        
        if (attempt < retries - 1) {
          // Backoff exponencial: 500ms, 1s, 2s
          await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
        }
        
      } catch (e) {
        lastError = e.toString();
        if (attempt < retries - 1) {
          // Verificar se é erro de rede retentável
          if (e.toString().contains('ClientException') ||
              e.toString().contains('TimeoutException')) {
            debugPrint('⚠️ Erro retentável em z=$z x=$x y=$y (tentativa ${attempt + 1}/$retries): $e');
            await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
          } else {
            debugPrint('⚠️ Erro não retentável ao baixar tile z=$z x=$x y=$y: $e');
            return;
          }
        } else {
          debugPrint('⚠️ Erro não retentável ao baixar tile z=$z x=$x y=$y: $e');
          return;
        }
      }
    }
    
    // Todas as tentativas falharam
    debugPrint('❌ Falhou após $retries tentativas para z=$z x=$x y=$y: $lastError');
  }
  
  /// Obtém diretório de cache
  static Future<Directory> _getCacheDirectory() async {
    final appDir = await getApplicationSupportDirectory();
    final cacheDir = Directory('${appDir.path}/tile_cache');
    
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    
    return cacheDir;
  }
  
  // ==================== TILE MATH ====================
  
  static int _latToTile(double lat, int zoom) {
    final n = pow(2.0, zoom).toInt();
    final latRad = lat * pi / 180.0;
    return ((n / 2.0) - (n / (2.0 * pi) * log(tan((pi / 4.0) + (latRad / 2.0))))).toInt();
  }
  
  static int _lonToTile(double lon, int zoom) {
    final n = pow(2.0, zoom).toInt();
    return ((lon + 180.0) / 360.0 * n).toInt();
  }
}
