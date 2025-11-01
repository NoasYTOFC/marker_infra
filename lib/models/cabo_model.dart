import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'element_type.dart';

/// Configuração de fibras por padrão ABNT com cores específicas
enum ConfiguracaoCabo {
  fo2(2, 1, 'Verde, Amarelo', Color.fromRGBO(255, 221, 0, 1.0)),
  fo4(4, 2, 'Verde/Amarelo, Laranja/Marrom', Color.fromRGBO(64, 81, 181, 1.0)),
  fo6(6, 3, 'Verde/Amarelo, Laranja/Marrom, Azul/Rosa', Color.fromRGBO(103, 58, 183, 1.0)),
  fo12(12, 6, '2 tubos - Padrão ABNT', Color.fromRGBO(0, 188, 212, 1.0)),
  fo24(24, 12, '2 tubos - Padrão ABNT', Color.fromRGBO(244, 67, 54, 1.0)),
  fo36(36, 12, '3 tubos - Padrão ABNT', Color.fromRGBO(156, 39, 176, 1.0)), // Roxo
  fo48(48, 12, '4 tubos - Padrão ABNT', Color.fromRGBO(255, 152, 0, 1.0)), // Laranja
  fo72(72, 12, '6 tubos - Padrão ABNT', Color.fromRGBO(76, 175, 80, 1.0)), // Verde
  fo96(96, 12, '8 tubos - Padrão ABNT', Color.fromRGBO(0, 150, 136, 1.0)), // Teal
  fo144(144, 12, '12 tubos - Padrão ABNT', Color.fromRGBO(63, 81, 181, 1.0)); // Indigo

  final int totalFibras;
  final int fibrasPorTubo;
  final String descricao;
  final Color cor;

  const ConfiguracaoCabo(this.totalFibras, this.fibrasPorTubo, this.descricao, this.cor);

  int get numeroTubos => (totalFibras / fibrasPorTubo).ceil();

  String get nome => '${totalFibras}FO';

  /// Retorna a cor em formato hexadecimal para KML
  String get corHex {
    return '#${cor.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  static ConfiguracaoCabo? fromTotalFibras(int fibras) {
    try {
      return ConfiguracaoCabo.values.firstWhere((c) => c.totalFibras == fibras);
    } catch (e) {
      return null;
    }
  }
}

/// Tipos de instalação de cabos
enum TipoInstalacaoCabo {
  aereo('Aéreo', '🔌 Aéreo'),
  subterraneo('Subterrâneo', '🕳️ Subterrâneo'),
  espinado('Espinado', '📎 Espinado');

  final String valor;
  final String descricao;

  const TipoInstalacaoCabo(this.valor, this.descricao);

  static TipoInstalacaoCabo fromString(String? valor) {
    return values.firstWhere(
      (t) => t.valor == valor,
      orElse: () => TipoInstalacaoCabo.aereo,
    );
  }
}

/// Cores das fibras por padrão ABNT
class CoresFibras {
  static const List<String> padrao12Fibras = [
    'Verde',
    'Amarelo',
    'Branco',
    'Azul',
    'Vermelho',
    'Violeta',
    'Marrom',
    'Rosa',
    'Preto',
    'Cinza',
    'Laranja',
    'Aqua',
  ];

  static String obterCor(int numeroFibra) {
    final index = (numeroFibra - 1) % padrao12Fibras.length;
    return padrao12Fibras[index];
  }

  static String obterCorTubo(int numeroTubo) {
    return obterCor(numeroTubo);
  }
}

/// Modelo de Cabo de Fibra Óptica
class CaboModel {
  final String id;
  final String nome;
  final List<LatLng> rota; // Pontos do cabo
  final String? descricao;

  // Configurações técnicas
  final ConfiguracaoCabo configuracao;
  final String tipoInstalacao; // Aéreo, Subterrâneo, Espinado
  final double? metragem;
  final List<TuboCabo> tubos;
  
  // Conectividade
  final String? pontoInicioId; // ID do elemento inicial (CTO, CEO, etc)
  final String? pontoFimId; // ID do elemento final
  final List<String> elementosIntermediariosIds; // CTOs, CEOs no meio do cabo
  
