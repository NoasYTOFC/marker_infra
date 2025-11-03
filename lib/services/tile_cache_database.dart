import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:math';
import 'dart:async';

/// Serviço de persistência de cache inteligente usando SQLite
class TileCacheDatabase {
  static const String _dbName = 'tile_cache.db';
  static const int _dbVersion = 1;
  
  // Nomes das tabelas
  static const String _tableCachedTiles = 'cached_tiles';
  static const String _tableCacheAreas = 'cache_areas';
  
  static Database? _database;
  
  // 🔒 Mutex para evitar contenção no SQLite
  static final _databaseLock = Semaphore(1);
  
  /// Obtém instância do banco de dados
  static Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }
  
  /// Inicializa o banco de dados
  static Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _dbName);
    
    // Deletar banco anterior para testes (remover em produção)
    await deleteDatabase(path);
    
    debugPrint('📦 Inicializando banco de dados de cache em: $path');
    
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createTables,
      onUpgrade: _upgradeTables,
    );
  }
  
  /// Cria as tabelas do banco
  static Future<void> _createTables(Database db, int version) async {
    debugPrint('🔨 Criando tabelas de cache...');
    
    // Tabela de áreas de cache
    await db.execute('''
      CREATE TABLE $_tableCacheAreas (
        id TEXT PRIMARY KEY,
        elemento_id TEXT NOT NULL,
        elemento_tipo TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        radius_km REAL NOT NULL,
        criado_em INTEGER NOT NULL,
        atualizado_em INTEGER NOT NULL,
        tiles_count INTEGER DEFAULT 0
      )
    ''');
    
    // Índices para busca rápida
    await db.execute(
      'CREATE INDEX idx_elemento_id ON $_tableCacheAreas(elemento_id)'
    );
    await db.execute(
      'CREATE INDEX idx_elemento_tipo ON $_tableCacheAreas(elemento_tipo)'
    );
    
    // Tabela de tiles em cache
    await db.execute('''
      CREATE TABLE $_tableCachedTiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        z INTEGER NOT NULL,
        x INTEGER NOT NULL,
        y INTEGER NOT NULL,
        tile_hash TEXT,
        file_path TEXT NOT NULL,
        file_size INTEGER NOT NULL,
        criado_em INTEGER NOT NULL,
        acessado_em INTEGER NOT NULL
      )
    ''');
    
    // Índices para busca rápida
    await db.execute(
      'CREATE UNIQUE INDEX idx_z_x_y ON $_tableCachedTiles(z, x, y)'
    );
    await db.execute(
      'CREATE INDEX idx_tile_hash ON $_tableCachedTiles(tile_hash)'
    );
    
    debugPrint('✅ Tabelas criadas com sucesso');
  }
  
  /// Upgrade do banco de dados
  static Future<void> _upgradeTables(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    debugPrint('🔄 Atualizando banco de dados de v$oldVersion para v$newVersion');
    // Futuras migrações aqui
  }
  
  // ==================== OPERAÇÕES DE CACHE AREAS ====================
  
  /// Registra uma nova área de cache para um elemento
  static Future<void> addCacheArea({
    required String elementoId,
    required String elementoTipo,
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final areaId = '$elementoId-cache-area';
    
    debugPrint('📍 Adicionando área de cache: $elementoId ($elementoTipo) - raio: ${radiusKm}km');
    
    await db.insert(
      _tableCacheAreas,
      {
        'id': areaId,
        'elemento_id': elementoId,
        'elemento_tipo': elementoTipo,
        'latitude': latitude,
        'longitude': longitude,
        'radius_km': radiusKm,
        'criado_em': now,
        'atualizado_em': now,
        'tiles_count': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    debugPrint('✅ Área de cache registrada');
  }
  
  /// Obtém todas as áreas de cache
  static Future<List<Map<String, dynamic>>> getAllCacheAreas() async {
    final db = await database;
    final areas = await db.query(_tableCacheAreas);
    return areas;
  }
  
  /// Obtém áreas próximas (dentro de X km de um ponto)
  static Future<List<Map<String, dynamic>>> getNearbyAreas({
    required double latitude,
    required double longitude,
    required double maxDistanceKm,
  }) async {
    final db = await database;
    
    // Aproximação simples: diferença de 1 grau ≈ 111 km
    final latOffset = maxDistanceKm / 111;
    final lonOffset = maxDistanceKm / (111 * cos(latitude * pi / 180));
    
    final areas = await db.query(
      _tableCacheAreas,
      where: '''
        latitude BETWEEN ? AND ? 
        AND longitude BETWEEN ? AND ?
      ''',
      whereArgs: [
        latitude - latOffset,
        latitude + latOffset,
        longitude - lonOffset,
        longitude + lonOffset,
      ],
    );
    
    return areas;
  }
  
  /// Remove uma área de cache (e seus tiles associados)
  static Future<void> removeCacheArea(String elementoId) async {
    final db = await database;
    final areaId = '$elementoId-cache-area';
    
    debugPrint('🗑️ Removendo área de cache: $elementoId');
    
    await db.delete(
      _tableCacheAreas,
      where: 'id = ?',
      whereArgs: [areaId],
    );
    
    debugPrint('✅ Área removida');
  }
  
  /// Atualiza o count de tiles em uma área
  static Future<void> updateTileCount(String elementoId, int count) async {
    final db = await database;
    final areaId = '$elementoId-cache-area';
    
    await db.update(
      _tableCacheAreas,
      {
        'tiles_count': count,
        'atualizado_em': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [areaId],
    );
  }
  
  // ==================== OPERAÇÕES DE CACHED TILES ====================
  
  /// Registra um tile em cache
  static Future<void> addCachedTile({
    required int z,
    required int x,
    required int y,
    required String filePath,
    required int fileSize,
  }) async {
    await _databaseLock.acquire();
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;
      final tileHash = _generateTileHash(z, x, y);
      
      await db.insert(
        _tableCachedTiles,
        {
          'z': z,
          'x': x,
          'y': y,
          'tile_hash': tileHash,
          'file_path': filePath,
          'file_size': fileSize,
          'criado_em': now,
          'acessado_em': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore, // Ignora se já existe
      );
    } finally {
      _databaseLock.release();
    }
  }
  
  /// Verifica se um tile já está em cache
  static Future<bool> isTileCached(int z, int x, int y) async {
    await _databaseLock.acquire();
    try {
      final db = await database;
      final tileHash = _generateTileHash(z, x, y);
      
      final result = await db.query(
        _tableCachedTiles,
        where: 'tile_hash = ?',
        whereArgs: [tileHash],
        limit: 1,
      );
      
      return result.isNotEmpty;
    } finally {
      _databaseLock.release();
    }
  }
  
  /// Obtém o caminho do arquivo de um tile (se existir)
  static Future<String?> getTilePath(int z, int x, int y) async {
    await _databaseLock.acquire();
    try {
      final db = await database;
      final tileHash = _generateTileHash(z, x, y);
      
      final result = await db.query(
        _tableCachedTiles,
        where: 'tile_hash = ?',
        whereArgs: [tileHash],
        limit: 1,
      );
      
      if (result.isEmpty) return null;
      
      // Atualizar tempo de acesso
      await db.update(
        _tableCachedTiles,
        {'acessado_em': DateTime.now().millisecondsSinceEpoch},
        where: 'tile_hash = ?',
        whereArgs: [tileHash],
      );
      
      return result.first['file_path'] as String;
    } finally {
      _databaseLock.release();
    }
  }
  
  /// Obtém estatísticas de cache
  static Future<Map<String, dynamic>> getCacheStats() async {
    await _databaseLock.acquire();
    try {
      final db = await database;
      
      // Total de tiles
      final tileCountResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableCachedTiles'
      );
      final tileCount = (tileCountResult.first['count'] as int?) ?? 0;
      
      // Total de espaço
      final sizeResult = await db.rawQuery(
        'SELECT SUM(file_size) as total_size FROM $_tableCachedTiles'
      );
      final totalSize = (sizeResult.first['total_size'] as int?) ?? 0;
      
      // Total de áreas
      final areaCountResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableCacheAreas'
      );
      final areaCount = (areaCountResult.first['count'] as int?) ?? 0;
      
      return {
        'tile_count': tileCount,
        'total_size_mb': totalSize / (1024 * 1024),
        'area_count': areaCount,
        'total_size_bytes': totalSize,
      };
    } finally {
      _databaseLock.release();
    }
  }
  
  /// Remove tiles não acessados por mais de X dias (LRU)
  static Future<int> cleanOldTiles({int daysOld = 30}) async {
    await _databaseLock.acquire();
    try {
      final db = await database;
      final cutoffTime = DateTime.now()
        .subtract(Duration(days: daysOld))
        .millisecondsSinceEpoch;
      
      debugPrint('🧹 Limpando tiles não acessados há $daysOld dias...');
      
      final tilesToDelete = await db.query(
        _tableCachedTiles,
        where: 'acessado_em < ?',
        whereArgs: [cutoffTime],
      );
      
      // Deletar arquivos físicos
      for (final tile in tilesToDelete) {
        final filePath = tile['file_path'] as String;
        try {
          final file = File(filePath);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          debugPrint('⚠️ Erro ao deletar arquivo: $filePath - $e');
        }
      }
      
      // Deletar registros do banco
      final deleted = await db.delete(
        _tableCachedTiles,
        where: 'acessado_em < ?',
        whereArgs: [cutoffTime],
      );
      
      debugPrint('✅ $deleted tiles removidos');
      return deleted;
    } finally {
      _databaseLock.release();
    }
  }
  
  /// Remove tiles até ficar sob o limite de tamanho (em MB)
  static Future<int> cleanUntilSizeLimit({int maxSizeMb = 500}) async {
    await _databaseLock.acquire();
    try {
      final db = await database;
      final maxSizeBytes = maxSizeMb * 1024 * 1024;
      
      debugPrint('📦 Verificando limite de tamanho: ${maxSizeMb}MB...');
      
      // Stats sem lock pois já estamos dentro do lock
      final tileCountResult = await db.rawQuery(
        'SELECT SUM(file_size) as total_size FROM $_tableCachedTiles'
      );
      final currentSize = (tileCountResult.first['total_size'] as int?) ?? 0;
      
      if (currentSize <= maxSizeBytes) {
        debugPrint('✅ Tamanho dentro do limite');
        return 0;
      }
      
      debugPrint('⚠️ Tamanho acima do limite: ${(currentSize / 1024 / 1024).toStringAsFixed(2)}MB');
      
      // Obter tiles ordenados por acesso (LRU)
      final tilesToClean = await db.query(
        _tableCachedTiles,
        orderBy: 'acessado_em ASC',
      );
      
      int deletedCount = 0;
      int deletedSize = 0;
      
      for (final tile in tilesToClean) {
        if (currentSize - deletedSize <= maxSizeBytes) break;
        
        final filePath = tile['file_path'] as String;
        final fileSize = tile['file_size'] as int;
        
        try {
          final file = File(filePath);
          if (await file.exists()) {
            await file.delete();
          }
          
          await db.delete(
            _tableCachedTiles,
            where: 'id = ?',
            whereArgs: [tile['id']],
          );
          
          deletedCount++;
          deletedSize += fileSize;
        } catch (e) {
          debugPrint('⚠️ Erro ao limpar tile: $e');
        }
      }
      
      debugPrint('✅ $deletedCount tiles removidos (${(deletedSize / 1024 / 1024).toStringAsFixed(2)}MB)');
      return deletedCount;
    } finally {
      _databaseLock.release();
    }
  }
  
  /// Fecha o banco de dados
  static Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
  
  // ==================== HELPERS ====================
  
  /// Gera hash único para um tile
  static String _generateTileHash(int z, int x, int y) {
    return '$z-$x-$y';
  }
}

/// 🔒 Semáforo para controlar acesso ao SQLite
/// Limita a 1 operação por vez para evitar "database is locked"
class Semaphore {
  final int _permits;
  late int _available;
  final List<Completer<void>> _waiters = [];
  
  Semaphore(this._permits) {
    _available = _permits;
  }
  
  Future<void> acquire() async {
    if (_available > 0) {
      _available--;
      return;
    }
    
    final completer = Completer<void>();
    _waiters.add(completer);
    await completer.future;
  }
  
  void release() {
    if (_waiters.isNotEmpty) {
      final completer = _waiters.removeAt(0);
      completer.complete();
    } else {
      _available++;
    }
  }
}
