import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/infrastructure_provider.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InfrastructureProvider>();
    final stats = provider.getStatistics();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSummaryCard(stats),
        const SizedBox(height: 16),
        _buildCabosCard(stats),
      ],
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumo Geral',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.router,
                  label: 'CTOs',
                  value: '${stats['totalCTOs']}',
                  color: Colors.green,
                ),
                _buildStatItem(
                  icon: Icons.dns,
                  label: 'OLTs',
                  value: '${stats['totalOLTs']}',
                  color: Colors.red,
                ),
                _buildStatItem(
                  icon: Icons.settings_ethernet,
                  label: 'CEOs',
                  value: '${stats['totalCEOs']}',
                  color: Colors.orange,
                ),
                _buildStatItem(
                  icon: Icons.hub,
                  label: 'DIOs',
                  value: '${stats['totalDIOs']}',
                  color: Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildCabosCard(Map<String, dynamic> stats) {
    final totalCabos = stats['totalCabos'] as int;
    final metragem = stats['totalMetragemCabos'] as double;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cabos de Fibra',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Icon(Icons.cable, size: 48, color: Colors.blue),
                    const SizedBox(height: 8),
                    Text(
                      '$totalCabos',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Cabos',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Icon(Icons.straighten, size: 48, color: Colors.blue),
                    const SizedBox(height: 8),
                    Text(
                      '${metragem.toStringAsFixed(0)}m',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Metragem Total',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
