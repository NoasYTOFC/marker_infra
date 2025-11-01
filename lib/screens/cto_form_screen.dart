import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/cto_model.dart';
import '../providers/infrastructure_provider.dart';

class CTOFormScreen extends StatefulWidget {
  final CTOModel? cto; // null para adicionar, preenchido para editar
  final LatLng? initialPosition; // Posição pré-selecionada no mapa
  final VoidCallback? onRequestPositionPick; // Callback para solicitar seleção de posição

  const CTOFormScreen({
    super.key, 
    this.cto, 
    this.initialPosition,
    this.onRequestPositionPick,
  });

  @override
  State<CTOFormScreen> createState() => _CTOFormScreenState();
}

class _CTOFormScreenState extends State<CTOFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _numeroController = TextEditingController();
  final _descricaoController = TextEditingController();
  
  int _numeroSplitters = 1;
  int _portasPorSplitter = 8;
  LatLng? _posicaoSelecionada;

  int get _numeroPortasTotal => _numeroSplitters * _portasPorSplitter;
  String get _tipoSplitter => '1:$_portasPorSplitter';

  @override
  void initState() {
    super.initState();
    print('DEBUG CTO initState: widget.cto != null? ${widget.cto != null}');
    print('DEBUG CTO initState: widget.onRequestPositionPick != null? ${widget.onRequestPositionPick != null}');
    
    if (widget.cto != null) {
      // Modo edição - preencher campos
      _nomeController.text = widget.cto!.nome;
      _numeroController.text = widget.cto!.numeroCTO ?? '';
      _descricaoController.text = widget.cto!.descricao ?? '';
      
      // Extrair número de portas por splitter do formato "1:X"
      final splitterParts = widget.cto!.tipoSplitter.split(':');
      if (splitterParts.length == 2) {
        _portasPorSplitter = int.tryParse(splitterParts[1]) ?? 8;
      }
      
      // Calcular número de splitters
      _numeroSplitters = (widget.cto!.numeroPortas / _portasPorSplitter).ceil();
      
      _posicaoSelecionada = widget.cto!.posicao;
    } else if (widget.initialPosition != null) {
      // Nova CTO com posição pré-selecionada
      _posicaoSelecionada = widget.initialPosition;
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _numeroController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  void _salvar() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_posicaoSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione uma posição no mapa'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final provider = context.read<InfrastructureProvider>();
    
    if (widget.cto == null) {
      // Modo adicionar
      final novoCTO = CTOModel(
        id: const Uuid().v4(),
        nome: _nomeController.text,
        posicao: _posicaoSelecionada!,
        numeroPortas: _numeroPortasTotal,
        tipoSplitter: _tipoSplitter,
        numeroCTO: _numeroController.text.isEmpty ? null : _numeroController.text,
        descricao: _descricaoController.text.isEmpty ? null : _descricaoController.text,
      );
      provider.addCTO(novoCTO);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CTO adicionada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // Modo editar
      final ctoAtualizado = widget.cto!.copyWith(
        nome: _nomeController.text,
        posicao: _posicaoSelecionada!,
        numeroPortas: _numeroPortasTotal,
        tipoSplitter: _tipoSplitter,
        numeroCTO: _numeroController.text.isEmpty ? null : _numeroController.text,
        descricao: _descricaoController.text.isEmpty ? null : _descricaoController.text,
      );
      provider.updateCTO(ctoAtualizado);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CTO atualizada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    }
    
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cto == null ? 'Adicionar CTO' : 'Editar CTO'),
        actions: [
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
                prefixIcon: Icon(Icons.router),
                helperText: 'Ex: CTO-01, CTO Centro, etc',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Informe o nome da CTO';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Número CTO
            TextFormField(
              controller: _numeroController,
              decoration: const InputDecoration(
                labelText: 'Número da CTO',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.tag),
                helperText: 'Número de identificação (opcional)',
              ),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 16),

            // Número de Splitters
            DropdownButtonFormField<int>(
              value: _numeroSplitters,
              decoration: const InputDecoration(
                labelText: 'Número de Splitters *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.device_hub),
                helperText: 'Quantidade de splitters na CTO',
              ),
              items: [1, 2, 3, 4].map((numero) {
                return DropdownMenuItem(
                  value: numero,
                  child: Text('$numero ${numero == 1 ? "splitter" : "splitters"}'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _numeroSplitters = value!;
                });
              },
            ),

            const SizedBox(height: 16),

            // Portas por Splitter
            DropdownButtonFormField<int>(
              value: _portasPorSplitter,
              decoration: const InputDecoration(
                labelText: 'Portas por Splitter *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.settings_input_hdmi),
                helperText: 'Número de saídas de cada splitter',
              ),
              items: [2, 4, 8, 16, 32, 64].map((portas) {
                return DropdownMenuItem(
                  value: portas,
                  child: Text('$portas portas'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _portasPorSplitter = value!;
                });
              },
            ),

            const SizedBox(height: 16),

            // Card com resumo da configuração
            Card(
              color: isDarkMode 
                ? Colors.blue.withOpacity(0.2) 
                : Colors.blue.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Configuração do Splitter',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tipo: $_numeroSplitters:$_portasPorSplitter',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      'Descrição: $_numeroSplitters ${_numeroSplitters == 1 ? "splitter" : "splitters"} × $_portasPorSplitter portas',
                      style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total de Portas:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          '$_numeroPortasTotal',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.blue[300] : Colors.blue),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Descrição
            TextFormField(
              controller: _descricaoController,
              decoration: const InputDecoration(
                labelText: 'Descrição/Observações',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
                helperText: 'Informações adicionais sobre a CTO',
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            // Botão para escolher/editar localização
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.location_on,
                  color: _posicaoSelecionada != null ? Colors.green : Colors.grey,
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
                  color: Colors.green,
                ),
                onTap: () {
                  print('DEBUG CTO: onTap chamado');
                  print('DEBUG CTO: widget.onRequestPositionPick != null? ${widget.onRequestPositionPick != null}');
                  
                  if (widget.onRequestPositionPick != null) {
                    print('DEBUG CTO: Chamando callback para selecionar posição (SEM fechar formulário)');
                    // Chamar callback para ativar position picker NO MAPA
                    // NÃO fechar o formulário - deixar visível para que possa ser atualizado depois
                    widget.onRequestPositionPick!();
                  } else {
                    print('DEBUG CTO: Sem callback, mostrando SnackBar');
                    // Modo standalone (sem callback) - apenas orientar usuário
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

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
