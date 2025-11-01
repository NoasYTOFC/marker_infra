import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import '../models/cto_model.dart';
import '../models/cabo_model.dart';
import '../models/olt_model.dart';
import '../models/ceo_model.dart';
import '../models/dio_model.dart';
import '../services/storage_service.dart';

/// Gerenciador central de dados da infraestrutura
class InfrastructureProvider extends ChangeNotifier {
  final List<CTOModel> _ctos = [];
  final List<CaboModel> _cabos = [];
  final List<OLTModel> _olts = [];
  final List<CEOModel> _ceos = [];
  final List<DIOModel> _dios = [];
  
  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;
  
  // ⚡ Controle de concorrência para saves
  bool _isSaving = false;
  bool _pendingSave = false;
  Timer? _saveDebounceTimer;

  /// Carrega dados salvos
  Future<void> loadData() async {
    if (_isLoaded) return;
    
    try {
      final data = await StorageService.loadAll();
      
      _ctos.clear();
      _ctos.addAll(data['ctos'] as List<CTOModel>);
      
      _cabos.clear();
      _cabos.addAll(data['cabos'] as List<CaboModel>);
      
      _olts.clear();
      _olts.addAll(data['olts'] as List<OLTModel>);
      
      _ceos.clear();
      _ceos.addAll(data['ceos'] as List<CEOModel>);
      
      _dios.clear();
      _dios.addAll(data['dios'] as List<DIOModel>);
      
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar dados: $e');
    }
  }

  @override
  void dispose() {
    _saveDebounceTimer?.cancel();
    super.dispose();
  }

  /// Salva dados automaticamente com debouncing e controle de concorrência
  void _saveData() {
    // ⚡ Se já está salvando, marca como pendente e aguarda próxima oportunidade
    if (_isSaving) {
      _pendingSave = true;
      return;
    }
    
    // ⚡ Cancelar timer anterior se existir
    _saveDebounceTimer?.cancel();
    
    // ⚡ Agendar save com debounce de 500ms para evitar múltiplas chamadas
    _saveDebounceTimer = Timer(const Duration(milliseconds: 500), () async {
      _isSaving = true;
      _pendingSave = false;
      
      try {
        await StorageService.saveAll(
          ctos: _ctos,
          cabos: _cabos,
          olts: _olts,
          ceos: _ceos,
          dios: _dios,
        );
      } catch (e) {
        debugPrint('Erro ao salvar dados: $e');
      } finally {
        _isSaving = false;
        
        // ⚡ Se houver save pendente, fazer agora
        if (_pendingSave) {
          _saveData();
        }
      }
    });
  }

  // Getters
  List<CTOModel> get ctos => List.unmodifiable(_ctos);
  List<CaboModel> get cabos => List.unmodifiable(_cabos);
  List<OLTModel> get olts => List.unmodifiable(_olts);
  List<CEOModel> get ceos => List.unmodifiable(_ceos);
  List<DIOModel> get dios => List.unmodifiable(_dios);

  int get totalElements =>
      _ctos.length + _cabos.length + _olts.length + _ceos.length + _dios.length;

  // CTOs
  void addCTO(CTOModel cto) {
    _ctos.add(cto);
    _saveData();
    notifyListeners();
  }

  void updateCTO(CTOModel cto) {
    final index = _ctos.indexWhere((c) => c.id == cto.id);
    if (index != -1) {
      _ctos[index] = cto;
      _saveData();
      notifyListeners();
    }
  }

  void removeCTO(String id) {
    _ctos.removeWhere((c) => c.id == id);
    _saveData();
    notifyListeners();
  }

