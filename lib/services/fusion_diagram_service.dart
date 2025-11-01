import 'package:flutter/material.dart';
import '../models/ceo_model.dart';
import '../models/cabo_model.dart';

/// Estrutura para representar uma fibra em um diagrama
class FibraVisual {
  final String caboId;
  final String caboNome;
  final int numeroFibra;
  final Color cor;
  final bool isEntrada;
  
  FibraVisual({
    required this.caboId,
    required this.caboNome,
    required this.numeroFibra,
    required this.cor,
    required this.isEntrada,
  });
}

/// Estrutura para representar uma fusão visualmente
class FusaoVisual {
  final String id;
  final FibraVisual entrada;
  final FibraVisual saida;
  final double? atenuacao;
  final String? tecnico;
  final String? observacao;
  
  FusaoVisual({
    required this.id,
    required this.entrada,
    required this.saida,
    this.atenuacao,
    this.tecnico,
    this.observacao,
  });
}

/// Service para gerar diagramas de fusão
class FusionDiagramService {
  /// Gera lista de fusões visuais para uma CEO
  static List<FusaoVisual> gerarDiagramaFusoes(
    CEOModel ceo,
    Map<String, CaboModel> cabosMap,
  ) {
    return ceo.fusoes.map((fusao) {
      final caboEntrada = cabosMap[fusao.caboEntradaId];
      final caboSaida = cabosMap[fusao.caboSaidaId];
      
      if (caboEntrada == null || caboSaida == null) return null;
      
      final fibraEntrada = FibraVisual(
        caboId: fusao.caboEntradaId,
        caboNome: caboEntrada.nome,
        numeroFibra: fusao.fibraEntradaNumero,
        cor: _gerarCorFibra(fusao.fibraEntradaNumero),
        isEntrada: true,
      );
      
      final fibraSaida = FibraVisual(
        caboId: fusao.caboSaidaId,
        caboNome: caboSaida.nome,
        numeroFibra: fusao.fibraSaidaNumero,
        cor: _gerarCorFibra(fusao.fibraSaidaNumero),
        isEntrada: false,
      );
      
      return FusaoVisual(
        id: fusao.id,
        entrada: fibraEntrada,
        saida: fibraSaida,
        atenuacao: fusao.atenuacao,
        tecnico: fusao.tecnico,
        observacao: fusao.observacao,
      );
    }).whereType<FusaoVisual>().toList();
  }
  
  /// Gera cor única para uma fibra baseado no número
  static Color _gerarCorFibra(int numeroFibra) {
    // Cores disponíveis (padrão de cores de fibra óptica)
    const cores = [
      Color(0xFFFFFFFF), // Branco
      Color(0xFFFF0000), // Vermelho
      Color(0xFF000000), // Preto
      Color(0xFFFFFF00), // Amarelo
      Color(0xFF00FF00), // Verde
      Color(0xFF0000FF), // Azul
      Color(0xFF800080), // Roxo
      Color(0xFF00FFFF), // Ciano
      Color(0xFFFF1493), // Rosa
      Color(0xFFFF8C00), // Laranja
      Color(0xFF808080), // Cinza
      Color(0xFF008000), // Verde Escuro
    ];
    
    return cores[numeroFibra % cores.length];
  }
  
  /// Calcula estatísticas de fusão
  static Map<String, dynamic> calcularEstatisticas(List<FusaoVisual> fusoes) {
    return {
      'totalFusoes': fusoes.length,
      'atenuacaoMedia': fusoes.isEmpty 
          ? 0.0 
          : fusoes.where((f) => f.atenuacao != null).fold(0.0, (sum, f) => sum + (f.atenuacao ?? 0)) / 
              (fusoes.where((f) => f.atenuacao != null).length),
      'atenuacaoMaxima': fusoes.isEmpty
          ? 0.0
          : fusoes.map((f) => f.atenuacao ?? 0).reduce((a, b) => a > b ? a : b),
      'cabosEnvolvidosEntrada': fusoes.map((f) => f.entrada.caboId).toSet().length,
      'cabosEnvolvidosSaida': fusoes.map((f) => f.saida.caboId).toSet().length,
    };
  }
  
  /// Valida uma fusão
  static ValidacaoFusao validarFusao(
    FusaoCEO fusao,
    CEOModel ceo,
    CaboModel? caboEntrada,
    CaboModel? caboSaida,
  ) {
    final erros = <String>[];
    
    if (caboEntrada == null) {
      erros.add('Cabo de entrada não encontrado');
    }
    
    if (caboSaida == null) {
      erros.add('Cabo de saída não encontrado');
    }
    
    if (caboEntrada != null && fusao.fibraEntradaNumero > caboEntrada.configuracao.totalFibras) {
      erros.add('Fibra de entrada (${fusao.fibraEntradaNumero}) excede o total de fibras do cabo (${caboEntrada.configuracao.totalFibras})');
    }
    
    if (caboSaida != null && fusao.fibraSaidaNumero > caboSaida.configuracao.totalFibras) {
      erros.add('Fibra de saída (${fusao.fibraSaidaNumero}) excede o total de fibras do cabo (${caboSaida.configuracao.totalFibras})');
    }
    
    if (fusao.caboEntradaId == fusao.caboSaidaId && 
        fusao.fibraEntradaNumero == fusao.fibraSaidaNumero) {
      erros.add('A fibra não pode ser fusionada consigo mesma');
    }
    
    return ValidacaoFusao(
      valido: erros.isEmpty,
      erros: erros,
    );
  }
}

/// Resultado da validação de uma fusão
class ValidacaoFusao {
  final bool valido;
  final List<String> erros;
  
  ValidacaoFusao({
    required this.valido,
    required this.erros,
  });
  
  String get mensagemErro => erros.join('\n');
}
