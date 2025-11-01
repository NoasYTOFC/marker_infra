/// Modelo para representar uma conexão entre CEO e CTO
/// Simplificado: apenas registra que existe uma ligação entre dois elementos
class ConexaoCEOCTO {
  final String ceoId; // ID do CEO (caixa de emenda)
  final String ctoId; // ID do CTO (caixa de terminação)

  ConexaoCEOCTO({
    required this.ceoId,
    required this.ctoId,
  });

  Map<String, dynamic> toJson() {
    return {
      'ceoId': ceoId,
      'ctoId': ctoId,
    };
  }

  factory ConexaoCEOCTO.fromJson(Map<String, dynamic> json) {
    return ConexaoCEOCTO(
      ceoId: json['ceoId'],
      ctoId: json['ctoId'],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConexaoCEOCTO &&
          runtimeType == other.runtimeType &&
          ceoId == other.ceoId &&
          ctoId == other.ctoId;

  @override
  int get hashCode => ceoId.hashCode ^ ctoId.hashCode;
}

/// Serviço para gerenciar conexões CEO-CTO
class GerenciadorConexoes {
  /// Remove a seção completa de KEYS da descrição (para limpeza de dados antigos)
  static String? removerSecaoCompleteKeys(String? descricao) {
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
        // Se é uma key (tem :), pula
        if (line.trim().contains(':') && line.trim().isNotEmpty) {
          continue;
        }
        // Se é uma linha vazia e estávamos em keys, continua fora de keys
        if (line.trim().isEmpty) {
          inKeysSection = false;
        }
      }

      result.add(line);
    }

    // Remove linhas vazias no final
    while (result.isNotEmpty && result.last.trim().isEmpty) {
      result.removeLast();
    }

    return result.join('\n');
  }
}
