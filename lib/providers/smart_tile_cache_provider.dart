import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../services/smart_tile_cache_service.dart';

/// Provider para gerenciar estado do cache inteligente
class SmartTileCacheProvider extends ChangeNotifier {
  Map<String, dynamic> _cacheStats = {
    'tile_count': 0,
    'total_size_mb': 0.0,
    'area_count': 0,
  };
  
  bool _isDownloading = false;
  String _downloadStatus = '';
  double _downloadProgress = 0.0;
  
  // Getters
  Map<String, dynamic> get cacheStats => _cacheStats;
  bool get isDownloading => _isDownloading;
  String get downloadStatus => _downloadStatus;
  double get downloadProgress => _downloadProgress;
  
  SmartTileCacheProvider() {
    // Setup callbacks
    SmartTileCacheService.onStatus = _onStatusUpdate;
    SmartTileCacheService.onProgress = _onProgressUpdate;
    
    // Carregar stats iniciais
    _loadStats();
  }
  
  /// Atualiza callback de status
  void _onStatusUpdate(String status) {
    _downloadStatus = status;
    notifyListeners();
  }
  
  /// Atualiza callback de progresso
  void _onProgressUpdate(int current, int total, double percent) {
    _downloadProgress = percent;
    notifyListeners();
  }
  
  /// Carrega estatísticas do cache
  Future<void> _loadStats() async {
    _cacheStats = await SmartTileCacheService.getCacheStats();
    notifyListeners();
  }
  
  /// Inicia cache para um elemento
  Future<void> initCacheForElement({
    required String elementoId,
    required String elementoTipo,
    required double latitude,
    required double longitude,
    double radiusKm = 1.0,
  }) async {
    _isDownloading = true;
    _downloadProgress = 0.0;
    notifyListeners();
    
    try {
      await SmartTileCacheService.initCacheForElement(
        elementoId: elementoId,
        elementoTipo: elementoTipo,
        posicao: LatLng(latitude, longitude),
        radiusKm: radiusKm,
      );
      
      await _loadStats();
    } finally {
      _isDownloading = false;
      notifyListeners();
    }
  }
  
  /// Remove cache de um elemento
  Future<void> removeCacheForElement(String elementoId) async {
    await SmartTileCacheService.removeCacheForElement(elementoId);
    await _loadStats();
    notifyListeners();
  }
  
  /// Limpa cache manualmente
  Future<void> cleanCache() async {
    _isDownloading = true;
    notifyListeners();
    
    try {
      await SmartTileCacheService.cleanCache();
      await _loadStats();
    } finally {
      _isDownloading = false;
      notifyListeners();
    }
  }
  
  @override
  void dispose() {
    SmartTileCacheService.onStatus = null;
    SmartTileCacheService.onProgress = null;
    super.dispose();
  }
}
