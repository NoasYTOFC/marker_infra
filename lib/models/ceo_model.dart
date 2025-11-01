import 'package:latlong2/latlong.dart';
import 'element_type.dart';

/// Modelo para CEO (Caixa de Emenda Óptica)
/// Usada para interconectar cabos de fibra óptica através de fusões
class CEOModel {
  final String id;
  final String nome;
  final LatLng posicao;
  final String? descricao;

  // Configurações técnicas
  final int capacidadeFusoes; // Número máximo de fusões suportadas
  final String tipo; // Aérea, Subterrânea, Poste
  final List<FusaoCEO> fusoes;
  final String? numeroCEO;

  // Conectividade - cabos que entram e saem da CEO
  final List<String> cabosConectadosIds;

  // Metadata
  final DateTime dataCriacao;
  final DateTime? dataAtualizacao;

  CEOModel({
    required this.id,
    required this.nome,
    required this.posicao,
    this.descricao,
    this.capacidadeFusoes = 24,
    this.tipo = 'Aérea',
    List<FusaoCEO>? fusoes,
    this.numeroCEO,
    List<String>? cabosConectadosIds,
    DateTime? dataCriacao,
    this.dataAtualizacao,
  })  : fusoes = fusoes ?? [],
        cabosConectadosIds = cabosConectadosIds ?? [],
        dataCriacao = dataCriacao ?? DateTime.now();

  String gerarDescricaoComKeys() {
    final buffer = StringBuffer();

    // Limpar descrição de keys antigas
    final descricaoLimpa = _removerKeysAntiga(descricao);

    if (descricaoLimpa != null && descricaoLimpa.isNotEmpty) {
      buffer.writeln(descricaoLimpa);
      buffer.writeln();
    }

    buffer.writeln('--- KEYS ---');
    buffer.writeln('TYPE: ${ElementType.ceo.key}');
    buffer.writeln('TIMESTAMP: ${dataAtualizacao?.toIso8601String() ?? dataCriacao.toIso8601String()}');
    buffer.writeln('CAPACIDADE: $capacidadeFusoes');
    buffer.writeln('TIPO: $tipo');
    if (numeroCEO != null) buffer.writeln('NUMERO: $numeroCEO');
    buffer.writeln('FUSOES_ATIVAS: ${fusoes.length}');

    // Adicionar cada fusão como KEY
    for (int i = 0; i < fusoes.length; i++) {
      final fusao = fusoes[i];
      final prefix = 'FUSAO_${i + 1}';
      buffer.writeln('$prefix: ${fusao.caboEntradaId}:${fusao.fibraEntradaNumero}:${fusao.caboSaidaId}:${fusao.fibraSaidaNumero}:${fusao.atenuacao ?? 0}:${fusao.tecnico ?? ""}:${fusao.observacao ?? ""}');
    }

    if (cabosConectadosIds.isNotEmpty) {
      buffer.writeln('CABOS_CONECTADOS: ${cabosConectadosIds.join(',')}');
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

  int get fusoesOcupadas => fusoes.length;
  int get fusoesDisponiveis => capacidadeFusoes - fusoesOcupadas;
  double get percentualOcupacao =>
      capacidadeFusoes > 0 ? (fusoesOcupadas / capacidadeFusoes * 100) : 0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'latitude': posicao.latitude,
      'longitude': posicao.longitude,
      'descricao': descricao,
      'capacidadeFusoes': capacidadeFusoes,
      'tipo': tipo,
      'fusoes': fusoes.map((f) => f.toJson()).toList(),
      'numeroCEO': numeroCEO,
      'cabosConectadosIds': cabosConectadosIds,
      'dataCriacao': dataCriacao.toIso8601String(),
      'dataAtualizacao': dataAtualizacao?.toIso8601String(),
    };
  }

  factory CEOModel.fromJson(Map<String, dynamic> json) {
    return CEOModel(
      id: json['id'],
      nome: json['nome'],
      posicao: LatLng(json['latitude'], json['longitude']),
      descricao: json['descricao'],
      capacidadeFusoes: json['capacidadeFusoes'],
      tipo: json['tipo'],
      fusoes:
          (json['fusoes'] as List).map((f) => FusaoCEO.fromJson(f)).toList(),
      numeroCEO: json['numeroCEO'],
      cabosConectadosIds: List<String>.from(json['cabosConectadosIds'] ?? []),
      dataCriacao: DateTime.parse(json['dataCriacao']),
      dataAtualizacao: json['dataAtualizacao'] != null
          ? DateTime.parse(json['dataAtualizacao'])
          : null,
    );
  }

  CEOModel copyWith({
    String? nome,
    LatLng? posicao,
    String? descricao,
    int? capacidadeFusoes,
    String? tipo,
    List<FusaoCEO>? fusoes,
    String? numeroCEO,
    List<String>? cabosConectadosIds,
  }) {
    return CEOModel(
      id: id,
      nome: nome ?? this.nome,
      posicao: posicao ?? this.posicao,
      descricao: descricao ?? this.descricao,
      capacidadeFusoes: capacidadeFusoes ?? this.capacidadeFusoes,
      tipo: tipo ?? this.tipo,
      fusoes: fusoes ?? this.fusoes,
      numeroCEO: numeroCEO ?? this.numeroCEO,
      cabosConectadosIds: cabosConectadosIds ?? this.cabosConectadosIds,
      dataCriacao: dataCriacao,
      dataAtualizacao: DateTime.now(),
    );
  }
}

/// Modelo de fusão dentro da CEO
class FusaoCEO {
  final String id;
  final String caboEntradaId;
  final int fibraEntradaNumero;
  final String caboSaidaId;
  final int fibraSaidaNumero;
  final double? atenuacao; // dB
  final DateTime dataFusao;
  final String? tecnico;
  final String? observacao;

  FusaoCEO({
    required this.id,
    required this.caboEntradaId,
    required this.fibraEntradaNumero,
    required this.caboSaidaId,
    required this.fibraSaidaNumero,
    this.atenuacao,
    DateTime? dataFusao,
    this.tecnico,
    this.observacao,
  }) : dataFusao = dataFusao ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caboEntradaId': caboEntradaId,
      'fibraEntradaNumero': fibraEntradaNumero,
      'caboSaidaId': caboSaidaId,
      'fibraSaidaNumero': fibraSaidaNumero,
      'atenuacao': atenuacao,
      'dataFusao': dataFusao.toIso8601String(),
      'tecnico': tecnico,
      'observacao': observacao,
    };
  }

  factory FusaoCEO.fromJson(Map<String, dynamic> json) {
    final atenuacaoRaw = json['atenuacao']?.toDouble();
    final atenuacao = atenuacaoRaw != null ? atenuacaoRaw.abs() : null;
    
    return FusaoCEO(
      id: json['id'],
      caboEntradaId: json['caboEntradaId'],
      fibraEntradaNumero: json['fibraEntradaNumero'],
      caboSaidaId: json['caboSaidaId'],
      fibraSaidaNumero: json['fibraSaidaNumero'],
      atenuacao: atenuacao,
      dataFusao: DateTime.parse(json['dataFusao']),
      tecnico: json['tecnico'],
      observacao: json['observacao'],
    );
  }
}
