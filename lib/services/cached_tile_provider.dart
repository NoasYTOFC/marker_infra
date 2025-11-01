import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'tile_cache_database.dart';

/// Provider de tiles customizado que usa cache inteligente + SQLite
/// Performance: ~1-5ms para tiles em cache (disk), ~100-200ms para network
/// 
/// Fluxo:
/// 1. Verifica se tile está em SQLite cache
/// 2. Se existe → carrega do arquivo local
/// 3. Se não existe → tenta network
/// 4. Se network OK → salva automaticamente (SmartTileCacheService cuida disso)
class CachedTileProvider extends TileProvider {
  static const String _osmUrlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  
  // Cache em memória para evitar muitas queries ao SQLite
  static final Map<String, String?> _memoryCache = {};
  static const int _maxMemoryCacheSize = 100;

  CachedTileProvider();

  /// Retorna URL do tile para flutter_map
  @override
  String getTileUrl(TileCoordinates coordinates, TileLayer layer) {
    return _osmUrlTemplate
        .replaceAll('{z}', coordinates.z.toString())
        .replaceAll('{x}', coordinates.x.toString())
        .replaceAll('{y}', coordinates.y.toString());
  }

  /// Fetch tile usando cache inteligente
  @override
  ImageProvider<Object> getImage(TileCoordinates coordinates, TileLayer layer) {
    return _CachedImage(coordinates.z, coordinates.x, coordinates.y);
  }
  
  /// Obtém caminho do tile em cache ou null
  static Future<String?> getCachedTilePath(int z, int x, int y) async {
    final cacheKey = '$z-$x-$y';
    
    // Verificar cache em memória primeiro
    if (_memoryCache.containsKey(cacheKey)) {
      return _memoryCache[cacheKey];
    }
    
    // Consultar banco de dados
    final path = await TileCacheDatabase.getTilePath(z, x, y);
    
    // Armazenar em memória
    if (_memoryCache.length >= _maxMemoryCacheSize) {
      _memoryCache.remove(_memoryCache.keys.first);
    }
    _memoryCache[cacheKey] = path;
    
    return path;
  }

  
  /// Limpar cache inteligente (SQLite)
  static Future<void> clearCache() async {
    try {
      debugPrint('🗑️ Limpando cache de tiles...');
      _memoryCache.clear();
      
      // Limpar até ficar sob limite de tamanho (vai triggerar limpeza LRU)
      await TileCacheDatabase.cleanUntilSizeLimit(maxSizeMb: 0);
      
      debugPrint('✅ Cache limpo');
    } catch (e) {
      debugPrint('❌ Erro ao limpar cache: $e');
    }
  }

  /// Obter estatísticas do cache
  static Future<Map<String, dynamic>> getCacheStats() async {
    return await TileCacheDatabase.getCacheStats();
  }

  /// Formatar bytes para leitura humana
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Image provider customizado que combina cache local + network
class _CachedImage extends ImageProvider<_CachedImage> {
  final int z;
  final int x;
  final int y;

  _CachedImage(this.z, this.x, this.y);

  @override
  Future<_CachedImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<_CachedImage>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    _CachedImage key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadImageAsync(decode),
      scale: 1.0,
      debugLabel: 'CachedTile($z,$x,$y)',
    );
  }

  /// Carrega imagem de cache ou network
  Future<ui.Codec> _loadImageAsync(ImageDecoderCallback decode) async {
    try {
      // 1️⃣ Verificar cache SQLite primeiro
      final cachedPath = await CachedTileProvider.getCachedTilePath(z, x, y);
      
      if (cachedPath != null && await File(cachedPath).exists()) {
        debugPrint('💾 Tile do cache: z=$z x=$x y=$y');
        final bytes = await File(cachedPath).readAsBytes();
        return decode(
          await ui.ImmutableBuffer.fromUint8List(bytes),
        );
      }
      
      // 2️⃣ Se não tiver em cache, carregar do network
      final url = 'https://tile.openstreetmap.org/$z/$x/$y.png';
      debugPrint('🌐 Tile da rede: z=$z x=$x y=$y');
      
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );
      
      if (response.statusCode == 200) {
        // ℹ️ SmartTileCacheService vai cuidar de salvar automaticamente
        // Este provider só consome, não salva
        return decode(
          await ui.ImmutableBuffer.fromUint8List(response.bodyBytes),
        );
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
      
    } catch (e) {
      debugPrint('❌ Erro ao carregar tile z=$z x=$x y=$y: $e');
      
      // Retornar imagem vazia em caso de erro
      return _getErrorImage();
    }
  }

  /// Gera imagem vazia para erro
  Future<ui.Codec> _getErrorImage() async {
    final picoder = ui.PictureRecorder();
    final canvas = Canvas(picoder);
    
    // Desenhar fundo cinza escuro
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 256, 256),
      Paint()..color = const Color.fromARGB(255, 64, 64, 64),
    );
    
    // Desenhar X
    canvas.drawLine(
      const Offset(0, 0),
      const Offset(256, 256),
      Paint()
        ..color = Colors.red
        ..strokeWidth = 4,
    );
    canvas.drawLine(
      const Offset(256, 0),
      const Offset(0, 256),
      Paint()
        ..color = Colors.red
        ..strokeWidth = 4,
    );
    
    final picture = picoder.endRecording();
    final image = await picture.toImage(256, 256);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    
    return ui.instantiateImageCodec(bytes!.buffer.asUint8List());
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _CachedImage &&
          runtimeType == other.runtimeType &&
          z == other.z &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => Object.hash(z, x, y);
}