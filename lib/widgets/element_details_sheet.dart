import 'package:flutter/material.dart';
import '../models/cto_model.dart';
import '../models/cabo_model.dart';
import '../models/olt_model.dart';
import '../models/ceo_model.dart';
import '../models/dio_model.dart';
import '../screens/fusion_diagram_screen.dart';

/// Bottom sheet com detalhes formatados de elementos
class ElementDetailsSheet {
  static void showCTO(BuildContext context, CTOModel cto, {
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    VoidCallback? onNavigate,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.router, color: Colors.green, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CTO',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          cto.nome,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Informações principais
              _buildInfoCard(
                'Configuração',
                [
                  if (cto.numeroCTO != null) _InfoRow('Número', cto.numeroCTO!),
                  _InfoRow('Portas Totais', '${cto.numeroPortas}'),
                  _InfoRow('Configuração', _formatCTOConfig(cto)),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Localização
              _buildInfoCard(
                'Localização',
                [
                  _InfoRow('Latitude', cto.posicao.latitude.toStringAsFixed(6)),
                  _InfoRow('Longitude', cto.posicao.longitude.toStringAsFixed(6)),
                ],
              ),
              
              if (cto.descricao != null && cto.descricao!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildInfoCard('Descrição', [
                  _InfoRow('', cto.descricao!),
                ]),
              ],
              
              const SizedBox(height: 24),
              
              // Botões de ação
              Row(
                children: [
                  if (onNavigate != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onNavigate,
                        icon: const Icon(Icons.location_on),
                        label: const Text('Ver no Mapa'),
                      ),
                    ),
                  if (onNavigate != null && onEdit != null) const SizedBox(width: 8),
                  if (onEdit != null)
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit),
                        label: const Text('Editar'),
                      ),
                    ),
                  if (onEdit != null && onDelete != null) const SizedBox(width: 8),
                  if (onDelete != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete),
                        label: const Text('Excluir'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showOLT(BuildContext context, OLTModel olt, {
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    VoidCallback? onNavigate,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.dns, color: Colors.red, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'OLT',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          olt.nome,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              _buildInfoCard(
                'Configuração',
                [
                  if (olt.ipAddress != null) _InfoRow('IP', olt.ipAddress!),
                  _InfoRow('Slots', '${olt.numeroSlots}'),
                  _InfoRow('Total PONs', '${olt.totalPONs}'),
                  if (olt.fabricante != null) _InfoRow('Fabricante', olt.fabricante!),
                  if (olt.modelo != null) _InfoRow('Modelo', olt.modelo!),
                ],
              ),
              
              const SizedBox(height: 16),
              
              _buildInfoCard(
                'Localização',
                [
                  _InfoRow('Latitude', olt.posicao.latitude.toStringAsFixed(6)),
                  _InfoRow('Longitude', olt.posicao.longitude.toStringAsFixed(6)),
                ],
              ),
              
              if (olt.descricao != null && olt.descricao!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildInfoCard('Descrição', [
                  _InfoRow('', olt.descricao!),
                ]),
              ],
              
              const SizedBox(height: 24),
              
              Row(
                children: [
                  if (onNavigate != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onNavigate,
                        icon: const Icon(Icons.location_on),
                        label: const Text('Ver no Mapa'),
                      ),
                    ),
                  if (onNavigate != null && onEdit != null) const SizedBox(width: 8),
                  if (onEdit != null)
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit),
                        label: const Text('Editar'),
                      ),
                    ),
                  if (onEdit != null && onDelete != null) const SizedBox(width: 8),
                  if (onDelete != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete),
                        label: const Text('Excluir'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showCabo(BuildContext context, CaboModel cabo, {
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    VoidCallback? onNavigate,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cabo.configuracao.cor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.cable, color: cabo.configuracao.cor, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CABO',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          cabo.nome,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              _buildInfoCard(
                'Configuração',
                [
                  _InfoRow('Fibras', '${cabo.configuracao.totalFibras}FO'),
                  _InfoRow('Tubos', '${cabo.configuracao.numeroTubos}'),
                  _InfoRow('Tipo', cabo.tipoInstalacao),
                  _InfoRow('Distância', '${cabo.calcularMetragem().toStringAsFixed(2)} m'),
                  _InfoRow('Pontos', '${cabo.rota.length}'),
                ],
              ),
              
              if (cabo.descricao != null && cabo.descricao!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildInfoCard('Descrição', [
                  _InfoRow('', cabo.descricao!),
                ]),
              ],
              
              const SizedBox(height: 24),
              
              Row(
                children: [
                  if (onNavigate != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onNavigate,
                        icon: const Icon(Icons.location_on),
                        label: const Text('Ver no Mapa'),
                      ),
                    ),
                  if (onNavigate != null && onEdit != null) const SizedBox(width: 8),
                  if (onEdit != null)
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit),
                        label: const Text('Editar'),
                      ),
                    ),
                  if (onEdit != null && onDelete != null) const SizedBox(width: 8),
                  if (onDelete != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete),
                        label: const Text('Excluir'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildInfoCard(String title, List<_InfoRow> rows) {
    return Card(
      elevation: 0,
      color: Colors.grey.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...rows.map((row) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: row.label.isEmpty
                  ? Text(
                      row.value,
                      style: const TextStyle(fontSize: 14),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          row.label,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Flexible(
                          child: Text(
                            row.value,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
            )),
          ],
        ),
      ),
    );
  }

  static void showCEO(BuildContext context, CEOModel ceo, {
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    VoidCallback? onNavigate,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.settings_ethernet, color: Colors.orange, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('CEO', style: TextStyle(fontSize: 14, color: Colors.grey)),
                        Text(
                          ceo.nome,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              _buildInfoCard(
                'Configuração',
                [
                  if (ceo.numeroCEO != null) _InfoRow('Número', ceo.numeroCEO!),
                  _InfoRow('Capacidade', '${ceo.capacidadeFusoes} fusões'),
                  _InfoRow('Tipo', ceo.tipo),
                  _InfoRow('Fusões Ativas', '${ceo.fusoesOcupadas}'),
                  _InfoRow('Disponíveis', '${ceo.fusoesDisponiveis}'),
                  _InfoRow('Ocupação', '${ceo.percentualOcupacao.toStringAsFixed(1)}%'),
                ],
              ),
              
              const SizedBox(height: 16),
              
              _buildInfoCard(
                'Localização',
                [
                  _InfoRow('Latitude', ceo.posicao.latitude.toStringAsFixed(6)),
                  _InfoRow('Longitude', ceo.posicao.longitude.toStringAsFixed(6)),
                ],
              ),
              
              if (ceo.descricao != null && ceo.descricao!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildInfoCard('Descrição', [
                  _InfoRow('', ceo.descricao!),
                ]),
              ],
              
              const SizedBox(height: 24),
              
              // Botão para ver diagrama de fusões
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => FusionDiagramScreen(ceoId: ceo.id),
                    ),
                  );
                },
                icon: const Icon(Icons.hub),
                label: const Text('Diagrama de Fusões'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Row(
                children: [
                  if (onNavigate != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onNavigate,
                        icon: const Icon(Icons.location_on),
                        label: const Text('Ver no Mapa'),
                      ),
                    ),
                  if (onNavigate != null && onEdit != null) const SizedBox(width: 8),
                  if (onEdit != null)
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit),
                        label: const Text('Editar'),
                      ),
                    ),
                ],
              ),
              
