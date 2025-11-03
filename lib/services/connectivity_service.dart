import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'cached_tile_provider.dart';

/// Callback quando a conectividade muda
typedef OnConnectivityChanged = void Function(bool isConnected);

/// Serviço para monitorar conectividade e recarregar tiles quando conexão voltar
/// Funciona em TODOS os platforms (Windows, Android, iOS, Web, etc)
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  
  bool _isConnected = true;
  late Timer _periodicCheck;
  final List<OnConnectivityChanged> _listeners = [];
  
  ConnectivityService._internal();
  
  factory ConnectivityService() {
    return _instance;
  }
  
  /// Registrar um listener para mudanças de conectividade
  void addListener(OnConnectivityChanged callback) {
    _listeners.add(callback);
  }
  
  /// Remover um listener
  void removeListener(OnConnectivityChanged callback) {
    _listeners.remove(callback);
  }
  
  /// Notificar todos os listeners sobre mudança de conectividade
  void _notifyListeners(bool isConnected) {
    for (final listener in _listeners) {
      listener(isConnected);
    }
  }
  
  /// Verificar se há conexão fazendo ping para um servidor confiável
  Future<bool> _checkConnectivity() async {
    try {
      // Tentar conectar a um servidor confiável com timeout rápido
      final response = await http.get(
        Uri.parse('https://www.google.com/'),
      ).timeout(const Duration(seconds: 3));
      
      final isConnected = response.statusCode == 200;
      debugPrint('📡 Verificação de conectividade: ${isConnected ? '✅ Online' : '❌ Offline'} (HTTP ${response.statusCode})');
      return isConnected;
    } catch (e) {
      debugPrint('📡 Verificação de conectividade: ❌ Offline - $e');
      return false;
    }
  }
  
  /// Iniciar monitoramento de conectividade com verificação periódica
  void startMonitoring() {
    debugPrint('🔄 Iniciando monitoramento de conectividade...');
    
    // Fazer uma verificação inicial
    _checkConnectivity().then((isConnected) {
      _isConnected = isConnected;
      debugPrint('📊 Estado inicial de conectividade: ${isConnected ? '✅ Online' : '❌ Offline'}');
    });
    
    // Verificar conectividade a cada 5 segundos
    _periodicCheck = Timer.periodic(const Duration(seconds: 5), (_) async {
      final isConnected = await _checkConnectivity();
      
      // Se estava sem conexão e agora tem, limpar tiles falhados
      if (!_isConnected && isConnected) {
        debugPrint('✅ Conexão restaurada! Limpando tiles que falharam para tentar novamente...');
        CachedTileProvider.clearFailedTiles();
        _notifyListeners(true);
      }
      
      // Se estava com conexão e perdeu
      if (_isConnected && !isConnected) {
        debugPrint('❌ Conexão perdida! Tiles que falharem serão marcados para retry...');
        _notifyListeners(false);
      }
      
      _isConnected = isConnected;
    });
  }
  
  /// Parar monitoramento
  void stopMonitoring() {
    _periodicCheck.cancel();
  }
}
