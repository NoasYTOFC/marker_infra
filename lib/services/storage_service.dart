import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cto_model.dart';
import '../models/cabo_model.dart';
import '../models/olt_model.dart';
import '../models/ceo_model.dart';
import '../models/dio_model.dart';

/// Serviço de persistência local de dados
class StorageService {
  static const String _keyCTOs = 'ctos';
  static const String _keyCabos = 'cabos';
  static const String _keyOLTs = 'olts';
  static const String _keyCEOs = 'ceos';
  static const String _keyDIOs = 'dios';

  /// Salva todos os elementos
  static Future<void> saveAll({
    required List<CTOModel> ctos,
    required List<CaboModel> cabos,
    required List<OLTModel> olts,
    required List<CEOModel> ceos,
    required List<DIOModel> dios,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    debugPrint('💾 StorageService.saveAll INICIADO');
    debugPrint('   CEOs: ${ceos.length}');
    
    // Contar fusões totais
    int totalFusoes = 0;
    for (final ceo in ceos) {
      totalFusoes += ceo.fusoes.length;
      if (ceo.fusoes.isNotEmpty) {
        debugPrint('   CEO ${ceo.nome}: ${ceo.fusoes.length} fusões');
      }
    }
    debugPrint('   Total fusões em todas CEOs: $totalFusoes');
    
    // Salvar CTOs
    await prefs.setString(
      _keyCTOs,
      jsonEncode(ctos.map((c) => c.toJson()).toList()),
    );
    debugPrint('   ✅ CTOs salvos (${ctos.length})');
    
    // Salvar Cabos
    await prefs.setString(
      _keyCabos,
      jsonEncode(cabos.map((c) => c.toJson()).toList()),
    );
    debugPrint('   ✅ Cabos salvos (${cabos.length})');
    
    // Salvar OLTs
    await prefs.setString(
      _keyOLTs,
      jsonEncode(olts.map((o) => o.toJson()).toList()),
    );
    debugPrint('   ✅ OLTs salvos (${olts.length})');
    
    // Salvar CEOs
    await prefs.setString(
      _keyCEOs,
      jsonEncode(ceos.map((c) => c.toJson()).toList()),
    );
    debugPrint('   ✅ CEOs salvas (${ceos.length}) com $totalFusoes fusões');
    
    // Salvar DIOs
    await prefs.setString(
      _keyDIOs,
      jsonEncode(dios.map((d) => d.toJson()).toList()),
    );
    debugPrint('   ✅ DIOs salvos (${dios.length})');
    debugPrint('✅ StorageService.saveAll CONCLUÍDO');
  }

  /// Carrega todos os elementos
  static Future<Map<String, dynamic>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Carregar CTOs
    final ctosJson = prefs.getString(_keyCTOs);
    final ctos = ctosJson != null
        ? (jsonDecode(ctosJson) as List)
            .map((json) => CTOModel.fromJson(json))
            .toList()
        : <CTOModel>[];
    
    // Carregar Cabos
    final cabosJson = prefs.getString(_keyCabos);
    final cabos = cabosJson != null
        ? (jsonDecode(cabosJson) as List)
            .map((json) => CaboModel.fromJson(json))
            .toList()
        : <CaboModel>[];
    
    // Carregar OLTs
    final oltsJson = prefs.getString(_keyOLTs);
    final olts = oltsJson != null
        ? (jsonDecode(oltsJson) as List)
            .map((json) => OLTModel.fromJson(json))
            .toList()
        : <OLTModel>[];
    
    // Carregar CEOs
    final ceosJson = prefs.getString(_keyCEOs);
    final ceos = ceosJson != null
        ? (jsonDecode(ceosJson) as List)
            .map((json) => CEOModel.fromJson(json))
            .toList()
        : <CEOModel>[];
    
    // Carregar DIOs
    final diosJson = prefs.getString(_keyDIOs);
    final dios = diosJson != null
        ? (jsonDecode(diosJson) as List)
            .map((json) => DIOModel.fromJson(json))
            .toList()
        : <DIOModel>[];
    
    return {
      'ctos': ctos,
      'cabos': cabos,
      'olts': olts,
      'ceos': ceos,
      'dios': dios,
    };
  }

  /// Limpa todos os dados salvos
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCTOs);
    await prefs.remove(_keyCabos);
    await prefs.remove(_keyOLTs);
    await prefs.remove(_keyCEOs);
    await prefs.remove(_keyDIOs);
  }
}
