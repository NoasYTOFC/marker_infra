import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/infrastructure_provider.dart';
import '../models/dio_model.dart';

class DIOFormScreen extends StatefulWidget {
  final DIOModel? dio; // null para novo, preenchido para edição
  final LatLng? initialPosition; // Posição pré-selecionada no mapa
  final VoidCallback? onRequestPositionPick; // Callback para solicitar seleção de posição

  const DIOFormScreen({
    super.key, 
    this.dio, 
    this.initialPosition,
    this.onRequestPositionPick,
  });

  @override
  State<DIOFormScreen> createState() => _DIOFormScreenState();
}

class _DIOFormScreenState extends State<DIOFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nomeController;
  late TextEditingController _descricaoController;
  late TextEditingController _numeroController;

  LatLng? _posicaoSelecionada;
  int _numeroPortas = 24;
  String _tipo = 'Rack';

  @override
  void initState() {
    super.initState();

    if (widget.dio != null) {
      // Modo edição
      _nomeController = TextEditingController(text: widget.dio!.nome);
      _descricaoController = TextEditingController(text: widget.dio!.descricao ?? '');
      _numeroController = TextEditingController(text: widget.dio!.numeroDIO ?? '');
      _posicaoSelecionada = widget.dio!.posicao;
      _numeroPortas = widget.dio!.numeroPortas;
      _tipo = widget.dio!.tipo;
    } else if (widget.initialPosition != null) {
      _posicaoSelecionada = widget.initialPosition;
      // Modo criação
      _nomeController = TextEditingController();
      _descricaoController = TextEditingController();
      _numeroController = TextEditingController();
      // Se tem posição inicial, usar ela
      if (widget.initialPosition != null) {
        _posicaoSelecionada = widget.initialPosition!;
      }
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

      final dio = DIOModel(
        id: widget.dio?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        nome: _nomeController.text,
        posicao: _posicaoSelecionada!,
        descricao: _descricaoController.text.isEmpty ? null : _descricaoController.text,
        numeroPortas: _numeroPortas,
        tipo: _tipo,
        numeroDIO: _numeroController.text.isEmpty ? null : _numeroController.text,
        portas: widget.dio?.portas,
        cabosConectadosIds: widget.dio?.cabosConectadosIds ?? [],
        dataCriacao: widget.dio?.dataCriacao,
        dataAtualizacao: widget.dio != null ? DateTime.now() : null,
      );

      if (widget.dio != null) {
        provider.updateDIO(dio);
      } else {
        provider.addDIO(dio);
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
        title: Text(widget.dio != null ? 'Editar DIO' : 'Novo DIO'),
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
                prefixIcon: Icon(Icons.hub),
                helperText: 'Ex: DIO-01, DIO POP Centro, etc',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Informe o nome do DIO';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Número DIO
            TextFormField(
              controller: _numeroController,
              decoration: const InputDecoration(
                labelText: 'Número do DIO',
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
              items: ['Rack', 'Parede', '19 polegadas', 'Compacto'].map((tipo) {
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

            // Número de Portas
            DropdownButtonFormField<int>(
              value: _numeroPortas,
              decoration: const InputDecoration(
                labelText: 'Número de Portas *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.settings_input_component),
              ),
              items: [12, 24, 48, 72, 96, 144].map((portas) {
                return DropdownMenuItem(
                  value: portas,
                  child: Text('$portas portas'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _numeroPortas = value!;
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
                helperText: 'Informações adicionais sobre o DIO',
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            // Botão para escolher/editar localização
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.location_on,
                  color: _posicaoSelecionada != null ? Colors.purple : Colors.grey,
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
                  color: Colors.purple,
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
              label: Text(widget.dio != null ? 'Salvar Alterações' : 'Criar DIO'),
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
