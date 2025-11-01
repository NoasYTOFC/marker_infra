import 'package:latlong2/latlong.dart';
import 'element_type.dart';

/// Modelo para DIO (Distribuidor Interno Óptico)
/// Usado em POPs, data centers e centrais para organizar conexões de fibra
class DIOModel {
  final String id;
  final String nome;
  final LatLng posicao;
  final String? descricao;

  // Configurações técnicas
  final int numeroPortas;
  final String tipo; // Rack, Parede, etc
  final List<PortaDIO> portas;
  final String? numeroDIO;

  // Conectividade
  final List<String> cabosConectadosIds;

  // Metadata
  final DateTime dataCriacao;
  final DateTime? dataAtualizacao;

  DIOModel({
    required this.id,
    required this.nome,
    required this.posicao,
    this.descricao,
    this.numeroPortas = 24,
    this.tipo = 'Rack',
    List<PortaDIO>? portas,
    this.numeroDIO,
    List<String>? cabosConectadosIds,
    DateTime? dataCriacao,
    this.dataAtualizacao,
  })  : portas = portas ?? _gerarPortasPadrao(numeroPortas),
        cabosConectadosIds = cabosConectadosIds ?? [],
        dataCriacao = dataCriacao ?? DateTime.now();

  static List<PortaDIO> _gerarPortasPadrao(int numeroPortas) {
    return List.generate(
      numeroPortas,
      (i) => PortaDIO(numero: i + 1),
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
    buffer.writeln('TYPE: ${ElementType.dio.key}');
    buffer.writeln('TIMESTAMP: ${dataAtualizacao?.toIso8601String() ?? dataCriacao.toIso8601String()}');
    buffer.writeln('PORTAS: $numeroPortas');
    buffer.writeln('TIPO: $tipo');
    if (numeroDIO != null) buffer.writeln('NUMERO: $numeroDIO');
    buffer.writeln('PORTAS_OCUPADAS: ${portasOcupadas}');

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

  int get portasOcupadas => portas.where((p) => p.ocupada).length;
  int get portasDisponiveis => numeroPortas - portasOcupadas;
  double get percentualOcupacao =>
      numeroPortas > 0 ? (portasOcupadas / numeroPortas * 100) : 0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'latitude': posicao.latitude,
      'longitude': posicao.longitude,
      'descricao': descricao,
      'numeroPortas': numeroPortas,
      'tipo': tipo,
      'portas': portas.map((p) => p.toJson()).toList(),
      'numeroDIO': numeroDIO,
      'cabosConectadosIds': cabosConectadosIds,
      'dataCriacao': dataCriacao.toIso8601String(),
      'dataAtualizacao': dataAtualizacao?.toIso8601String(),
    };
  }

  factory DIOModel.fromJson(Map<String, dynamic> json) {
    return DIOModel(
      id: json['id'],
      nome: json['nome'],
      posicao: LatLng(json['latitude'], json['longitude']),
      descricao: json['descricao'],
      numeroPortas: json['numeroPortas'],
      tipo: json['tipo'],
      portas:
          (json['portas'] as List).map((p) => PortaDIO.fromJson(p)).toList(),
      numeroDIO: json['numeroDIO'],
      cabosConectadosIds: List<String>.from(json['cabosConectadosIds'] ?? []),
      dataCriacao: DateTime.parse(json['dataCriacao']),
      dataAtualizacao: json['dataAtualizacao'] != null
          ? DateTime.parse(json['dataAtualizacao'])
          : null,
    );
  }

  DIOModel copyWith({
    String? nome,
    LatLng? posicao,
    String? descricao,
    int? numeroPortas,
    String? tipo,
    List<PortaDIO>? portas,
    String? numeroDIO,
    List<String>? cabosConectadosIds,
  }) {
    return DIOModel(
      id: id,
      nome: nome ?? this.nome,
      posicao: posicao ?? this.posicao,
      descricao: descricao ?? this.descricao,
      numeroPortas: numeroPortas ?? this.numeroPortas,
      tipo: tipo ?? this.tipo,
      portas: portas ?? this.portas,
      numeroDIO: numeroDIO ?? this.numeroDIO,
      cabosConectadosIds: cabosConectadosIds ?? this.cabosConectadosIds,
      dataCriacao: dataCriacao,
      dataAtualizacao: DateTime.now(),
    );
  }
}

/// Modelo de porta do DIO
class PortaDIO {
  final int numero;
  final bool ocupada;
  final String? caboId;
  final int? fibraNumero;
  final String? destinoId; // ID do equipamento conectado
  final String? conectorTipo; // SC, LC, ST, etc
  final String? observacao;

  PortaDIO({
    required this.numero,
    this.ocupada = false,
    this.caboId,
    this.fibraNumero,
    this.destinoId,
    this.conectorTipo = 'SC/APC',
    this.observacao,
  });

  Map<String, dynamic> toJson() {
    return {
      'numero': numero,
      'ocupada': ocupada,
      'caboId': caboId,
      'fibraNumero': fibraNumero,
      'destinoId': destinoId,
      'conectorTipo': conectorTipo,
      'observacao': observacao,
    };
  }

  factory PortaDIO.fromJson(Map<String, dynamic> json) {
    return PortaDIO(
      numero: json['numero'],
      ocupada: json['ocupada'] ?? false,
      caboId: json['caboId'],
      fibraNumero: json['fibraNumero'],
      destinoId: json['destinoId'],
      conectorTipo: json['conectorTipo'],
      observacao: json['observacao'],
    );
  }

  PortaDIO copyWith({
    bool? ocupada,
    String? caboId,
    int? fibraNumero,
    String? destinoId,
    String? conectorTipo,
    String? observacao,
  }) {
    return PortaDIO(
      numero: numero,
      ocupada: ocupada ?? this.ocupada,
      caboId: caboId ?? this.caboId,
      fibraNumero: fibraNumero ?? this.fibraNumero,
      destinoId: destinoId ?? this.destinoId,
      conectorTipo: conectorTipo ?? this.conectorTipo,
      observacao: observacao ?? this.observacao,
    );
  }
}
