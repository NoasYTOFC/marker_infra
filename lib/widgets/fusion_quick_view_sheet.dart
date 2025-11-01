import 'package:flutter/material.dart';
import '../models/ceo_model.dart';
import '../models/cabo_model.dart';
import '../services/fusion_diagram_service.dart';

/// Bottom sheet para visualizar fusões de uma CEO rapidamente
class FusionQuickViewSheet extends StatelessWidget {
  final CEOModel ceo;
  final Map<String, CaboModel> cabosMap;
  final VoidCallback? onViewDetails;
  
  const FusionQuickViewSheet({
    super.key,
    required this.ceo,
    required this.cabosMap,
    this.onViewDetails,
  });
  
  @override
  Widget build(BuildContext context) {
    final fusoes = FusionDiagramService.gerarDiagramaFusoes(ceo, cabosMap);
    final stats = FusionDiagramService.calcularEstatisticas(fusoes);
    
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.only(
          top: 16,
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.hub,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ceo.nome,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${ceo.tipo} • ${fusoes.length}/${ceo.capacidadeFusoes} fusões',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Mini stats
            if (fusoes.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MiniStatItem(
                      label: 'Fusões',
                      value: '${stats['totalFusoes']}',
                      icon: Icons.link,
                    ),
                    _MiniStatItem(
                      label: 'Atenuação',
                      value: '${(stats['atenuacaoMedia'] as double).toStringAsFixed(1)} dB',
                      icon: Icons.signal_cellular_alt,
                    ),
                    _MiniStatItem(
                      label: 'Ocupação',
                      value: '${((fusoes.length / ceo.capacidadeFusoes) * 100).toStringAsFixed(0)}%',
                      icon: Icons.pie_chart,
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Lista de fusões
            if (fusoes.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(
                      Icons.link_off,
                      size: 32,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nenhuma fusão',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Últimas Fusões',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  ...fusoes.take(3).map((fusao) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: fusao.entrada.cor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Fibra ${fusao.entrada.numeroFibra} → ${fusao.saida.numeroFibra}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '${fusao.entrada.caboNome} → ${fusao.saida.caboNome}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (fusao.atenuacao != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withAlpha(30),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                '${fusao.atenuacao!.toStringAsFixed(2)} dB',
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  )),
                  if (fusoes.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '+ ${fusoes.length - 3} mais fusões',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            
            const SizedBox(height: 16),
            
            // Botões de ação
            if (onViewDetails != null) ...[
              ElevatedButton.icon(
                onPressed: onViewDetails,
                icon: const Icon(Icons.open_in_full),
                label: const Text('Ver Diagrama Completo'),
              ),
              const SizedBox(height: 8),
            ],
            
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
              label: const Text('Fechar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  
  const _MiniStatItem({
    required this.label,
    required this.value,
    required this.icon,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
