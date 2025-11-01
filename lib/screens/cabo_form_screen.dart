import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/cabo_model.dart';
import '../providers/infrastructure_provider.dart';

class CaboFormScreen extends StatefulWidget {
  final CaboModel? cabo;
  final List<LatLng>? initialRoute; // Rota pré-desenhada no mapa
  final VoidCallback? onRequestRoutePick; // Callback para solicitar desenho de rota

  const CaboFormScreen({
    super.key, 
    this.cabo, 
    this.initialRoute,
    this.onRequestRoutePick,
  });

  @override
  State<CaboFormScreen> createState() => _CaboFormScreenState();
}

class _CaboFormScreenState extends State<CaboFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  
  ConfiguracaoCabo _configuracao = ConfiguracaoCabo.fo24;
  String _tipoInstalacao = 'Aéreo';
  List<LatLng> _pontos = [];

  @override
  void initState() {
    super.initState();
    print('DEBUG Cabo initState: widget.cabo != null? ${widget.cabo != null}');
    print('DEBUG Cabo initState: widget.initialRoute != null? ${widget.initialRoute != null}');
    if (widget.initialRoute != null) {
      print('DEBUG Cabo initState: widget.initialRoute.length = ${widget.initialRoute!.length}');
    }
    
    if (widget.cabo != null) {
      _nomeController.text = widget.cabo!.nome;
      _descricaoController.text = widget.cabo!.descricao ?? '';
      _configuracao = widget.cabo!.configuracao;
      _tipoInstalacao = widget.cabo!.tipoInstalacao;
      _pontos = List.from(widget.cabo!.rota);
      print('DEBUG Cabo initState: Modo edição, carregou ${_pontos.length} pontos');
    } else if (widget.initialRoute != null) {
      // Nova cabo com rota pré-desenhada
      _pontos = List.from(widget.initialRoute!);
      print('DEBUG Cabo initState: Modo criação, carregou ${_pontos.length} pontos de initialRoute');
    } else {
      print('DEBUG Cabo initState: Modo criação sem rota inicial');
    }
    print('DEBUG Cabo initState: _pontos.length = ${_pontos.length}');
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  double get _distanciaTotal {
    if (_pontos.length < 2) return 0;
    
    double distancia = 0;
    const distance = Distance();
    
    for (int i = 0; i < _pontos.length - 1; i++) {
      distancia += distance(_pontos[i], _pontos[i + 1]);
    }
    
    return distancia;
  }

  void _salvar() {
    print('DEBUG Cabo _salvar: iniciado');
    print('DEBUG Cabo _pontos.length: ${_pontos.length}');
    
    // Validar formulário
    final isValid = _formKey.currentState?.validate() ?? false;
    print('DEBUG Cabo: Formulário válido? $isValid');
    
    if (!isValid) {
      print('DEBUG Cabo: Formulário inválido - abortando');
      return;
    }

    if (_pontos.length < 2) {
      print('DEBUG Cabo: Menos de 2 pontos (${_pontos.length}) - mostrando SnackBar');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Desenhe a rota do cabo no mapa (mínimo 2 pontos)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('DEBUG Cabo: Validação OK! Salvando cabo...');
    print('DEBUG Cabo: Nome: ${_nomeController.text}');
    print('DEBUG Cabo: Rota com ${_pontos.length} pontos');
    
    final provider = context.read<InfrastructureProvider>();
    
    if (widget.cabo == null) {
      print('DEBUG Cabo: Criando novo cabo');
      final novoCabo = CaboModel(
        id: const Uuid().v4(),
        nome: _nomeController.text,
        rota: _pontos,
        configuracao: _configuracao,
        tipoInstalacao: _tipoInstalacao,
        descricao: _descricaoController.text.isEmpty ? null : _descricaoController.text,
      );
      provider.addCabo(novoCabo);
      print('DEBUG Cabo: Cabo adicionado ao provider');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cabo adicionado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // Editar: criar novo objeto com dados atualizados
      final caboAtualizado = CaboModel(
        id: widget.cabo!.id,
        nome: _nomeController.text,
        rota: _pontos,
        configuracao: _configuracao,
        tipoInstalacao: _tipoInstalacao,
        descricao: _descricaoController.text.isEmpty ? null : _descricaoController.text,
        tubos: widget.cabo!.tubos, // Manter tubos existentes
        pontoInicioId: widget.cabo!.pontoInicioId,
        pontoFimId: widget.cabo!.pontoFimId,
        elementosIntermediariosIds: widget.cabo!.elementosIntermediariosIds,
        dataCriacao: widget.cabo!.dataCriacao,
        dataAtualizacao: DateTime.now(),
      );
      provider.updateCabo(caboAtualizado);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cabo atualizado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    }
    
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cabo == null ? 'Adicionar Cabo' : 'Editar Cabo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _salvar,
          ),
        ],
      ),
      body: Column(
        children: [
          // Formulário
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nomeController,
                      decoration: const InputDecoration(
                        labelText: 'Nome *',
                        hintText: 'Ex: CABO-PRINCIPAL-01',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.cable),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Campo obrigatório';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<ConfiguracaoCabo>(
                      value: _configuracao,
                      decoration: const InputDecoration(
                        labelText: 'Configuração (Fibras) *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.settings_input_svideo),
                      ),
                      items: ConfiguracaoCabo.values.map((config) {
                        return DropdownMenuItem(
                          value: config,
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: config.cor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.grey),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('${config.totalFibras}FO (${config.numeroTubos} ${config.numeroTubos == 1 ? "tubo" : "tubos"})'),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _configuracao = value!;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      value: _tipoInstalacao,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Instalação *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.architecture),
                      ),
                      items: ['Aéreo', 'Subterrâneo', 'Espinado'].map((tipo) {
                        return DropdownMenuItem(
                          value: tipo,
                          child: Text(tipo),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _tipoInstalacao = value!;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _descricaoController,
                      decoration: const InputDecoration(
                        labelText: 'Descrição',
                        hintText: 'Informações adicionais',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 2,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Card(
                      color: _pontos.length >= 2 
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _pontos.length >= 2 ? Icons.check_circle : Icons.info,
                                  color: _pontos.length >= 2 ? Colors.green : Colors.orange,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Rota: ${_pontos.length} pontos',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            if (_distanciaTotal > 0) ...[
                              const SizedBox(height: 4),
                              Text('Distância: ${_distanciaTotal.toStringAsFixed(2)} m'),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Botão para escolher/editar rota
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: ListTile(
                leading: Icon(
                  Icons.location_on,
                  color: _pontos.length >= 2 ? Colors.blue : Colors.grey,
                  size: 32,
                ),
                title: Text(
                  _pontos.length >= 2 
                    ? 'Rota desenhada' 
                    : 'Desenhar rota *',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: _pontos.length >= 2
                  ? Text(
                      '${_pontos.length} pontos, ${_distanciaTotal.toStringAsFixed(2)} m\nToque para editar',
                      style: const TextStyle(fontSize: 12),
                    )
                  : const Text('Toque para desenhar no mapa'),
                trailing: Icon(
                  _pontos.length >= 2 ? Icons.edit_location : Icons.add_location,
                  color: Colors.blue,
                ),
                onTap: () {
                  print('DEBUG Cabo: onTap do botão editar rota chamado');
                  print('DEBUG Cabo: widget.onRequestRoutePick != null? ${widget.onRequestRoutePick != null}');
                  print('DEBUG Cabo: _pontos.length atual: ${_pontos.length}');
                  
                  if (widget.onRequestRoutePick != null) {
                    print('DEBUG Cabo: Fechando formulário e chamando callback');
                    Navigator.pop(context);
                    widget.onRequestRoutePick!();
                  } else {
                    print('DEBUG Cabo: Sem callback, mostrando SnackBar');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Feche este formulário e use o botão + para desenhar a rota primeiro'),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