  CTOModel? getCTO(String id) {
    try {
      return _ctos.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  // Cabos
  void addCabo(CaboModel cabo) {
    _cabos.add(cabo);
    _saveData();
    notifyListeners();
  }

  void updateCabo(CaboModel cabo) {
    final index = _cabos.indexWhere((c) => c.id == cabo.id);
    if (index != -1) {
      _cabos[index] = cabo;
      _saveData();
      notifyListeners();
    }
  }

  void removeCabo(String id) {
    _cabos.removeWhere((c) => c.id == id);
    _saveData();
    notifyListeners();
  }

  CaboModel? getCabo(String id) {
    try {
      return _cabos.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  // OLTs
  void addOLT(OLTModel olt) {
    _olts.add(olt);
    _saveData();
    notifyListeners();
  }

  void updateOLT(OLTModel olt) {
    final index = _olts.indexWhere((o) => o.id == olt.id);
    if (index != -1) {
      _olts[index] = olt;
      _saveData();
      notifyListeners();
    }
  }

  void removeOLT(String id) {
    _olts.removeWhere((o) => o.id == id);
    _saveData();
    notifyListeners();
  }

  OLTModel? getOLT(String id) {
    try {
      return _olts.firstWhere((o) => o.id == id);
    } catch (e) {
      return null;
    }
  }

  // CEOs
  void addCEO(CEOModel ceo) {
    _ceos.add(ceo);
    _saveData();
    notifyListeners();
  }

  void updateCEO(CEOModel ceo) {
    final index = _ceos.indexWhere((c) => c.id == ceo.id);
    if (index != -1) {
      _ceos[index] = ceo;
      _saveData();
      notifyListeners();
    }
  }

  void removeCEO(String id) {
    _ceos.removeWhere((c) => c.id == id);
    _saveData();
    notifyListeners();
  }

  CEOModel? getCEO(String id) {
    try {
      return _ceos.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Adiciona uma fusão a uma CEO
  /// Normaliza atenuação para sempre ser positiva
  double? _normalizarAtenuacao(double? atenuacao) {
    if (atenuacao == null) return null;
    return atenuacao.abs();
  }

  void adicionarFusao(String ceoId, FusaoCEO fusao) {
    debugPrint('🔵 adicionarFusao INICIADO - CEOId: $ceoId');
    debugPrint('   Fusão recebida: ID="${fusao.id}", Cabo entrada: ${fusao.caboEntradaId}, Cabo saída: ${fusao.caboSaidaId}');
    
    final index = _ceos.indexWhere((c) => c.id == ceoId);
    debugPrint('   CEO encontrada: index=$index');
    
    if (index != -1) {
      final ceo = _ceos[index];
      debugPrint('   CEO: ${ceo.nome}, Fusões atuais: ${ceo.fusoes.length}/${ceo.capacidadeFusoes}');
      
      if (ceo.fusoes.length < ceo.capacidadeFusoes) {
        // Gerar ID se não tiver
        final fusaoComId = fusao.id.isEmpty
            ? FusaoCEO(
                id: const Uuid().v4(),
                caboEntradaId: fusao.caboEntradaId,
                fibraEntradaNumero: fusao.fibraEntradaNumero,
                caboSaidaId: fusao.caboSaidaId,
                fibraSaidaNumero: fusao.fibraSaidaNumero,
                atenuacao: _normalizarAtenuacao(fusao.atenuacao),
                dataFusao: fusao.dataFusao,
                tecnico: fusao.tecnico,
                observacao: fusao.observacao,
              )
            : FusaoCEO(
                id: fusao.id,
                caboEntradaId: fusao.caboEntradaId,
                fibraEntradaNumero: fusao.fibraEntradaNumero,
                caboSaidaId: fusao.caboSaidaId,
                fibraSaidaNumero: fusao.fibraSaidaNumero,
                atenuacao: _normalizarAtenuacao(fusao.atenuacao),
                dataFusao: fusao.dataFusao,
                tecnico: fusao.tecnico,
                observacao: fusao.observacao,
              );
        
        debugPrint('   Fusão com ID gerado: ID="${fusaoComId.id}"');
        
        final novasFusoes = [...ceo.fusoes, fusaoComId];
        final novoCEO = CEOModel(
          id: ceo.id,
          nome: ceo.nome,
          posicao: ceo.posicao,
          descricao: ceo.descricao,
          capacidadeFusoes: ceo.capacidadeFusoes,
          tipo: ceo.tipo,
          fusoes: novasFusoes,
          numeroCEO: ceo.numeroCEO,
          cabosConectadosIds: ceo.cabosConectadosIds,
          dataCriacao: ceo.dataCriacao,
          dataAtualizacao: DateTime.now(),
        );
        
        _ceos[index] = novoCEO;
        debugPrint('   ✅ CEO atualizada em memória com ${novasFusoes.length} fusões');
        
        debugPrint('   Salvando dados...');
        _saveData();
        debugPrint('   ✅ Dados salvos');
        
        notifyListeners();
        debugPrint('   ✅ Listeners notificados');
        
      } else {
        debugPrint('   ❌ CEO está cheia! ${ceo.fusoes.length}/${ceo.capacidadeFusoes}');
      }
    } else {
      debugPrint('   ❌ CEO NÃO ENCONTRADA! CEOId: $ceoId');
    }
  }

  /// Remove uma fusão de uma CEO
  void deletarFusao(String ceoId, String fusaoId) {
    final index = _ceos.indexWhere((c) => c.id == ceoId);
    if (index != -1) {
      final ceo = _ceos[index];
      final novasFusoes = ceo.fusoes.where((f) => f.id != fusaoId).toList();
      final novoCEO = CEOModel(
        id: ceo.id,
        nome: ceo.nome,
        posicao: ceo.posicao,
        descricao: ceo.descricao,
        capacidadeFusoes: ceo.capacidadeFusoes,
        tipo: ceo.tipo,
        fusoes: novasFusoes,
        numeroCEO: ceo.numeroCEO,
        cabosConectadosIds: ceo.cabosConectadosIds,
        dataCriacao: ceo.dataCriacao,
        dataAtualizacao: DateTime.now(),
      );
      _ceos[index] = novoCEO;
      _saveData();
      notifyListeners();
    }
  }

  /// Atualiza uma fusão existente de uma CEO
  void atualizarFusao(String ceoId, FusaoCEO fusaoAtualizada) {
    final index = _ceos.indexWhere((c) => c.id == ceoId);
    if (index != -1) {
      final ceo = _ceos[index];
      final novasFusoes = ceo.fusoes.map((f) {
        if (f.id == fusaoAtualizada.id) {
          // Normalizar atenuação
          return FusaoCEO(
            id: fusaoAtualizada.id,
            caboEntradaId: fusaoAtualizada.caboEntradaId,
            fibraEntradaNumero: fusaoAtualizada.fibraEntradaNumero,
            caboSaidaId: fusaoAtualizada.caboSaidaId,
            fibraSaidaNumero: fusaoAtualizada.fibraSaidaNumero,
            atenuacao: _normalizarAtenuacao(fusaoAtualizada.atenuacao),
            dataFusao: fusaoAtualizada.dataFusao,
            tecnico: fusaoAtualizada.tecnico,
            observacao: fusaoAtualizada.observacao,
          );
        }
        return f;
      }).toList();
      
      final novoCEO = CEOModel(
        id: ceo.id,
        nome: ceo.nome,
        posicao: ceo.posicao,
        descricao: ceo.descricao,
        capacidadeFusoes: ceo.capacidadeFusoes,
        tipo: ceo.tipo,
        fusoes: novasFusoes,
        numeroCEO: ceo.numeroCEO,
        cabosConectadosIds: ceo.cabosConectadosIds,
        dataCriacao: ceo.dataCriacao,
        dataAtualizacao: DateTime.now(),
      );
      _ceos[index] = novoCEO;
      debugPrint('💾 Fusão atualizada em CEO: ${ceo.nome}, Total fusões: ${novasFusoes.length}');
      _saveData();
      notifyListeners();
    }
  }

  // DIOs
  void addDIO(DIOModel dio) {
    _dios.add(dio);
    _saveData();
    notifyListeners();
  }

  void updateDIO(DIOModel dio) {
    final index = _dios.indexWhere((d) => d.id == dio.id);
    if (index != -1) {
      _dios[index] = dio;
      _saveData();
      notifyListeners();
    }
  }

  void removeDIO(String id) {
    _dios.removeWhere((d) => d.id == id);
    _saveData();
    notifyListeners();
  }

  DIOModel? getDIO(String id) {
    try {
      return _dios.firstWhere((d) => d.id == id);
    } catch (e) {
      return null;
    }
  }

  // Limpar tudo
  void clearAll() {
    _ctos.clear();
    _cabos.clear();
    _olts.clear();
    _ceos.clear();
    _dios.clear();
    _saveData();
    notifyListeners();
  }

  // Importar elementos em lote
  void importElements({
    List<CTOModel>? ctos,
    List<CaboModel>? cabos,
    List<OLTModel>? olts,
    List<CEOModel>? ceos,
    List<DIOModel>? dios,
  }) {
    if (ctos != null) _ctos.addAll(ctos);
    if (cabos != null) _cabos.addAll(cabos);
    if (olts != null) _olts.addAll(olts);
    if (ceos != null) _ceos.addAll(ceos);
    if (dios != null) _dios.addAll(dios);
    _saveData();
    notifyListeners();
  }

  // Estatísticas
  Map<String, dynamic> getStatistics() {
    int totalPortasCTO = _ctos.fold(0, (sum, cto) => sum + cto.numeroPortas);

    int totalPONs = _olts.fold(0, (sum, olt) => sum + olt.totalPONs);
    int ponsOcupados = _olts.fold(0, (sum, olt) => sum + olt.ponsOcupados);

    // Calcular metragem usando a função de cálculo ao invés do campo que pode ser nulo
    double totalMetragemCabos = _cabos.fold(0.0, (sum, cabo) {
      double metragemCabo = cabo.metragem ?? cabo.calcularMetragem();
      return sum + metragemCabo;
    });

    return {
      'totalCTOs': _ctos.length,
      'totalPortasCTO': totalPortasCTO,
      'portasOcupadasCTO': 0, // TODO: Implementar controle de portas ocupadas
      'totalOLTs': _olts.length,
      'totalPONs': totalPONs,
      'ponsOcupados': ponsOcupados,
      'totalCEOs': _ceos.length,
      'totalDIOs': _dios.length,
      'totalCabos': _cabos.length,
      'totalMetragemCabos': totalMetragemCabos,
    };
  }
}
