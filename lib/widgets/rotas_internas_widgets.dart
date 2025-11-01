import 'package:flutter/material.dart';
import '../services/analisador_rotas_internas.dart';
import '../services/routes_validation_service.dart';

/// Widget que exibe informações de um cabo (entrada ou saída)
class CaboInfoCardWidget extends StatelessWidget {
  final InfoCaboEntradasaida info;
  final bool isEntrada;

  const CaboInfoCardWidget({
    super.key,
    required this.info,
    required this.isEntrada,
  });

  Color get _corOcupacao {
    if (info.ocupacao < 50) return Colors.green;
    if (info.ocupacao < 80) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com ícone e nome
            Row(
              children: [
                Icon(
                  isEntrada ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isEntrada ? Colors.blue : Colors.purple,
                  size: 18.0,
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEntrada ? 'Entrada' : 'Saída',
                        style: TextStyle(
                          fontSize: 10.0,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        info.caboNome,
                        style: const TextStyle(
                          fontSize: 12.0,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),

            // Informações
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Fibras
                Column(
                  children: [
                    Icon(
                      Icons.fiber_manual_record,
                      size: 14.0,
                      color: _corOcupacao,
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      '${info.fibrasUsadas}',
                      style: TextStyle(
                        fontSize: 11.0,
                        fontWeight: FontWeight.bold,
                        color: _corOcupacao,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    const Text(
                      'Fibras',
                      style: TextStyle(fontSize: 9.0, color: Colors.grey),
                    ),
                  ],
                ),

                // Ocupação
                Column(
                  children: [
                    Icon(
                      Icons.speed,
                      size: 14.0,
                      color: _corOcupacao,
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      info.ocupacao.isFinite ? '${info.ocupacao.toStringAsFixed(0)}%' : '-',
                      style: TextStyle(
                        fontSize: 11.0,
                        fontWeight: FontWeight.bold,
                        color: _corOcupacao,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    const Text(
                      'Ocupação',
                      style: TextStyle(fontSize: 9.0, color: Colors.grey),
                    ),
                  ],
                ),

                // Distância
                Column(
                  children: [
                    const Icon(
                      Icons.straighten,
                      size: 14.0,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      info.distanciaFormatada,
                      style: const TextStyle(
                        fontSize: 11.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    const Text(
                      'Distância',
                      style: TextStyle(fontSize: 9.0, color: Colors.grey),
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

/// Widget que exibe um fluxo de rota
class FluxoRotaCardWidget extends StatelessWidget {
  final FluxoRota fluxo;

  const FluxoRotaCardWidget({
    super.key,
    required this.fluxo,
  });

  Color get _corScore {
    final score = AnalisadorRotasInternas.calcularScoreSaude(fluxo);
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  String get _labelAtenuacao =>
      AnalisadorRotasInternas.avaliarAtenuacao(fluxo.atenuacaoMedia);

  @override
  Widget build(BuildContext context) {
    final score = AnalisadorRotasInternas.calcularScoreSaude(fluxo);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2.0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          border: Border(
            left: BorderSide(
              color: _corScore,
              width: 4.0,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header com score
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fluxo.descricaoCaminho,
                          style: const TextStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          _labelAtenuacao,
                          style: TextStyle(
                            fontSize: 10.0,
                            color: _corScore,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  // Score circular
                  Container(
                    width: 50.0,
                    height: 50.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _corScore.withAlpha(30),
                      border: Border.all(color: _corScore, width: 2.0),
                    ),
                    child: Center(
                      child: Text(
                        '$score',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: _corScore,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12.0),
              const Divider(height: 1.0),
              const SizedBox(height: 12.0),

              // Informações em grid
              GridView(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3.5,
                  mainAxisSpacing: 8.0,
                  crossAxisSpacing: 8.0,
                ),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _InfoItem(
                    label: 'Fusões',
                    valor: '${fluxo.numFusoes}',
                    icon: Icons.hub,
                    cor: Colors.blue,
                  ),
                  _InfoItem(
                    label: 'Fibras',
                    valor: '${fluxo.fibrasUsadas}',
                    icon: Icons.fiber_manual_record,
                    cor: Colors.purple,
                  ),
                  _InfoItem(
                    label: 'Distância',
                    valor: fluxo.distanciaFormatada,
                    icon: Icons.straighten,
                    cor: Colors.orange,
                  ),
                  _InfoItem(
                    label: 'Atenuação',
                    valor: '${fluxo.atenuacaoMedia.toStringAsFixed(2)} dB',
                    icon: Icons.signal_cellular_null,
                    cor: _corScore,
                  ),
                ],
              ),

              const SizedBox(height: 10.0),
              
              // Detalhamento de cabos
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cabos Envolvidos',
                    style: TextStyle(
                      fontSize: 11.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _CaboTag(
                        nome: fluxo.caboEntradaNome,
                        distancia: RoutesValidationService.formatarDistancia(
                          fluxo.distanciaEntrada / 1000,
                        ),
                        isEntrada: true,
                      ),
                      Icon(
                        Icons.arrow_forward,
                        size: 14.0,
                        color: Colors.grey[400],
                      ),
                      _CaboTag(
                        nome: fluxo.caboSaidaNome,
                        distancia: RoutesValidationService.formatarDistancia(
                          fluxo.distanciaSaida / 1000,
                        ),
                        isEntrada: false,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Item de informação para grid
class _InfoItem extends StatelessWidget {
  final String label;
  final String valor;
  final IconData icon;
  final Color cor;

  const _InfoItem({
    required this.label,
    required this.valor,
    required this.icon,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14.0, color: cor),
        const SizedBox(width: 6.0),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 9.0,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                valor,
                style: TextStyle(
                  fontSize: 11.0,
                  fontWeight: FontWeight.bold,
                  color: cor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Tag de cabo com distância
class _CaboTag extends StatelessWidget {
  final String nome;
  final String distancia;
  final bool isEntrada;

  const _CaboTag({
    required this.nome,
    required this.distancia,
    required this.isEntrada,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: isEntrada ? Colors.blue.withAlpha(20) : Colors.purple.withAlpha(20),
          borderRadius: BorderRadius.circular(6.0),
          border: Border.all(
            color: isEntrada ? Colors.blue.withAlpha(100) : Colors.purple.withAlpha(100),
            width: 1.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              nome,
              style: TextStyle(
                fontSize: 9.0,
                fontWeight: FontWeight.bold,
                color: isEntrada ? Colors.blue : Colors.purple,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2.0),
            Text(
              distancia,
              style: TextStyle(
                fontSize: 8.0,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
