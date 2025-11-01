import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/infrastructure_provider.dart';
import '../models/ceo_model.dart';
import 'fusion_diagram_screen.dart';

class CEOFormScreen extends StatefulWidget {
  final CEOModel? ceo; // null para novo, preenchido para edição
  final LatLng? initialPosition; // Posição pré-selecionada no mapa
  final VoidCallback? onRequestPositionPick; // Callback para solicitar seleção de posição

  const CEOFormScreen({
    super.key, 
    this.ceo, 
    this.initialPosition,
    this.onRequestPositionPick,
  });

  @override
  State<CEOFormScreen> createState() => _CEOFormScreenState();
}

class _CEOFormScreenState extends State<CEOFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nomeController;
  late TextEditingController _descricaoController;
  late TextEditingController _numeroController;

  LatLng? _posicaoSelecionada;
  int _capacidadeFusoes = 24;
  late String _tipo; // Usar 'late' para inicializar em initState

  static const List<String> _tiposDisponiveis = ['Aérea', 'Subterrânea', 'Poste'];
  static const List<int> _capacidadesDisponiveis = [12, 24, 48, 72, 96, 144];

  @override
  void initState() {
    super.initState();

    if (widget.ceo != null) {
      // Modo edição
      _nomeController = TextEditingController(text: widget.ceo!.nome);
      _descricaoController = TextEditingController(text: widget.ceo!.descricao ?? '');
      _numeroController = TextEditingController(text: widget.ceo!.numeroCEO ?? '');
      _posicaoSelecionada = widget.ceo!.posicao;
      _capacidadeFusoes = widget.ceo!.capacidadeFusoes;
      // Garantir que o tipo está na lista, senão usar padrão
      _tipo = _tiposDisponiveis.contains(widget.ceo!.tipo) ? widget.ceo!.tipo : 'Aérea';
    } else if (widget.initialPosition != null) {
      _posicaoSelecionada = widget.initialPosition;
      // Modo criação
      _nomeController = TextEditingController();
      _descricaoController = TextEditingController();
      _numeroController = TextEditingController();
      _tipo = 'Aérea'; // Valor padrão
      // Se tem posição inicial, usar ela
      if (widget.initialPosition != null) {
        _posicaoSelecionada = widget.initialPosition!;
      }
    } else {
      // Modo criação sem posição
      _nomeController = TextEditingController();
      _descricaoController = TextEditingController();
      _numeroController = TextEditingController();
      _tipo = 'Aérea'; // Valor padrão
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _numeroController.dispose();
    super.dispose();
  }

  void _salvar() {
    if (_formKey.currentState!.validate() && _posicaoSelecionada != null) {
      _formKey.currentState!.save();

      final provider = context.read<InfrastructureProvider>();

      final ceo = CEOModel(
        id: widget.ceo?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        nome: _nomeController.text,
        posicao: _posicaoSelecionada!,
        descricao: _descricaoController.text.isEmpty ? null : _descricaoController.text,
        capacidadeFusoes: _capacidadeFusoes,
        tipo: _tipo,
        numeroCEO: _numeroController.text.isEmpty ? null : _numeroController.text,
        fusoes: widget.ceo?.fusoes ?? [],
        cabosConectadosIds: widget.ceo?.cabosConectadosIds ?? [],
        dataCriacao: widget.ceo?.dataCriacao,
        dataAtualizacao: widget.ceo != null ? DateTime.now() : null,
      );

      if (widget.ceo != null) {
        provider.updateCEO(ceo);
      } else {
        provider.addCEO(ceo);
      }

      Navigator.pop(context);
    } else if (_posicaoSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione uma localização')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ceo != null ? 'Editar CEO' : 'Nova CEO'),
        actions: [
          if (widget.ceo != null)
            IconButton(
              icon: const Icon(Icons.hub),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => FusionDiagramScreen(ceoId: widget.ceo!.id),
                  ),
                );
              },
              tooltip: 'Ver Diagrama de Fusões',
            ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _salvar,
            tooltip: 'Salvar',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Nome
            TextFormField(
              controller: _nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome/Identificação *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.settings_ethernet),
                helperText: 'Ex: CEO-01, CEO Centro, etc',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Informe o nome da CEO';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Número CEO
            TextFormField(
              controller: _numeroController,
              decoration: const InputDecoration(
                labelText: 'Número da CEO',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.tag),
                helperText: 'Número de identificação (opcional)',
              ),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 16),

            // Tipo
            DropdownButtonFormField<String>(
              value: _tipo,
              decoration: const InputDecoration(
                labelText: 'Tipo de Instalação *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              items: _tiposDisponiveis.map((tipo) {
                return DropdownMenuItem(
                  value: tipo,
                  child: Text(tipo),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _tipo = value!;
                });
              },
            ),

            const SizedBox(height: 16),

            // Capacidade de Fusões
            DropdownButtonFormField<int>(
              value: _capacidadeFusoes,
              decoration: const InputDecoration(
                labelText: 'Capacidade de Fusões *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.merge_type),
              ),
              items: _capacidadesDisponiveis.map((capacidade) {
                return DropdownMenuItem(
                  value: capacidade,
                  child: Text('$capacidade fusões'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _capacidadeFusoes = value!;
                });
              },
            ),

            const SizedBox(height: 16),

            // Descrição
            TextFormField(
              controller: _descricaoController,
              decoration: const InputDecoration(
                labelText: 'Descrição/Observações',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
                helperText: 'Informações adicionais sobre a CEO',
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            // Botão para escolher/editar localização
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.location_on,
                  color: _posicaoSelecionada != null ? Colors.orange : Colors.grey,
                  size: 32,
                ),
                title: Text(
                  _posicaoSelecionada != null 
                    ? 'Localização selecionada' 
                    : 'Escolher localização *',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: _posicaoSelecionada != null
                  ? Text(
                      'Lat: ${_posicaoSelecionada!.latitude.toStringAsFixed(6)}, '
                      'Lng: ${_posicaoSelecionada!.longitude.toStringAsFixed(6)}\nToque para editar',
                      style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white70 : Colors.black87),
                    )
                  : const Text('Toque para escolher no mapa'),
                trailing: Icon(
                  _posicaoSelecionada != null ? Icons.edit_location : Icons.add_location,
                  color: Colors.orange,
                ),
                onTap: () {
                  if (widget.onRequestPositionPick != null) {
                    widget.onRequestPositionPick!();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Feche este formulário e use o botão + para escolher a localização primeiro'),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                },
              ),
            ),

            const SizedBox(height: 24),

            // Botão Salvar
            FilledButton.icon(
              onPressed: _salvar,
              icon: const Icon(Icons.save),
              label: Text(widget.ceo != null ? 'Salvar Alterações' : 'Criar CEO'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
