import 'package:flutter/material.dart';
import '../services/routes_validation_service.dart';

/// Widget que exibe uma rota com distâncias e validação
class RotaCardWidget extends StatelessWidget {
  final RotaAnalise rota;

  const RotaCardWidget({
    super.key,
    required this.rota,
  });

  Color get _corStatus {
    return rota.valida ? Colors.green : Colors.red;
  }

  IconData get _iconStatus {
    return rota.valida ? Icons.check_circle : Icons.cancel;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
      elevation: 2.0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: _corStatus.withAlpha(100),
            width: 1.0,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header com status
              Row(
                children: [
                  Icon(
                    _iconStatus,
                    color: _corStatus,
                    size: 24.0,
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rota.descricaoCaminho,
                          style: const TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          rota.valida ? 'Rota Válida' : 'Rota Inválida',
                          style: TextStyle(
                            fontSize: 11.0,
                            color: _corStatus,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12.0),
              const Divider(height: 1.0),
              const SizedBox(height: 12.0),

              // Informações de distância e fusões
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Distância
                  Column(
                    children: [
                      Icon(
                        Icons.straighten,
                        size: 20.0,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        RoutesValidationService.formatarDistancia(
                          rota.distanciaTotal,
                        ),
                        style: const TextStyle(
                          fontSize: 13.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      const Text(
                        'Distância',
                        style: TextStyle(
                          fontSize: 10.0,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  // Fusões
                  Column(
                    children: [
                      Icon(
                        Icons.hub,
                        size: 20.0,
                        color: Colors.purple,
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        '${rota.numFusoes}',
                        style: const TextStyle(
                          fontSize: 13.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      const Text(
                        'Fusões',
                        style: TextStyle(
                          fontSize: 10.0,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  // Pontos intermediários
                  Column(
                    children: [
                      Icon(
                        Icons.route,
                        size: 20.0,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        '${rota.ceosIntermediarias.length}',
                        style: const TextStyle(
                          fontSize: 13.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      const Text(
                        'CEOs',
                        style: TextStyle(
                          fontSize: 10.0,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // CEOs intermediárias se houver
              if (rota.ceosIntermediarias.isNotEmpty) ...[
                const SizedBox(height: 12.0),
                const Divider(height: 1.0),
                const SizedBox(height: 12.0),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: [
                    for (var ceo in rota.ceosIntermediarias)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10.0,
                          vertical: 6.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withAlpha(30),
                          borderRadius: BorderRadius.circular(6.0),
                          border: Border.all(
                            color: Colors.orange.withAlpha(100),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.hub,
                              size: 12.0,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 4.0),
                            Text(
                              ceo.nome,
                              style: const TextStyle(
                                fontSize: 10.0,
                                color: Colors.orange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget que exibe um problema de validação
class ProblemaCardWidget extends StatelessWidget {
  final ProblemaConexao problema;

  const ProblemaCardWidget({
    super.key,
    required this.problema,
  });

  Color get _corSeveridade {
    switch (problema.severidade) {
      case Severidade.info:
        return Colors.blue;
      case Severidade.aviso:
        return Colors.orange;
      case Severidade.critica:
        return Colors.red;
    }
  }

  IconData get _iconSeveridade {
    switch (problema.severidade) {
      case Severidade.info:
        return Icons.info;
      case Severidade.aviso:
        return Icons.warning;
      case Severidade.critica:
        return Icons.error;
    }
  }

  String get _labelSeveridade {
    switch (problema.severidade) {
      case Severidade.info:
        return 'Informação';
      case Severidade.aviso:
        return 'Aviso';
      case Severidade.critica:
        return 'Crítico';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      elevation: 1.0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          border: Border(
            left: BorderSide(
              color: _corSeveridade,
              width: 4.0,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _iconSeveridade,
                    color: _corSeveridade,
                    size: 20.0,
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          problema.elementoNome,
                          style: const TextStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          _labelSeveridade,
                          style: TextStyle(
                            fontSize: 10.0,
                            color: _corSeveridade,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Text(
                problema.descricao,
                style: TextStyle(
                  fontSize: 11.0,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