              if (onDelete != null) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete),
                  label: const Text('Excluir'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static void showDIO(BuildContext context, DIOModel dio, {
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    VoidCallback? onNavigate,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.hub, color: Colors.purple, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('DIO', style: TextStyle(fontSize: 14, color: Colors.grey)),
                        Text(
                          dio.nome,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              _buildInfoCard(
                'Configuração',
                [
                  if (dio.numeroDIO != null) _InfoRow('Número', dio.numeroDIO!),
                  _InfoRow('Portas', '${dio.numeroPortas}'),
                  _InfoRow('Tipo', dio.tipo),
                  _InfoRow('Portas Ocupadas', '${dio.portasOcupadas}'),
                  _InfoRow('Disponíveis', '${dio.portasDisponiveis}'),
                  _InfoRow('Ocupação', '${dio.percentualOcupacao.toStringAsFixed(1)}%'),
                ],
              ),
              
              const SizedBox(height: 16),
              
              _buildInfoCard(
                'Localização',
                [
                  _InfoRow('Latitude', dio.posicao.latitude.toStringAsFixed(6)),
                  _InfoRow('Longitude', dio.posicao.longitude.toStringAsFixed(6)),
                ],
              ),
              
              if (dio.descricao != null && dio.descricao!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildInfoCard('Descrição', [
                  _InfoRow('', dio.descricao!),
                ]),
              ],
              
              const SizedBox(height: 24),
              
              Row(
                children: [
                  if (onNavigate != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onNavigate,
                        icon: const Icon(Icons.location_on),
                        label: const Text('Ver no Mapa'),
                      ),
                    ),
                  if (onNavigate != null && onEdit != null) const SizedBox(width: 8),
                  if (onEdit != null)
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit),
                        label: const Text('Editar'),
                      ),
                    ),
                ],
              ),
              
              if (onDelete != null) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete),
                  label: const Text('Excluir'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _formatCTOConfig(CTOModel cto) {
    // Extrair número de portas por splitter do formato "1:X"
    final splitterParts = cto.tipoSplitter.split(':');
    if (splitterParts.length == 2) {
      final portasPorSplitter = int.tryParse(splitterParts[1]) ?? 8;
      final numeroSplitters = (cto.numeroPortas / portasPorSplitter).ceil();
      
      return '$numeroSplitters:$portasPorSplitter ($numeroSplitters ${numeroSplitters == 1 ? "splitter" : "splitters"} × $portasPorSplitter portas)';
    }
    
    return cto.tipoSplitter;
  }
}

class _InfoRow {
  final String label;
  final String value;
  
  _InfoRow(this.label, this.value);
}