  // Metadata
  final DateTime dataCriacao;
  final DateTime? dataAtualizacao;

  CaboModel({
    required this.id,
    required this.nome,
    required this.rota,
    this.descricao,
    required this.configuracao,
    this.tipoInstalacao = 'Aéreo',
    this.metragem,
    List<TuboCabo>? tubos,
    this.pontoInicioId,
    this.pontoFimId,
    List<String>? elementosIntermediariosIds,
    DateTime? dataCriacao,
    this.dataAtualizacao,
  })  : tubos = tubos ?? _gerarTubosPadrao(configuracao),
        elementosIntermediariosIds = elementosIntermediariosIds ?? [],
        dataCriacao = dataCriacao ?? DateTime.now();

  static List<TuboCabo> _gerarTubosPadrao(ConfiguracaoCabo config) {
    return List.generate(
      config.numeroTubos,
      (i) => TuboCabo(
        numero: i + 1,
        cor: CoresFibras.obterCorTubo(i + 1),
        fibras: List.generate(
          config.fibrasPorTubo,
          (j) => FibraCabo(
            numero: j + 1,
            numeroGlobal: (i * config.fibrasPorTubo) + j + 1,
            cor: CoresFibras.obterCor(j + 1),
          ),
        ),
      ),
    );
  }

  String gerarDescricaoComKeys() {
    final buffer = StringBuffer();
    
    // Limpar descrição de keys antigas
    final descricaoLimpa = _removerKeysAntiga(descricao);
    
    if (descricaoLimpa != null && descricaoLimpa.isNotEmpty) {
      buffer.writeln(descricaoLimpa);
      buffer.writeln();
    }
    
    buffer.writeln('--- KEYS ---');
    buffer.writeln('ID: $id'); // 🎯 IMPORTANTE: Exportar o ID do cabo
    buffer.writeln('TYPE: ${ElementType.cabo.key}');
    buffer.writeln('TIMESTAMP: ${dataAtualizacao?.toIso8601String() ?? dataCriacao.toIso8601String()}');
    buffer.writeln('TIPO_FO: ${configuracao.nome}');
    buffer.writeln('FIBRAS: ${configuracao.totalFibras}');
    buffer.writeln('TUBOS: ${configuracao.numeroTubos}');
    buffer.writeln('FIBRAS_POR_TUBO: ${configuracao.fibrasPorTubo}');
    buffer.writeln('INSTALACAO: $tipoInstalacao');
    if (metragem != null) buffer.writeln('METRAGEM: ${metragem!.toStringAsFixed(2)}');
    if (pontoInicioId != null) buffer.writeln('PONTO_INICIO: $pontoInicioId');
    if (pontoFimId != null) buffer.writeln('PONTO_FIM: $pontoFimId');
    if (elementosIntermediariosIds.isNotEmpty) {
      buffer.writeln('ELEMENTOS_INTERMEDIARIOS: ${elementosIntermediariosIds.join(',')}');
    }
    
    return buffer.toString();
  }

  /// Remove a seção de KEYS antiga da descrição
  static String? _removerKeysAntiga(String? descricao) {
    if (descricao == null || descricao.isEmpty) return descricao;
    
    final lines = descricao.split('\n');
    final result = <String>[];
    bool inKeysSection = false;
    
    for (final line in lines) {
      if (line.trim() == '--- KEYS ---') {
        inKeysSection = true;
        continue;
      }
      
      if (inKeysSection) {
        if (!line.contains(':') && line.trim().isNotEmpty) {
          inKeysSection = false;
          result.add(line);
        }
        continue;
      }
      
      result.add(line);
    }
    
    while (result.isNotEmpty && result.last.trim().isEmpty) {
      result.removeLast();
    }
    
    return result.join('\n');
  }

