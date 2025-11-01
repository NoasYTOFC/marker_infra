import '../models/ceo_model.dart';
import '../models/cabo_model.dart';
import 'routes_validation_service.dart';

/// Serviço para analisar rotas internas de cada CEO
class AnalisadorRotasInternas {
  
  /// Analisa todas as rotas internas de um CEO
  static AnaliseRotasCEO analisarRotasCEO(
    CEOModel ceo,
    Map<String, CaboModel> cabosMap,
  ) {
    final fluxos = <FluxoRota>[];
    final cabosEntrada = <String, InfoCaboEntradasaida>{};
    final cabosSaida = <String, InfoCaboEntradasaida>{};
    
    double atenuacaoTotal = 0;
    int totalFusoes = 0;

    // Analisar cada fusão
    for (var fusao in ceo.fusoes) {
      totalFusoes++;
      
      final caboEntrada = cabosMap[fusao.caboEntradaId];
      final caboSaida = cabosMap[fusao.caboSaidaId];

      if (caboEntrada == null || caboSaida == null) continue;

      // Registrar entrada
      if (!cabosEntrada.containsKey(fusao.caboEntradaId)) {
        cabosEntrada[fusao.caboEntradaId] = InfoCaboEntradasaida(
          caboId: fusao.caboEntradaId,
          caboNome: caboEntrada.nome,
          distancia: caboEntrada.metragem ?? caboEntrada.calcularMetragem(),
          fibrasUsadas: 0,
          ocupacao: 0,
          totalFibras: caboEntrada.tubos.length, // Usar número de tubos como total de fibras
        );
      }
      cabosEntrada[fusao.caboEntradaId]!.fibrasUsadas++;

      // Registrar saída
      if (!cabosSaida.containsKey(fusao.caboSaidaId)) {
        cabosSaida[fusao.caboSaidaId] = InfoCaboEntradasaida(
          caboId: fusao.caboSaidaId,
          caboNome: caboSaida.nome,
          distancia: caboSaida.metragem ?? caboSaida.calcularMetragem(),
          fibrasUsadas: 0,
          ocupacao: 0,
          totalFibras: caboSaida.tubos.length, // Usar número de tubos como total de fibras
        );
      }
      cabosSaida[fusao.caboSaidaId]!.fibrasUsadas++;

      // Atualizar atenuação total
      if (fusao.atenuacao != null) {
        atenuacaoTotal += fusao.atenuacao!;
      }

      // Criar ou atualizar fluxo
      _atualizarFluxo(
        fluxos,
        fusao.caboEntradaId,
        fusao.caboSaidaId,
        caboEntrada,
        caboSaida,
        fusao,
      );
    }

    // Calcular ocupação de fibras
    for (var info in cabosEntrada.values) {
      if (info.totalFibras > 0) {
        info.ocupacao = (info.fibrasUsadas / info.totalFibras * 100);
      } else {
        info.ocupacao = 0;
      }
    }
    for (var info in cabosSaida.values) {
      if (info.totalFibras > 0) {
        info.ocupacao = (info.fibrasUsadas / info.totalFibras * 100);
      } else {
        info.ocupacao = 0;
      }
    }

    // Calcular atenuação média
    final atenuacaoMedia =
        totalFusoes > 0 ? atenuacaoTotal / totalFusoes.toDouble() : 0.0;

    return AnaliseRotasCEO(
      ceoId: ceo.id,
      ceoNome: ceo.nome,
      cabosEntrada: cabosEntrada.values.toList(),
      cabosSaida: cabosSaida.values.toList(),
      fluxos: fluxos,
      totalFusoes: totalFusoes,
      atenuacaoMedia: atenuacaoMedia,
      atenuacaoTotal: atenuacaoTotal,
    );
  }

  /// Atualiza ou cria um fluxo de rota
  static void _atualizarFluxo(
    List<FluxoRota> fluxos,
    String caboEntradaId,
    String caboSaidaId,
    CaboModel caboEntrada,
    CaboModel caboSaida,
    FusaoCEO fusao,
  ) {
    // Procurar fluxo existente
    final fluxoExistente = fluxos.firstWhere(
      (f) =>
          f.caboEntradaId == caboEntradaId &&
          f.caboSaidaId == caboSaidaId,
      orElse: () => FluxoRota(
        caboEntradaId: caboEntradaId,
        caboEntradaNome: caboEntrada.nome,
        caboSaidaId: caboSaidaId,
        caboSaidaNome: caboSaida.nome,
        distanciaEntrada: caboEntrada.metragem ?? caboEntrada.calcularMetragem(),
        distanciaSaida: caboSaida.metragem ?? caboSaida.calcularMetragem(),
        numFusoes: 0,
        atenuacaoTotal: 0,
        atenuacaoMedia: 0,
        fibrasUsadas: 0,
      ),
    );

    if (!fluxos.contains(fluxoExistente)) {
      fluxos.add(fluxoExistente);
    }

    // Atualizar fluxo
    fluxoExistente.numFusoes++;
    fluxoExistente.fibrasUsadas++;
    if (fusao.atenuacao != null) {
      fluxoExistente.atenuacaoTotal += fusao.atenuacao!;
    }
    fluxoExistente.atenuacaoMedia =
        fluxoExistente.atenuacaoTotal / fluxoExistente.numFusoes;
  }

