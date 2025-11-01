/// Utilitários para formatação e parsing de dados
class FormatUtils {
  /// Normaliza input numérico: converte vírgula em ponto
  /// Entrada: "0,3" ou "0.3"
  /// Saída: "0.3"
  static String normalizeNumericInput(String input) {
    return input.replaceAll(',', '.');
  }

  /// Parse de double com suporte a vírgula
  /// Entrada: "0,3" ou "0.3"
  /// Retorna: 0.3 ou null se inválido
  static double? parseDouble(String? input) {
    if (input == null || input.isEmpty) return null;
    final normalized = normalizeNumericInput(input);
    return double.tryParse(normalized);
  }

  /// Parse de int com suporte a vírgula (trunca decimais)
  /// Entrada: "5,0" ou "5.0" ou "5"
  /// Retorna: 5 ou null se inválido
  static int? parseInt(String? input) {
    if (input == null || input.isEmpty) return null;
    final normalized = normalizeNumericInput(input);
    return int.tryParse(normalized) ?? double.tryParse(normalized)?.toInt();
  }
}
