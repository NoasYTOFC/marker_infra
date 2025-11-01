import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Ferramenta para medir distâncias entre pontos no mapa
class MeasurementTool {
  final List<LatLng> points = [];
  bool isActive = false;

  void addPoint(LatLng point) {
    points.add(point);
  }

  void removeLastPoint() {
    if (points.isNotEmpty) {
      points.removeLast();
    }
  }

  void clear() {
    points.clear();
  }

  void toggle() {
    isActive = !isActive;
    if (!isActive) {
      clear();
    }
  }

  /// Calcula a distância total do percurso
  double getTotalDistance() {
    if (points.length < 2) return 0.0;

    final distance = Distance();
    double total = 0.0;

    for (int i = 0; i < points.length - 1; i++) {
      total += distance.as(LengthUnit.Meter, points[i], points[i + 1]);
    }

    return total;
  }

  /// Calcula distâncias entre cada segmento
  List<double> getSegmentDistances() {
    if (points.length < 2) return [];

    final distance = Distance();
    final segments = <double>[];

    for (int i = 0; i < points.length - 1; i++) {
      segments.add(distance.as(LengthUnit.Meter, points[i], points[i + 1]));
    }

    return segments;
  }

  /// Formata distância para exibição
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(2)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    }
  }

  /// Cria texto de resumo das medições
  String getSummary() {
    if (points.isEmpty) return 'Nenhum ponto marcado';
    if (points.length == 1) return '1 ponto marcado';

    final segments = getSegmentDistances();
    final total = getTotalDistance();

    final buffer = StringBuffer();
    buffer.writeln('${points.length} pontos');
    buffer.writeln('Distância total: ${formatDistance(total)}');
    buffer.writeln('\nSegmentos:');

    for (int i = 0; i < segments.length; i++) {
      buffer.writeln('  ${i + 1}→${i + 2}: ${formatDistance(segments[i])}');
    }

    return buffer.toString();
  }
}

/// Widget de informações da medição
class MeasurementInfo extends StatelessWidget {
  final MeasurementTool tool;
  final VoidCallback onClear;
  final VoidCallback onUndo;

  const MeasurementInfo({
    super.key,
    required this.tool,
    required this.onClear,
    required this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.straighten, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Medição',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.undo),
                      onPressed: tool.points.isNotEmpty ? onUndo : null,
                      tooltip: 'Desfazer último ponto',
                      iconSize: 20,
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: tool.points.isNotEmpty ? onClear : null,
                      tooltip: 'Limpar tudo',
                      iconSize: 20,
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            if (tool.points.isEmpty)
              const Text(
                'Clique no mapa para adicionar pontos',
                style: TextStyle(fontStyle: FontStyle.italic),
              )
            else ...[
              Text('Pontos: ${tool.points.length}'),
              if (tool.points.length >= 2) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Total: ${MeasurementTool.formatDistance(tool.getTotalDistance())}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 8),
            const Text(
              'Dica: Clique no mapa para medir distâncias',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