  /// Análisa distância calculada por atenuação
  static String avaliarAtenuacao(double atenuacao) {
    if (atenuacao < 0.5) return '✅ Excelente';
    if (atenuacao < 1.0) return '🟢 Bom';
    if (atenuacao < 2.0) return '🟡 Aceitável';
    if (atenuacao < 3.0) return '🟠 Preocupante';
    return '🔴 Crítico';
  }

  /// Calcula o "score" de saúde de uma rota (0-100)
  static int calcularScoreSaude(FluxoRota fluxo) {
    // Score baseado em atenuação
    // 0 dB = 100 pontos, -3 dB = 0 pontos
    var score = (100 * (1 - (fluxo.atenuacaoMedia.abs() / 3))).toInt();
    score = score.clamp(0, 100);
    return score;
  }
}

/// Informações sobre um cabo (entrada ou saída)
class InfoCaboEntradasaida {
  final String caboId;
  final String caboNome;
  final double distancia; // em metros
  int fibrasUsadas;
  double ocupacao; // percentual
  final int totalFibras;

  InfoCaboEntradasaida({
    required this.caboId,
    required this.caboNome,
    required this.distancia,
    required this.fibrasUsadas,
    required this.ocupacao,
    required this.totalFibras,
  });

  String get distanciaFormatada =>
      RoutesValidationService.formatarDistancia(distancia / 1000);
}

/// Fluxo de rota (entrada → saída)
class FluxoRota {
  final String caboEntradaId;
  final String caboEntradaNome;
  final String caboSaidaId;
  final String caboSaidaNome;
  final double distanciaEntrada; // metros
  final double distanciaSaida; // metros
  int numFusoes;
  double atenuacaoTotal;
  double atenuacaoMedia;
  int fibrasUsadas;

  FluxoRota({
    required this.caboEntradaId,
    required this.caboEntradaNome,
    required this.caboSaidaId,
    required this.caboSaidaNome,
    required this.distanciaEntrada,
    required this.distanciaSaida,
    required this.numFusoes,
    required this.atenuacaoTotal,
    required this.atenuacaoMedia,
    required this.fibrasUsadas,
  });

  double get distanciaTotal => distanciaEntrada + distanciaSaida;

  String get distanciaFormatada =>
      RoutesValidationService.formatarDistancia(distanciaTotal / 1000);

  String get descricaoCaminho =>
      '$caboEntradaNome → $caboSaidaNome';
}

/// Análise completa de rotas de um CEO
class AnaliseRotasCEO {
  final String ceoId;
  final String ceoNome;
  final List<InfoCaboEntradasaida> cabosEntrada;
  final List<InfoCaboEntradasaida> cabosSaida;
  final List<FluxoRota> fluxos;
  final int totalFusoes;
  final double atenuacaoMedia;
  final double atenuacaoTotal;

  AnaliseRotasCEO({
    required this.ceoId,
    required this.ceoNome,
    required this.cabosEntrada,
    required this.cabosSaida,
    required this.fluxos,
    required this.totalFusoes,
    required this.atenuacaoMedia,
    required this.atenuacaoTotal,
  });

  // Fibra mais usada na entrada
  InfoCaboEntradasaida? get caboEntradaMaisUsado {
    if (cabosEntrada.isEmpty) return null;
    return cabosEntrada.reduce((a, b) =>
        a.fibrasUsadas > b.fibrasUsadas ? a : b);
  }

  // Fibra mais usada na saída
  InfoCaboEntradasaida? get caboSaidaMaisUsado {
    if (cabosSaida.isEmpty) return null;
    return cabosSaida.reduce((a, b) =>
        a.fibrasUsadas > b.fibrasUsadas ? a : b);
  }

  // Score de saúde geral (0-100)
  int get scoreGeral {
    if (fluxos.isEmpty) return 100;
    final scores = fluxos.map(AnalisadorRotasInternas.calcularScoreSaude);
    final media = scores.reduce((a, b) => a + b) / scores.length;
    return media.toInt();
  }
}
