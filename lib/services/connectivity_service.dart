import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'cached_tile_provider.dart';

/// Serviço para monitorar conectividade e recarregar tiles quando conexão voltar
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  final Connectivity _connectivity = Connectivity();
  
  ConnectivityService._internal();
  
  factory ConnectivityService() {
    return _instance;
  }
  
  /// Iniciar monitoramento de conectividade
  void startMonitoring() {
    _connectivity.onConnectivityChanged.listen((result) {
      debugPrint('📡 Conectividade mudou: $result');
      
      // Se não está desconectado, limpar tiles falhados
      if (result != ConnectivityResult.none) {
        debugPrint('✅ Conexão restaurada! Limpando tiles que falharam para tentar novamente...');
        CachedTileProvider.clearFailedTiles();
      }
    });
  }
}
