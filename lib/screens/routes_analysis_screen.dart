import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/infrastructure_provider.dart';
import '../services/routes_validation_service.dart';
import '../services/analisador_rotas_internas.dart';
import '../widgets/routes_analysis_widgets.dart';
import '../widgets/rotas_internas_widgets.dart';

/// Tela para análise de rotas e validação de conexões
class RoutesAnalysisScreen extends StatefulWidget {
  final String? ceoIdSelecionada;

  const RoutesAnalysisScreen({
    super.key,
    this.ceoIdSelecionada,
  });

  @override
  State<RoutesAnalysisScreen> createState() => _RoutesAnalysisScreenState();
}

class _RoutesAnalysisScreenState extends State<RoutesAnalysisScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<RotaAnalise> rotas = [];
  late RelatorioValidacao relatorio;
  late TextEditingController _filtroController;
  String _filtroPesquisa = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _filtroController = TextEditingController();
    
    // Se veio de um CEO específico, pré-filtrar
    if (widget.ceoIdSelecionada != null) {
      final provider = context.read<InfrastructureProvider>();
      final ceo = provider.getCEO(widget.ceoIdSelecionada!);
      if (ceo != null) {
        _filtroController.text = ceo.nome;
        _filtroPesquisa = ceo.nome.toLowerCase();
      }
    }
    
    _filtroController.addListener(() {
      setState(() {
        _filtroPesquisa = _filtroController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _filtroController.dispose();
    super.dispose();
  }

  void _atualizarAnalise() {
    setState(() {
      // Força atualização dos dados
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Análise de Rotas & Validação'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.route), text: 'Rotas'),
            Tab(icon: Icon(Icons.check_circle), text: 'Validação'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _atualizarAnalise,
            tooltip: 'Atualizar análise',
          ),
        ],
      ),
      body: Consumer<InfrastructureProvider>(
        builder: (context, provider, _) {
          // Gerar rotas
          final rotasAnalise = RoutesValidationService.analisarRotas(
            ctos: provider.ctos,
            ceos: provider.ceos,
            olts: provider.olts,
            cabos: provider.cabos,
          );

          // Gerar relatório de validação
          final relatorioValidacao =
              RoutesValidationService.analisarConexoes(
            ctos: provider.ctos,
            ceos: provider.ceos,
            olts: provider.olts,
            dios: provider.dios,
            cabos: provider.cabos,
          );

          return TabBarView(
            controller: _tabController,
            children: [
              // Aba de Rotas
              _construirAbRotas(rotasAnalise),

              // Aba de Validação
              _construirAbaValidacao(relatorioValidacao),
            ],
          );
        },
      ),
    );
  }

  Widget _construirAbRotas(List<RotaAnalise> rotas) {
    return Consumer<InfrastructureProvider>(
      builder: (context, provider, _) {
        if (provider.ceos.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.hub,
                  size: 64.0,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16.0),
                Text(
                  'Nenhuma CEO encontrada',
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        // Analisar rotas de cada CEO
        final analisesCEO = <AnaliseRotasCEO>[];
        final cabosMap = {for (var cabo in provider.cabos) cabo.id: cabo};

        for (var ceo in provider.ceos) {
          final analise =
              AnalisadorRotasInternas.analisarRotasCEO(ceo, cabosMap);
          if (analise.totalFusoes > 0) {
            analisesCEO.add(analise);
          }
        }

        // Filtrar CEOs por nome
        final analisesFiltradas = _filtroPesquisa.isEmpty
            ? analisesCEO
            : analisesCEO
                .where((a) => a.ceoNome.toLowerCase().contains(_filtroPesquisa))
                .toList();

        if (analisesCEO.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.route,
                  size: 64.0,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16.0),
                Text(
                  'Nenhuma rota encontrada',
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  'Adicione fusões às CEOs para gerar rotas',
                  style: TextStyle(
                    fontSize: 12.0,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        if (analisesFiltradas.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64.0,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16.0),
                Text(
                  'Nenhuma CEO encontrada',
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  'Tente outro nome',
                  style: TextStyle(
                    fontSize: 12.0,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Barra de pesquisa
                _construirBarraPesquisa(analisesCEO.length, analisesFiltradas.length),
                const SizedBox(height: 16.0),

                // Resumo geral
                _construirCartaoResumoGeral(analisesFiltradas),
                const SizedBox(height: 20.0),

                // CEOs expandíveis
                for (var analise in analisesFiltradas)
                  _construirCEOExpandivel(analise),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _construirBarraPesquisa(int totalCeos, int ceosFiltradas) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _filtroController,
          decoration: InputDecoration(
            hintText: 'Buscar CEO por nome...',
            hintStyle: TextStyle(color: Colors.grey[500]),
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _filtroController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _filtroController.clear();
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
          ),
        ),
        if (_filtroPesquisa.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              '$ceosFiltradas de $totalCeos CEO(s)',
              style: TextStyle(
                fontSize: 11.0,
                color: Colors.grey[600],
              ),
            ),
          ),
      ],
    );
  }

  Widget _construirCartaoResumoGeral(List<AnaliseRotasCEO> analises) {
    final totalFusoes = analises.fold<int>(
      0,
      (sum, a) => sum + a.totalFusoes,
    );
    final scoreGeral = analises.isNotEmpty
        ? (analises.fold<int>(0, (sum, a) => sum + a.scoreGeral) /
                analises.length)
            .toInt()
        : 100;

    return Card(
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Resumo Geral de Rotas',
              style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _construirItemResumo(
                  'CEOs',
                  '${analises.length}',
                  Colors.blue,
                  Icons.hub,
                ),
                _construirItemResumo(
                  'Fusões',
                  '$totalFusoes',
                  Colors.purple,
                  Icons.connect_without_contact,
                ),
                _construirItemResumo(
                  'Score',
                  '$scoreGeral',
                  scoreGeral >= 80
                      ? Colors.green
                      : scoreGeral >= 60
                          ? Colors.orange
                          : Colors.red,
                  Icons.grade,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirCEOExpandivel(AnaliseRotasCEO analise) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.blue.withAlpha(30),
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: Icon(
                Icons.hub,
                color: Colors.blue,
                size: 18.0,
              ),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    analise.ceoNome,
                    style: const TextStyle(
                      fontSize: 13.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${analise.fluxos.length} fluxos | ${analise.totalFusoes} fusões',
                    style: TextStyle(
                      fontSize: 11.0,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(30),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Text(
                '${analise.scoreGeral}',
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                  color: analise.scoreGeral >= 80
                      ? Colors.green
                      : analise.scoreGeral >= 60
                          ? Colors.orange
                          : Colors.red,
                ),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabos de entrada
                if (analise.cabosEntrada.isNotEmpty) ...[
                  Text(
                    '� Cabos de Entrada',
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  for (var cabo in analise.cabosEntrada)
                    CaboInfoCardWidget(
                      info: cabo,
                      isEntrada: true,
                    ),
                  const SizedBox(height: 16.0),
                ],

                // Cabos de saída
                if (analise.cabosSaida.isNotEmpty) ...[
                  Text(
                    '📤 Cabos de Saída',
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  for (var cabo in analise.cabosSaida)
                    CaboInfoCardWidget(
                      info: cabo,
                      isEntrada: false,
                    ),
                  const SizedBox(height: 16.0),
                ],

                // Fluxos
                if (analise.fluxos.isNotEmpty) ...[
                  const Divider(),
                  const SizedBox(height: 12.0),
                  Text(
                    '🔄 Fluxos de Rota',
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  for (var fluxo in analise.fluxos)
                    FluxoRotaCardWidget(fluxo: fluxo),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirItemResumo(
    String label,
    String valor,
    Color cor,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: cor, size: 24.0),
        const SizedBox(height: 4.0),
        Text(
          valor,
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            color: cor,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.0,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _construirAbaValidacao(RelatorioValidacao relatorio) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card de resumo
            _construirCartaoValidacaoResumo(relatorio),
            const SizedBox(height: 20.0),

            // Indicador de integridade
            _construirIndicadorIntegridade(relatorio.taxaIntegridade),
            const SizedBox(height: 20.0),

            // Problemas por severidade
            if (relatorio.problemas.isNotEmpty) ...[
              const Text(
                '🔍 Problemas Encontrados',
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12.0),

              // Filtrar por severidade
              for (var severidade in [
                Severidade.critica,
                Severidade.aviso,
                Severidade.info,
              ]) ...[
                if (relatorio.problemas
                    .any((p) => p.severidade == severidade)) ...[
                  _construirSecaoProblemas(
                    relatorio.problemas
                        .where((p) => p.severidade == severidade)
                        .toList(),
                    severidade,
                  ),
                  const SizedBox(height: 12.0),
                ],
              ],
            ] else
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 64.0,
                        color: Colors.green[300],
                      ),
                      const SizedBox(height: 16.0),
                      const Text(
                        'Nenhum problema encontrado!',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w500,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _construirCartaoValidacaoResumo(RelatorioValidacao relatorio) {
    return Card(
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📋 Resumo de Validação',
              style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _construirItemResumo(
                  'Fusões',
                  '${relatorio.totalFusoes}',
                  Colors.blue,
                  Icons.hub,
                ),
                _construirItemResumo(
                  'Com Problema',
                  '${relatorio.fusoesCOMProblemas}',
                  Colors.red,
                  Icons.error,
                ),
                _construirItemResumo(
                  'Taxa OK',
                  '${relatorio.taxaIntegridade.toStringAsFixed(0)}%',
                  Colors.green,
                  Icons.check_circle,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirIndicadorIntegridade(double taxa) {
    final cor = taxa >= 90
        ? Colors.green
        : taxa >= 70
            ? Colors.orange
            : Colors.red;

    return Card(
      elevation: 1.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔒 Taxa de Integridade',
              style: TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12.0),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: LinearProgressIndicator(
                      value: taxa / 100,
                      minHeight: 12.0,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation(cor),
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                Text(
                  '${taxa.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: cor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirSecaoProblemas(
    List<ProblemaConexao> problemas,
    Severidade severidade,
  ) {
    final labels = {
      Severidade.critica: '🔴 Críticos (${problemas.length})',
      Severidade.aviso: '🟡 Avisos (${problemas.length})',
      Severidade.info: '🔵 Informações (${problemas.length})',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labels[severidade] ?? '',
          style: const TextStyle(
            fontSize: 12.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8.0),
        for (var problema in problemas) ProblemaCardWidget(problema: problema),
      ],
    );
  }
}
