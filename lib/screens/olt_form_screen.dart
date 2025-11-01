import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/olt_model.dart';
import '../providers/infrastructure_provider.dart';
import '../utils/format_utils.dart';

class OLTFormScreen extends StatefulWidget {
  final OLTModel? olt;
  final LatLng? initialPosition; // Posição pré-selecionada no mapa
  final VoidCallback? onRequestPositionPick; // Callback para solicitar seleção de posição

  const OLTFormScreen({
    super.key, 
    this.olt, 
    this.initialPosition,
    this.onRequestPositionPick,
  });

  @override
  State<OLTFormScreen> createState() => _OLTFormScreenState();
}

class _OLTFormScreenState extends State<OLTFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _ipController = TextEditingController();
  final _fabricanteController = TextEditingController();
  final _modeloController = TextEditingController();
  final _descricaoController = TextEditingController();
  
  int _numeroSlots = 8;
  LatLng? _posicaoSelecionada;

  @override
  void initState() {
    super.initState();
    if (widget.olt != null) {
      _nomeController.text = widget.olt!.nome;
      _ipController.text = widget.olt!.ipAddress ?? '';
      _fabricanteController.text = widget.olt!.fabricante ?? '';
      _modeloController.text = widget.olt!.modelo ?? '';
      _descricaoController.text = widget.olt!.descricao ?? '';
      _numeroSlots = widget.olt!.numeroSlots;
      _posicaoSelecionada = widget.olt!.posicao;
    } else if (widget.initialPosition != null) {
      // Nova OLT com posição pré-selecionada
      _posicaoSelecionada = widget.initialPosition;
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _ipController.dispose();
    _fabricanteController.dispose();
    _modeloController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  int get _totalPONs => _numeroSlots * 16; // Assumindo 16 PONs por slot

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
    
    if (widget.olt == null) {
      final novoOLT = OLTModel(
        id: const Uuid().v4(),
        nome: _nomeController.text,
        posicao: _posicaoSelecionada!,
        numeroSlots: _numeroSlots,
        ipAddress: _ipController.text.isEmpty ? null : _ipController.text,
        fabricante: _fabricanteController.text.isEmpty ? null : _fabricanteController.text,
        modelo: _modeloController.text.isEmpty ? null : _modeloController.text,
        descricao: _descricaoController.text.isEmpty ? null : _descricaoController.text,
      );
      provider.addOLT(novoOLT);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OLT adicionada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      final oltAtualizado = widget.olt!.copyWith(
        nome: _nomeController.text,
        posicao: _posicaoSelecionada!,
        numeroSlots: _numeroSlots,
        ipAddress: _ipController.text.isEmpty ? null : _ipController.text,
        fabricante: _fabricanteController.text.isEmpty ? null : _fabricanteController.text,
        modelo: _modeloController.text.isEmpty ? null : _modeloController.text,
        descricao: _descricaoController.text.isEmpty ? null : _descricaoController.text,
      );
      provider.updateOLT(oltAtualizado);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OLT atualizada com sucesso!'),
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
        title: Text(widget.olt == null ? 'Adicionar OLT' : 'Editar OLT'),
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
                prefixIcon: Icon(Icons.dns),
                helperText: 'Ex: OLT-CENTRAL, OLT Norte, etc',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Informe o nome da OLT';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Endereço IP
            TextFormField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: 'Endereço IP',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.router),
                helperText: 'Endereço IP da OLT (opcional)',
              ),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 16),

            // Fabricante e Modelo
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _fabricanteController,
                    decoration: const InputDecoration(
                      labelText: 'Fabricante',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business),
                      helperText: 'Ex: Huawei, ZTE',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _modeloController,
                    decoration: const InputDecoration(
                      labelText: 'Modelo',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                      helperText: 'Ex: MA5800',
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Número de Slots
            TextFormField(
              initialValue: _numeroSlots.toString(),
              decoration: const InputDecoration(
                labelText: 'Número de Slots *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.settings_input_component),
                helperText: 'Quantidade de slots da OLT',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Informe o número de slots';
                }
                final numero = FormatUtils.parseInt(value);
                if (numero == null || numero <= 0) {
                  return 'Digite um número válido maior que 0';
                }
                return null;
              },
              onSaved: (value) {
                _numeroSlots = FormatUtils.parseInt(value!) ?? 4;
              },
              onChanged: (value) {
                final numero = FormatUtils.parseInt(value);
                if (numero != null && numero > 0) {
                  setState(() {
                    _numeroSlots = numero;
                  });
                }
              },
            ),

            const SizedBox(height: 16),

            // Card com total de PONs
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
                      'Capacidade da OLT',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total de PONs:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          '$_totalPONs',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.blue[300] : Colors.blue),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_numeroSlots ${_numeroSlots == 1 ? "slot" : "slots"} × 16 PONs',
                      style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
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
                helperText: 'Informações adicionais sobre a OLT',
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            // Botão para escolher/editar localização
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.location_on,
                  color: _posicaoSelecionada != null ? Colors.red : Colors.grey,
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
                  color: Colors.red,
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

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
