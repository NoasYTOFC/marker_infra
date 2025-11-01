import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class PermissionService {
  /// Solicita permissão de localização
  /// Retorna true se a permissão foi concedida
  static Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    
    if (status.isDenied) {
      // Permissão negada
      return false;
    } else if (status.isPermanentlyDenied) {
      // Permissão negada permanentemente, abrir configurações
      openAppSettings();
      return false;
    } else if (status.isGranted || status.isLimited) {
      return true;
    }
    return false;
  }

  /// Solicita permissão de armazenamento
  /// Retorna true se a permissão foi concedida
  static Future<bool> requestStoragePermission() async {
    // Android 13+ usa PHOTOS, VIDEOS, AUDIO
    // Android 11-12 usa READ/WRITE_EXTERNAL_STORAGE
    // Android 10 usa READ/WRITE_EXTERNAL_STORAGE com scoped storage
    
    if (Platform.isAndroid) {
      debugPrint('🔐 Solicitando permissão de armazenamento...');
      
      // Tentar com MANAGE_EXTERNAL_STORAGE (Android 11+)
      debugPrint('🔐 Tentando MANAGE_EXTERNAL_STORAGE (Android 11+)...');
      final manageStatus = await Permission.manageExternalStorage.request();
      debugPrint('🔐 Status MANAGE_EXTERNAL_STORAGE: $manageStatus');
      
      if (manageStatus.isGranted) {
        debugPrint('✅ MANAGE_EXTERNAL_STORAGE concedida!');
        return true;
      }
      
      // Fallback para READ_EXTERNAL_STORAGE + WRITE_EXTERNAL_STORAGE
      debugPrint('🔐 Tentando READ/WRITE_EXTERNAL_STORAGE (fallback)...');
      final readStatus = await Permission.storage.request();
      debugPrint('🔐 Status storage: $readStatus');
      
      if (readStatus.isGranted || readStatus.isLimited) {
        debugPrint('✅ Permissão de storage concedida!');
        return true;
      }
      
      if (readStatus.isDenied) {
        debugPrint('❌ Permissão de storage negada pelo usuário');
        return false;
      } else if (readStatus.isPermanentlyDenied) {
        debugPrint('❌ Permissão de storage negada permanentemente');
        openAppSettings();
        return false;
      }
    } else if (Platform.isIOS) {
      debugPrint('📱 iOS - Sem permissão explícita necessária');
      // iOS não precisa de permissão explícita para armazenamento local
      return true;
    }
    
    debugPrint('⚠️ Platform não reconhecida');
    return false;
  }

  /// Obtém a localização atual do usuário
  /// Retorna posição ou null se houver erro
  static Future<Position?> getCurrentLocation() async {
    try {
      // Verificar se localização está habilitada
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Abrir configurações de localização
        await Geolocator.openLocationSettings();
        return null;
      }

      // Solicitar permissão
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        return null;
      }

      // Obter localização com timeout de 10 segundos
      try {
        final position = await Geolocator.getCurrentPosition(
          timeLimit: const Duration(seconds: 10),
          forceAndroidLocationManager: true,
        );
        return position;
      } catch (e) {
        print('Erro ao obter localização: $e');
        return null;
      }
    } catch (e) {
      print('Erro ao obter localização: $e');
      return null;
    }
  }
}
