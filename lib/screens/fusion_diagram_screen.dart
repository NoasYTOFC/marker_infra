import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import '../providers/infrastructure_provider.dart';
import '../models/ceo_model.dart';
import '../services/fusion_diagram_service.dart';
import '../widgets/fusion_diagram_widget.dart';
import '../utils/format_utils.dart';
import 'routes_analysis_screen.dart';

/// Tela para visualizar e gerenciar fusões de uma CEO
class FusionDiagramScreen extends StatefulWidget {
  final String ceoId;
  
  const FusionDiagramScreen({
    super.key,
    required this.ceoId,
  });
  
  @override
  State<FusionDiagramScreen> createState() => _FusionDiagramScreenState();
}

class _FusionDiagramScreenState extends State<FusionDiagramScreen> {
  String? _selectedFusionId;
  bool _showStats = true;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Diagrama de Fusões'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RoutesAnalysisScreen(
                    ceoIdSelecionada: widget.ceoId,
                  ),
                ),
              );
            },
            tooltip: 'Análise desta CEO',
          ),
          IconButton(
            icon: Icon(_showStats ? Icons.bar_chart_outlined : Icons.bar_chart),
            onPressed: () {
              setState(() => _showStats = !_showStats);
            },
            tooltip: 'Alternar estatísticas',
          ),
        ],
      ),
      body: Consumer<InfrastructureProvider>(
        builder: (context, provider, _) {
          final ceo = provider.getCEO(widget.ceoId);
          
          if (ceo == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48.0, color: Colors.red),
                  const SizedBox(height: 16.0),
                  const Text('CEO não encontrada'),
                  const SizedBox(height: 24.0),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Voltar'),
                  ),
                ],
              ),
            );
          }
          
          // Gerar diagrama
          final cabosMap = {for (var cabo in provider.cabos) cabo.id: cabo};
          final fusoes = FusionDiagramService.gerarDiagramaFusoes(ceo, cabosMap);
          final stats = FusionDiagramService.calcularEstatisticas(fusoes);
          
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header com informações da CEO
                  _CEOHeaderWidget(ceo: ceo),
                  const SizedBox(height: 16.0),
                  
                  // Estatísticas
                  if (_showStats)
                    Column(
                      children: [
                        FusionStatisticsWidget(stats: stats),
                        const SizedBox(height: 16.0),
                      ],
                    ),
                  
                  // Lista de fusões
                  if (fusoes.isEmpty)
                    _EmptyFusionStateWidget(ceoNome: ceo.nome)
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            'Fusões Ativas (${fusoes.length})',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ...fusoes.map((fusao) => FusaoDiagramWidget(
                          fusao: fusao,
                          isSelected: _selectedFusionId == fusao.id,
                          onTap: () {
                            setState(() {
                              _selectedFusionId = _selectedFusionId == fusao.id
                                  ? null
                                  : fusao.id;
                            });
                          },
                          onEdit: () {
                            _abrirFormularioFusao(context, ceo, fusao.id);
                          },
                          onDelete: () {
                            _mostrarConfirmacaoDelecao(context, ceo, fusao.id);
                          },
                        )),
                      ],
                    ),
                  
                  const SizedBox(height: 24.0),
                  
                  // Botão para adicionar nova fusão
                  ElevatedButton.icon(
                    onPressed: () {
                      _abrirFormularioFusao(context, ceo);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar Fusão'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: 16.0),
                  
                  // Botão para voltar
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Voltar'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  void _abrirFormularioFusao(BuildContext context, CEOModel ceo, [String? fusaoId]) {
    showDialog(
      context: context,
      builder: (context) => _FormularioFusaoDialog(ceo: ceo, fusaoId: fusaoId),
    );
  }
  
  void _mostrarConfirmacaoDelecao(
    BuildContext context,
    CEOModel ceo,
    String fusaoId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deletar Fusão?'),
        content: const Text('Tem certeza que deseja remover esta fusão?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              context.read<InfrastructureProvider>().deletarFusao(ceo.id, fusaoId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fusão deletada')),
              );
            },
            child: const Text('Deletar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

/// Header mostrando informações da CEO
class _CEOHeaderWidget extends StatelessWidget {
  final CEOModel ceo;
  
  const _CEOHeaderWidget({required this.ceo});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.blue.withAlpha(20),
        border: Border.all(color: Colors.blue),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.hub,
              color: Colors.white,
              size: 24.0,
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ceo.nome,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '${ceo.tipo} • Cap: ${ceo.capacidadeFusoes}',
                      style: TextStyle(
                        fontSize: 12.0,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (ceo.numeroCEO != null)
                      Text(
                        ' • ${ceo.numeroCEO}',
                        style: TextStyle(
                          fontSize: 12.0,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Text(
              '${ceo.fusoes.length}/${ceo.capacidadeFusoes}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// State vazio quando não há fusões
class _EmptyFusionStateWidget extends StatelessWidget {
  final String ceoNome;
  
  const _EmptyFusionStateWidget({required this.ceoNome});
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.link_off,
                size: 48.0,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 16.0),
            Text(
              'Nenhuma fusão em $ceoNome',
              style: TextStyle(
                fontSize: 16.0,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Adicione a primeira fusão para começar',
              style: TextStyle(
                fontSize: 12.0,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Diálogo para criar/editar fusão
class _FormularioFusaoDialog extends StatefulWidget {
  final CEOModel ceo;
  final String? fusaoId;
  
  const _FormularioFusaoDialog({
    required this.ceo,
    this.fusaoId,
  });
  
  @override
  State<_FormularioFusaoDialog> createState() => _FormularioFusaoDialogState();
}

class _FormularioFusaoDialogState extends State<_FormularioFusaoDialog> {
  late int _fibraEntrada;
  late int _fibraSaida;
  late String _caboEntradaId;
  late String _caboSaidaId;
  String? _tecnico;
  String? _observacao;
  double? _atenuacao;
  
  final _formKey = GlobalKey<FormState>();
  
  @override
  void initState() {
    super.initState();
    
    // Se for edição, carrega os dados da fusão
    if (widget.fusaoId != null) {
      FusaoCEO? fusao;
      try {
        fusao = widget.ceo.fusoes.firstWhere(
          (f) => f.id == widget.fusaoId,
        );
      } catch (e) {
        fusao = null;
      }
      
      if (fusao != null) {
        _fibraEntrada = fusao.fibraEntradaNumero;
        _fibraSaida = fusao.fibraSaidaNumero;
        _caboEntradaId = fusao.caboEntradaId;
        _caboSaidaId = fusao.caboSaidaId;
        _tecnico = fusao.tecnico;
        _observacao = fusao.observacao;
        _atenuacao = fusao.atenuacao;
      }
    } else {
      // Se for criação, valores padrão
      _fibraEntrada = 1;
      _fibraSaida = 1;
      _caboEntradaId = '';
      _caboSaidaId = '';
      _tecnico = null;
      _observacao = null;
      _atenuacao = null;
    }
  }
  
  /// Converte graus para radianos
  double _degToRad(double degrees) {
    return degrees * (math.pi / 180.0);
  }
  
  @override
  Widget build(BuildContext context) {
    final provider = context.read<InfrastructureProvider>();
    
    // Filtrar apenas cabos próximos à CEO (distância máxima de 50 metros)
    final cabosProximos = provider.cabos.where((cabo) {
      // Verifica se o cabo tem pontos na rota
      if (cabo.rota.isEmpty || cabo.rota.length < 2) {
        debugPrint('⚠️ Cabo ${cabo.nome}: Rota vazia ou muito pequena (${cabo.rota.length} pontos)');
        return false;
      }
      
      // Calcula distância dos pontos interpolados do cabo até a CEO
      try {
        List<LatLng> pontosCabo = [];
        
        // Usar pontos originais MAIS pontos interpolados (menos que 100 para performance)
        for (int i = 0; i < cabo.rota.length; i++) {
          pontosCabo.add(cabo.rota[i]); // Sempre adicionar ponto original
          
          // Interpolar apenas alguns pontos entre segmentos (reduzir de 100 para 10)
          if (i < cabo.rota.length - 1) {
            final start = cabo.rota[i];
            final end = cabo.rota[i + 1];
            const pointsPerSegment = 10;
            for (int j = 1; j < pointsPerSegment; j++) {
              final t = j / pointsPerSegment;
              final ponto = LatLng(
                start.latitude + (end.latitude - start.latitude) * t,
                start.longitude + (end.longitude - start.longitude) * t,
              );
              pontosCabo.add(ponto);
            }
          }
        }
        
        // Calcular distância mínima entre qualquer ponto do cabo e a CEO
        double minDistancia = double.infinity;
        LatLng pontoMaisProximo = cabo.rota[0];
        
        for (final ponto in pontosCabo) {
          const earthRadiusKm = 6371;
          final dLat = _degToRad(ponto.latitude - widget.ceo.posicao.latitude);
          final dLon = _degToRad(ponto.longitude - widget.ceo.posicao.longitude);
          
          final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
              math.cos(_degToRad(widget.ceo.posicao.latitude)) *
                  math.cos(_degToRad(ponto.latitude)) *
                  math.sin(dLon / 2) *
                  math.sin(dLon / 2);
          
          // Clamp 'a' para evitar valores > 1
          final aClamp = a.clamp(0.0, 1.0);
          final c = 2 * math.asin(math.sqrt(aClamp));
          final distanciaKm = earthRadiusKm * c;
          
          if (distanciaKm < minDistancia) {
            minDistancia = distanciaKm;
            pontoMaisProximo = ponto;
          }
        }
        
        debugPrint('🔍 Cabo: ${cabo.nome}');
        debugPrint('   Pontos da rota: ${cabo.rota.length}, Pontos testados: ${pontosCabo.length}');
        debugPrint('   Min distância: ${minDistancia.toStringAsFixed(4)} km (${(minDistancia * 1000).toStringAsFixed(2)} m)');
        debugPrint('   Ponto mais próximo: Lat ${pontoMaisProximo.latitude.toStringAsFixed(6)}, Lng ${pontoMaisProximo.longitude.toStringAsFixed(6)}');
        debugPrint('   CEO posição: Lat ${widget.ceo.posicao.latitude.toStringAsFixed(6)}, Lng ${widget.ceo.posicao.longitude.toStringAsFixed(6)}');
        
        // Se o ponto mais próximo está dentro de 50m (0.05km), incluir
        final incluir = minDistancia < 0.05;
        debugPrint('   ➡️ ${incluir ? '✅ INCLUÍDO' : '❌ EXCLUÍDO'}\n');
        return incluir;
      } catch (e) {
        debugPrint('❌ Erro ao calcular distância do cabo ${cabo.nome}: $e');
        return false;
      }
    }).toList();
    
    debugPrint('📊 Total de cabos cadastrados: ${provider.cabos.length}');
    debugPrint('📍 CEO: ${widget.ceo.nome} em Lat: ${widget.ceo.posicao.latitude}, Lng: ${widget.ceo.posicao.longitude}');
    debugPrint('✅ Cabos próximos (10m): ${cabosProximos.length}');
    
    // Usar apenas os cabos próximos (sem fallback)
    final cabosParaMostrar = cabosProximos;
    
    return AlertDialog(
      title: const Text('Criar Fusão'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _caboEntradaId.isEmpty ? null : _caboEntradaId,
                decoration: InputDecoration(
                  labelText: 'Cabo de Saída (próximos à CEO)',
                  border: const OutlineInputBorder(),
                  helperText: cabosParaMostrar.isNotEmpty 
                    ? 'Cabos em até 10m de distância'
                    : 'Nenhum cabo encontrado dentro de 10m',
                ),
                items: cabosParaMostrar.map((cabo) => DropdownMenuItem(
                  value: cabo.id,
                  child: Text(cabo.nome),
                )).toList(),
                onChanged: (value) {
                  setState(() => _caboEntradaId = value ?? '');
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Selecione um cabo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12.0),
              TextFormField(
                initialValue: _fibraEntrada.toString(),
                decoration: const InputDecoration(
                  labelText: 'Fibra de Entrada',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _fibraEntrada = FormatUtils.parseInt(value) ?? 1;
                },
                validator: (value) {
                  final num = FormatUtils.parseInt(value ?? '');
                  if (num == null || num < 1) {
                    return 'Número de fibra inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12.0),
              DropdownButtonFormField<String>(
                value: _caboSaidaId.isEmpty ? null : _caboSaidaId,
                decoration: InputDecoration(
                  labelText: 'Cabo de Saída (próximos à CEO)',
                  border: const OutlineInputBorder(),
                  helperText: cabosProximos.isNotEmpty 
                    ? 'Cabos em até 10m de distância'
                    : 'Nenhum cabo próximo, mostrando todos',
                ),
                items: cabosParaMostrar.map((cabo) => DropdownMenuItem(
                  value: cabo.id,
                  child: Text(cabo.nome),
                )).toList(),
                onChanged: (value) {
                  setState(() => _caboSaidaId = value ?? '');
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Selecione um cabo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12.0),
              TextFormField(
                initialValue: _fibraSaida.toString(),
                decoration: const InputDecoration(
                  labelText: 'Fibra de Saída',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _fibraSaida = FormatUtils.parseInt(value) ?? 1;
                },
                validator: (value) {
                  final num = FormatUtils.parseInt(value ?? '');
                  if (num == null || num < 1) {
                    return 'Número de fibra inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12.0),
              TextFormField(
                initialValue: _atenuacao?.toString(),
                decoration: const InputDecoration(
                  labelText: 'Atenuação (dB)',
                  border: OutlineInputBorder(),
                  hintText: 'Opcional',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final parsed = FormatUtils.parseDouble(value);
                  if (parsed != null) {
                    // Converter negativo em positivo automaticamente
                    _atenuacao = parsed.abs();
                  } else {
                    _atenuacao = null;
                  }
                },
              ),
              const SizedBox(height: 12.0),
              TextFormField(
                initialValue: _tecnico,
                decoration: const InputDecoration(
                  labelText: 'Técnico',
                  border: OutlineInputBorder(),
                  hintText: 'Opcional',
                ),
                onChanged: (value) => _tecnico = value.isEmpty ? null : value,
              ),
              const SizedBox(height: 12.0),
              TextFormField(
                initialValue: _observacao,
                decoration: const InputDecoration(
                  labelText: 'Observação',
                  border: OutlineInputBorder(),
                  hintText: 'Opcional',
                ),
                maxLines: 2,
                onChanged: (value) => _observacao = value.isEmpty ? null : value,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final fusao = FusaoCEO(
                id: widget.fusaoId ?? '',
                caboEntradaId: _caboEntradaId,
                fibraEntradaNumero: _fibraEntrada,
                caboSaidaId: _caboSaidaId,
                fibraSaidaNumero: _fibraSaida,
                atenuacao: _atenuacao,
                tecnico: _tecnico,
                observacao: _observacao,
              );
              
              final provider = context.read<InfrastructureProvider>();
              final ceo = provider.getCEO(widget.ceo.id);
              
              if (ceo != null) {
                // Validar se as fibras já estão sendo usadas em outras fusões
                String? errorMsg;
                
                // Procurar por fusões existentes que usam as mesmas fibras
                for (final fOther in ceo.fusoes) {
                  // Pular se é a mesma fusão sendo editada
                  if (widget.fusaoId != null && fOther.id == widget.fusaoId) {
                    continue;
                  }
                  
                  // Verificar fibra de entrada
                  if (fOther.caboEntradaId == _caboEntradaId && 
                      fOther.fibraEntradaNumero == _fibraEntrada) {
                    errorMsg = 'Fibra de entrada #$_fibraEntrada do cabo $_caboEntradaId já está usando em outra fusão';
                    break;
                  }
                  
                  // Verificar fibra de saída
                  if (fOther.caboSaidaId == _caboSaidaId && 
                      fOther.fibraSaidaNumero == _fibraSaida) {
                    errorMsg = 'Fibra de saída #$_fibraSaida do cabo $_caboSaidaId já está usando em outra fusão';
                    break;
                  }
                }
                
                if (errorMsg != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ $errorMsg'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                  return;
                }
              }
              
              if (widget.fusaoId != null) {
                // Editar fusão existente
                provider.atualizarFusao(widget.ceo.id, fusao);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fusão atualizada com sucesso')),
                );
              } else {
                // Criar nova fusão
                provider.adicionarFusao(widget.ceo.id, fusao);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fusão criada com sucesso')),
                );
              }
            }
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
