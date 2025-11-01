import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import '../models/ceo_model.dart';
import '../models/cabo_model.dart';
import '../models/cto_model.dart';
import '../models/olt_model.dart';
import '../models/dio_model.dart';

/// Serviço para calcular rotas, distâncias e validar conexões
class RoutesValidationService {
  // Constante para cálculo de haversine
  static const double earthRadiusKm = 6371.0;

  /// Calcula distância em km entre dois pontos usando fórmula haversine
  static double calcularDistancia(LatLng ponto1, LatLng ponto2) {
    final lat1 = _toRad(ponto1.latitude);
    final lat2 = _toRad(ponto2.latitude);
    final deltaLat = _toRad(ponto2.latitude - ponto1.latitude);
    final deltaLng = _toRad(ponto2.longitude - ponto1.longitude);

    final a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) * math.cos(lat2) * 
        math.sin(deltaLng / 2) * math.sin(deltaLng / 2);
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _toRad(double graus) => graus * math.pi / 180;

  /// Formata distância para exibição (metros ou km)
  static String formatarDistancia(double distanciaKm) {
    if (distanciaKm < 1) {
      return '${(distanciaKm * 1000).toStringAsFixed(0)}m';
    }
    return '${distanciaKm.toStringAsFixed(2)}km';
  }

  /// Valida uma fusão verificando se os cabos existem e têm fibras válidas
  static ValidacaoFusao validarFusao(
    FusaoCEO fusao,
    CEOModel ceo,
    Map<String, CaboModel> cabosMap,
  ) {
    final problemas = <String>[];

    // Verificar se cabos existem
    final caboEntrada = cabosMap[fusao.caboEntradaId];
    final caboSaida = cabosMap[fusao.caboSaidaId];

    if (caboEntrada == null) {
      problemas.add('Cabo de entrada não encontrado');
    } else if (fusao.fibraEntradaNumero > caboEntrada.configuracao.totalFibras) {
      problemas.add('Fibra entrada ${fusao.fibraEntradaNumero} > fibras do cabo (${caboEntrada.configuracao.totalFibras})');
    }

    if (caboSaida == null) {
      problemas.add('Cabo de saída não encontrado');
    } else if (fusao.fibraSaidaNumero > caboSaida.configuracao.totalFibras) {
      problemas.add('Fibra saída ${fusao.fibraSaidaNumero} > fibras do cabo (${caboSaida.configuracao.totalFibras})');
    }

    // Verificar atenuação
    if (fusao.atenuacao != null && fusao.atenuacao! < 0) {
      problemas.add('Atenuação não pode ser negativa');
    }

    return ValidacaoFusao(
      valida: problemas.isEmpty,
      problemas: problemas,
    );
  }

  /// Analisa todas as conexões do sistema
  static RelatorioValidacao analisarConexoes({
    required List<CTOModel> ctos,
    required List<CEOModel> ceos,
    required List<OLTModel> olts,
    required List<DIOModel> dios,
    required List<CaboModel> cabos,
  }) {
    final cabosMap = {for (var cabo in cabos) cabo.id: cabo};
    final problemas = <ProblemaConexao>[];
    var totalFusoes = 0;
    var fusoesCOMProblemas = 0;

    // Validar fusões em CEOs
    for (var ceo in ceos) {
      for (var fusao in ceo.fusoes) {
        totalFusoes++;
        final validacao = validarFusao(fusao, ceo, cabosMap);
        
        if (!validacao.valida) {
          fusoesCOMProblemas++;
          for (var problema in validacao.problemas) {
            problemas.add(ProblemaConexao(
              tipo: TipoProblema.fusaoInvalida,
              elementoId: ceo.id,
              elementoNome: ceo.nome,
              descricao: 'Fusão inválida: $problema',
              severidade: Severidade.critica,
            ));
          }
        }

        // Verificar atenuação excessiva
        if (fusao.atenuacao != null && fusao.atenuacao! > 3.0) {
          problemas.add(ProblemaConexao(
            tipo: TipoProblema.atenuacaoAlta,
            elementoId: ceo.id,
            elementoNome: ceo.nome,
            descricao: 'Atenuação alta: ${fusao.atenuacao} dB (acima de 3dB)',
            severidade: Severidade.aviso,
          ));
        }
      }
    }

    // Verificar cabos sem conexões
    for (var cabo in cabos) {
      var temConexao = false;
      
      for (var ceo in ceos) {
        if (ceo.fusoes.any((f) => 
            f.caboEntradaId == cabo.id || f.caboSaidaId == cabo.id)) {
          temConexao = true;
          break;
        }
      }

      if (!temConexao) {
        problemas.add(ProblemaConexao(
          tipo: TipoProblema.caboSemConexao,
          elementoId: cabo.id,
          elementoNome: cabo.nome,
          descricao: 'Cabo não tem conexões (fusões)',
          severidade: Severidade.info,
        ));
      }
    }

    return RelatorioValidacao(
      totalFusoes: totalFusoes,
      fusoesCOMProblemas: fusoesCOMProblemas,
      problemas: problemas,
      dataAnalise: DateTime.now(),
    );
  }

