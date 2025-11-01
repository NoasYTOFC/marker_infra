import 'package:latlong2/latlong.dart';
import 'element_type.dart';
import 'conexao_model.dart';

/// Modelo para Caixa de Terminação Óptica
class CTOModel {
  final String id;
  final String nome;
  final LatLng posicao;
  final String? descricao;
  
  // Configurações técnicas
  final int numeroPortas;
  final String tipoSplitter; // 1:8, 1:16, 1:32, etc
  final String? numeroCTO; // Número de identificação
  final List<PortaCTO> portas;
  
  // Conectividade
  final String? caboEntradaId;
  final List<String> cabosSaidaIds;
  
  // Metadata
  final DateTime dataCriacao;
  final DateTime? dataAtualizacao;

  CTOModel({
    required this.id,
    required this.nome,
    required this.posicao,
    this.descricao,
    required this.numeroPortas,
    required this.tipoSplitter,
    this.numeroCTO,
    List<PortaCTO>? portas,
    this.caboEntradaId,
    List<String>? cabosSaidaIds,
    DateTime? dataCriacao,
    this.dataAtualizacao,
  })  : portas = portas ?? [],
        cabosSaidaIds = cabosSaidaIds ?? [],
        dataCriacao = dataCriacao ?? DateTime.now();

  /// Gera a descrição com KEYS para exportação KML
  /// Remove keys antigas primeiro para evitar duplicação
  String gerarDescricaoComKeys() {
    final buffer = StringBuffer();
    
    // Limpar descrição de keys antigas
    final descricaoLimpa = GerenciadorConexoes.removerSecaoCompleteKeys(descricao);
    
    if (descricaoLimpa != null && descricaoLimpa.isNotEmpty) {
      buffer.writeln(descricaoLimpa);
      buffer.writeln();
    }
    
    buffer.writeln('--- KEYS ---');
    buffer.writeln('TYPE: ${ElementType.cto.key}');
    buffer.writeln('TIMESTAMP: ${dataAtualizacao?.toIso8601String() ?? dataCriacao.toIso8601String()}');
    buffer.writeln('PORTAS: $numeroPortas');
    buffer.writeln('SPLITTER: $tipoSplitter');
    if (numeroCTO != null) buffer.writeln('NUMERO: $numeroCTO');
    if (caboEntradaId != null) buffer.writeln('CABO_ENTRADA: $caboEntradaId');
    if (cabosSaidaIds.isNotEmpty) {
      buffer.writeln('CABOS_SAIDA: ${cabosSaidaIds.join(',')}');
    }
    
    return buffer.toString();
  }

  /// Parse descrição com KEYS de KML
  static Map<String, String> parseKeys(String descricao) {
    final keys = <String, String>{};
    final lines = descricao.split('\n');
    bool inKeysSection = false;
    
    for (final line in lines) {
      if (line.trim() == '--- KEYS ---') {
        inKeysSection = true;
        continue;
      }
      
      if (inKeysSection && line.contains(':')) {
        final parts = line.split(':');
        if (parts.length >= 2) {
          keys[parts[0].trim()] = parts.sublist(1).join(':').trim();
        }
      }
    }
    
    return keys;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'latitude': posicao.latitude,
      'longitude': posicao.longitude,
      'descricao': descricao,
      'numeroPortas': numeroPortas,
      'tipoSplitter': tipoSplitter,
      'numeroCTO': numeroCTO,
      'portas': portas.map((p) => p.toJson()).toList(),
      'caboEntradaId': caboEntradaId,
      'cabosSaidaIds': cabosSaidaIds,
      'dataCriacao': dataCriacao.toIso8601String(),
      'dataAtualizacao': dataAtualizacao?.toIso8601String(),
    };
  }

  factory CTOModel.fromJson(Map<String, dynamic> json) {
    return CTOModel(
      id: json['id'],
      nome: json['nome'],
      posicao: LatLng(json['latitude'], json['longitude']),
      descricao: json['descricao'],
      numeroPortas: json['numeroPortas'],
      tipoSplitter: json['tipoSplitter'],
      numeroCTO: json['numeroCTO'],
      portas: (json['portas'] as List?)
          ?.map((p) => PortaCTO.fromJson(p))
          .toList(),
      caboEntradaId: json['caboEntradaId'],
      cabosSaidaIds: List<String>.from(json['cabosSaidaIds'] ?? []),
      dataCriacao: DateTime.parse(json['dataCriacao']),
      dataAtualizacao: json['dataAtualizacao'] != null
          ? DateTime.parse(json['dataAtualizacao'])
          : null,
    );
  }

  CTOModel copyWith({
    String? nome,
    LatLng? posicao,
    String? descricao,
    int? numeroPortas,
    String? tipoSplitter,
    String? numeroCTO,
    List<PortaCTO>? portas,
    String? caboEntradaId,
    List<String>? cabosSaidaIds,
  }) {
    return CTOModel(
      id: id,
      nome: nome ?? this.nome,
      posicao: posicao ?? this.posicao,
      descricao: descricao ?? this.descricao,
      numeroPortas: numeroPortas ?? this.numeroPortas,
      tipoSplitter: tipoSplitter ?? this.tipoSplitter,
      numeroCTO: numeroCTO ?? this.numeroCTO,
      portas: portas ?? this.portas,
      caboEntradaId: caboEntradaId ?? this.caboEntradaId,
      cabosSaidaIds: cabosSaidaIds ?? this.cabosSaidaIds,
      dataCriacao: dataCriacao,
      dataAtualizacao: DateTime.now(),
    );
  }
}

/// Modelo de porta de CTO
class PortaCTO {
  final int numero;
  final String? observacao;

  PortaCTO({
    required this.numero,
    this.observacao,
  });

  Map<String, dynamic> toJson() {
    return {
      'numero': numero,
      'observacao': observacao,
    };
  }

  factory PortaCTO.fromJson(Map<String, dynamic> json) {
    return PortaCTO(
      numero: json['numero'],
      observacao: json['observacao'],
    );
  }
}
