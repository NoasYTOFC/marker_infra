import 'package:latlong2/latlong.dart';
import 'element_type.dart';

/// Modelo para OLT (Optical Line Terminal)
class OLTModel {
  final String id;
  final String nome;
  final LatLng posicao;
  final String? descricao;

  // Configurações técnicas
  final String? ipAddress;
  final int numeroSlots;
  final List<SlotOLT> slots;
  final String? fabricante;
  final String? modelo;

  // Conectividade
  final List<String> cabosConectadosIds;

  // Metadata
  final DateTime dataCriacao;
  final DateTime? dataAtualizacao;

  OLTModel({
    required this.id,
    required this.nome,
    required this.posicao,
    this.descricao,
    this.ipAddress,
    required this.numeroSlots,
    List<SlotOLT>? slots,
    this.fabricante,
    this.modelo,
    List<String>? cabosConectadosIds,
    DateTime? dataCriacao,
    this.dataAtualizacao,
  })  : slots = slots ?? _gerarSlotsPadrao(numeroSlots),
        cabosConectadosIds = cabosConectadosIds ?? [],
        dataCriacao = dataCriacao ?? DateTime.now();

  static List<SlotOLT> _gerarSlotsPadrao(int numeroSlots) {
    return List.generate(
      numeroSlots,
      (i) => SlotOLT(
        numero: i + 1,
        numeroPONs: 16, // Padrão 16 PONs por slot
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
    buffer.writeln('TYPE: ${ElementType.olt.key}');
    buffer.writeln('TIMESTAMP: ${dataAtualizacao?.toIso8601String() ?? dataCriacao.toIso8601String()}');
    if (ipAddress != null) buffer.writeln('IP: $ipAddress');
    buffer.writeln('SLOTS: $numeroSlots');
    if (fabricante != null) buffer.writeln('FABRICANTE: $fabricante');
    if (modelo != null) buffer.writeln('MODELO: $modelo');

    // Informações dos slots
    for (final slot in slots) {
      buffer.writeln('SLOT_${slot.numero}_PONS: ${slot.numeroPONs}');
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

  int get totalPONs => slots.fold(0, (sum, slot) => sum + slot.numeroPONs);

  int get ponsOcupados => slots.fold(
      0, (sum, slot) => sum + slot.pons.where((p) => p.emUso).length);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'latitude': posicao.latitude,
      'longitude': posicao.longitude,
      'descricao': descricao,
      'ipAddress': ipAddress,
      'numeroSlots': numeroSlots,
      'slots': slots.map((s) => s.toJson()).toList(),
      'fabricante': fabricante,
      'modelo': modelo,
      'cabosConectadosIds': cabosConectadosIds,
      'dataCriacao': dataCriacao.toIso8601String(),
      'dataAtualizacao': dataAtualizacao?.toIso8601String(),
    };
  }

  factory OLTModel.fromJson(Map<String, dynamic> json) {
    return OLTModel(
      id: json['id'],
      nome: json['nome'],
      posicao: LatLng(json['latitude'], json['longitude']),
      descricao: json['descricao'],
      ipAddress: json['ipAddress'],
      numeroSlots: json['numeroSlots'],
      slots: (json['slots'] as List).map((s) => SlotOLT.fromJson(s)).toList(),
      fabricante: json['fabricante'],
      modelo: json['modelo'],
      cabosConectadosIds: List<String>.from(json['cabosConectadosIds'] ?? []),
      dataCriacao: DateTime.parse(json['dataCriacao']),
      dataAtualizacao: json['dataAtualizacao'] != null
          ? DateTime.parse(json['dataAtualizacao'])
          : null,
    );
  }

  OLTModel copyWith({
    String? nome,
    LatLng? posicao,
    String? descricao,
    String? ipAddress,
    int? numeroSlots,
    List<SlotOLT>? slots,
    String? fabricante,
    String? modelo,
    List<String>? cabosConectadosIds,
  }) {
    return OLTModel(
      id: id,
      nome: nome ?? this.nome,
      posicao: posicao ?? this.posicao,
      descricao: descricao ?? this.descricao,
      ipAddress: ipAddress ?? this.ipAddress,
      numeroSlots: numeroSlots ?? this.numeroSlots,
      slots: slots ?? this.slots,
      fabricante: fabricante ?? this.fabricante,
      modelo: modelo ?? this.modelo,
      cabosConectadosIds: cabosConectadosIds ?? this.cabosConectadosIds,
      dataCriacao: dataCriacao,
      dataAtualizacao: DateTime.now(),
    );
  }
}

/// Modelo de slot da OLT
class SlotOLT {
  final int numero;
  final int numeroPONs;
  final List<PONOLT> pons;
  final String? modelo;
  final bool ativo;

  SlotOLT({
    required this.numero,
    required this.numeroPONs,
    List<PONOLT>? pons,
    this.modelo,
    this.ativo = true,
  }) : pons = pons ?? _gerarPONsPadrao(numeroPONs);

  static List<PONOLT> _gerarPONsPadrao(int numeroPONs) {
    return List.generate(
      numeroPONs,
      (i) => PONOLT(numero: i + 1),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'numero': numero,
      'numeroPONs': numeroPONs,
      'pons': pons.map((p) => p.toJson()).toList(),
      'modelo': modelo,
      'ativo': ativo,
    };
  }

  factory SlotOLT.fromJson(Map<String, dynamic> json) {
    return SlotOLT(
      numero: json['numero'],
      numeroPONs: json['numeroPONs'],
      pons: (json['pons'] as List).map((p) => PONOLT.fromJson(p)).toList(),
      modelo: json['modelo'],
      ativo: json['ativo'] ?? true,
    );
  }
}

/// Modelo de PON (Passive Optical Network)
class PONOLT {
  final int numero;
  final bool emUso;
  final String? ctoId;
  final int? vlan;
  final String? potenciaRx; // Potência recebida
  final String? observacao;

  PONOLT({
    required this.numero,
    this.emUso = false,
    this.ctoId,
    this.vlan,
    this.potenciaRx,
    this.observacao,
  });

  Map<String, dynamic> toJson() {
    return {
      'numero': numero,
      'emUso': emUso,
      'ctoId': ctoId,
      'vlan': vlan,
      'potenciaRx': potenciaRx,
      'observacao': observacao,
    };
  }

  factory PONOLT.fromJson(Map<String, dynamic> json) {
    return PONOLT(
      numero: json['numero'],
      emUso: json['emUso'] ?? false,
      ctoId: json['ctoId'],
      vlan: json['vlan'],
      potenciaRx: json['potenciaRx'],
      observacao: json['observacao'],
    );
  }

  PONOLT copyWith({
    bool? emUso,
    String? ctoId,
    int? vlan,
    String? potenciaRx,
    String? observacao,
  }) {
    return PONOLT(
      numero: numero,
      emUso: emUso ?? this.emUso,
      ctoId: ctoId ?? this.ctoId,
      vlan: vlan ?? this.vlan,
      potenciaRx: potenciaRx ?? this.potenciaRx,
      observacao: observacao ?? this.observacao,
    );
  }
}