  /// Analisa rotas possíveis entre CTOs e OLTs
  static List<RotaAnalise> analisarRotas({
    required List<CTOModel> ctos,
    required List<CEOModel> ceos,
    required List<OLTModel> olts,
    required List<CaboModel> cabos,
  }) {
    final rotas = <RotaAnalise>[];
    final cabosMap = {for (var cabo in cabos) cabo.id: cabo};

    // Mapa de conexões: elemento -> elementos conectados
    final conexoes = <String, Set<String>>{};

    // Mapear conexões via fusões
    for (var ceo in ceos) {
      for (var fusao in ceo.fusoes) {
        final caboEntrada = cabosMap[fusao.caboEntradaId];
        final caboSaida = cabosMap[fusao.caboSaidaId];

        if (caboEntrada != null && caboSaida != null) {
          // Adicionar conexão bidirecional
          (conexoes.putIfAbsent(ceo.id, () => {}) ).add(ceo.id);
        }
      }
    }

    // Gerar rotas de cada CTO para cada OLT
    for (var cto in ctos) {
      for (var olt in olts) {
        // Encontrar CEOs mais próximas
        final ceosComDistancia = <(CEOModel ceo, double distancia)>[];
        for (var ceo in ceos) {
          final dist = calcularDistancia(cto.posicao, ceo.posicao);
          ceosComDistancia.add((ceo, dist));
        }
        
        ceosComDistancia.sort((a, b) => a.$2.compareTo(b.$2));
        final ceosProximas = ceosComDistancia.take(3).toList();

        // Calcular rota via CEO(s)
        var distanciaTotal = 0.0;
        var numFusoes = 0;

        for (var item in ceosProximas) {
          distanciaTotal += item.$2;
          numFusoes += item.$1.fusoes.length;
        }

        final ultimaCeo = ceosProximas.isNotEmpty ? ceosProximas.last.$1 : null;
        distanciaTotal += calcularDistancia(
          ultimaCeo?.posicao ?? cto.posicao,
          olt.posicao,
        );

        rotas.add(RotaAnalise(
          ctoId: cto.id,
          ctoNome: cto.nome,
          oltId: olt.id,
          oltNome: olt.nome,
          ceosIntermediarias: ceosProximas.map((item) => item.$1).toList(),
          distanciaTotal: distanciaTotal,
          numFusoes: numFusoes,
          valida: numFusoes > 0,
        ));
      }
    }

    return rotas;
  }
}

/// Resultado da validação de uma fusão
class ValidacaoFusao {
  final bool valida;
  final List<String> problemas;

  ValidacaoFusao({
    required this.valida,
    required this.problemas,
  });
}

/// Problema encontrado na validação
class ProblemaConexao {
  final TipoProblema tipo;
  final String elementoId;
  final String elementoNome;
  final String descricao;
  final Severidade severidade;

  ProblemaConexao({
    required this.tipo,
    required this.elementoId,
    required this.elementoNome,
    required this.descricao,
    required this.severidade,
  });
}

/// Tipos de problemas que podem ser encontrados
enum TipoProblema {
  fusaoInvalida,
  atenuacaoAlta,
  caboSemConexao,
  elementoSemConexao,
  fibrasInsuficientes,
}

/// Níveis de severidade
enum Severidade {
  info,
  aviso,
  critica,
}

/// Relatório completo de validação
class RelatorioValidacao {
  final int totalFusoes;
  final int fusoesCOMProblemas;
  final List<ProblemaConexao> problemas;
  final DateTime dataAnalise;

  RelatorioValidacao({
    required this.totalFusoes,
    required this.fusoesCOMProblemas,
    required this.problemas,
    required this.dataAnalise,
  });

  double get taxaIntegridade => totalFusoes == 0 
      ? 100 
      : ((totalFusoes - fusoesCOMProblemas) / totalFusoes * 100);

  int get problemasInfo => problemas.where((p) => p.severidade == Severidade.info).length;
  int get problemasAviso => problemas.where((p) => p.severidade == Severidade.aviso).length;
  int get problemasCriticos => problemas.where((p) => p.severidade == Severidade.critica).length;
}

/// Análise de uma rota
class RotaAnalise {
  final String ctoId;
  final String ctoNome;
  final String oltId;
  final String oltNome;
  final List<CEOModel> ceosIntermediarias;
  final double distanciaTotal;
  final int numFusoes;
  final bool valida;

  RotaAnalise({
    required this.ctoId,
    required this.ctoNome,
    required this.oltId,
    required this.oltNome,
    required this.ceosIntermediarias,
    required this.distanciaTotal,
    required this.numFusoes,
    required this.valida,
  });

  String get descricaoCaminho {
    final ceos = ceosIntermediarias.map((c) => c.nome).join(' → ');
    return '$ctoNome → $ceos → $oltNome';
  }
}