  double calcularMetragem() {
    if (rota.length < 2) return 0.0;
    
    final distance = Distance();
    double total = 0.0;
    
    for (int i = 0; i < rota.length - 1; i++) {
      total += distance.as(LengthUnit.Meter, rota[i], rota[i + 1]);
    }
    
    return total;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'rota': rota.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
      'descricao': descricao,
      'configuracao': configuracao.totalFibras,
      'tipoInstalacao': tipoInstalacao,
      'metragem': metragem,
      'tubos': tubos.map((t) => t.toJson()).toList(),
      'pontoInicioId': pontoInicioId,
      'pontoFimId': pontoFimId,
      'elementosIntermediariosIds': elementosIntermediariosIds,
      'dataCriacao': dataCriacao.toIso8601String(),
      'dataAtualizacao': dataAtualizacao?.toIso8601String(),
    };
  }

  factory CaboModel.fromJson(Map<String, dynamic> json) {
    return CaboModel(
      id: json['id'],
      nome: json['nome'],
      rota: (json['rota'] as List)
          .map((p) => LatLng(p['lat'], p['lng']))
          .toList(),
      descricao: json['descricao'],
      configuracao: ConfiguracaoCabo.fromTotalFibras(json['configuracao'])!,
      tipoInstalacao: json['tipoInstalacao'],
      metragem: json['metragem']?.toDouble(),
      tubos: (json['tubos'] as List).map((t) => TuboCabo.fromJson(t)).toList(),
      pontoInicioId: json['pontoInicioId'],
      pontoFimId: json['pontoFimId'],
      elementosIntermediariosIds:
          List<String>.from(json['elementosIntermediariosIds'] ?? []),
      dataCriacao: DateTime.parse(json['dataCriacao']),
      dataAtualizacao: json['dataAtualizacao'] != null
          ? DateTime.parse(json['dataAtualizacao'])
          : null,
    );
  }
}

/// Modelo de tubo do cabo
class TuboCabo {
  final int numero;
  final String cor;
  final List<FibraCabo> fibras;

  TuboCabo({
    required this.numero,
    required this.cor,
    required this.fibras,
  });

  Map<String, dynamic> toJson() {
    return {
      'numero': numero,
      'cor': cor,
      'fibras': fibras.map((f) => f.toJson()).toList(),
    };
  }

  factory TuboCabo.fromJson(Map<String, dynamic> json) {
    return TuboCabo(
      numero: json['numero'],
      cor: json['cor'],
      fibras: (json['fibras'] as List)
          .map((f) => FibraCabo.fromJson(f))
          .toList(),
    );
  }
}

/// Modelo de fibra individual
class FibraCabo {
  final int numero; // Número dentro do tubo (1-12)
  final int numeroGlobal; // Número global no cabo (1-144)
  final String cor;
  final bool emUso;
  final String? fusaoId;
  final String? destinoId;
  final String? observacao;

  FibraCabo({
    required this.numero,
    required this.numeroGlobal,
    required this.cor,
    this.emUso = false,
    this.fusaoId,
    this.destinoId,
    this.observacao,
  });

  Map<String, dynamic> toJson() {
    return {
      'numero': numero,
      'numeroGlobal': numeroGlobal,
      'cor': cor,
      'emUso': emUso,
      'fusaoId': fusaoId,
      'destinoId': destinoId,
      'observacao': observacao,
    };
  }

  factory FibraCabo.fromJson(Map<String, dynamic> json) {
    return FibraCabo(
      numero: json['numero'],
      numeroGlobal: json['numeroGlobal'],
      cor: json['cor'],
      emUso: json['emUso'] ?? false,
      fusaoId: json['fusaoId'],
      destinoId: json['destinoId'],
      observacao: json['observacao'],
    );
  }

  FibraCabo copyWith({
    bool? emUso,
    String? fusaoId,
    String? destinoId,
    String? observacao,
  }) {
    return FibraCabo(
      numero: numero,
      numeroGlobal: numeroGlobal,
      cor: cor,
      emUso: emUso ?? this.emUso,
      fusaoId: fusaoId ?? this.fusaoId,
      destinoId: destinoId ?? this.destinoId,
      observacao: observacao ?? this.observacao,
    );
  }
}
