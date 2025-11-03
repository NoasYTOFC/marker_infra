import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import '../providers/infrastructure_provider.dart';
import '../widgets/element_details_sheet.dart';
import '../models/cto_model.dart';
import '../models/olt_model.dart';
import '../models/ceo_model.dart';
import '../models/dio_model.dart';
import '../models/cabo_model.dart' show CaboModel, ConfiguracaoCabo;
import 'cto_form_screen.dart';
import 'olt_form_screen.dart';
import 'cabo_form_screen.dart';
import 'ceo_form_screen.dart';
import 'dio_form_screen.dart';

class ElementsListScreen extends StatefulWidget {
  final Function(LatLng? location, {String? elementType, String? elementId})? onNavigateToMap;

  const ElementsListScreen({super.key, this.onNavigateToMap});

  @override
  State<ElementsListScreen> createState() => _ElementsListScreenState();
}

class _ElementsListScreenState extends State<ElementsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  
  // Seleção em lote
  final Set<String> _selectedCTOs = {};
  final Set<String> _selectedOLTs = {};
  final Set<String> _selectedCEOs = {};
  final Set<String> _selectedDIOs = {};
  final Set<String> _selectedCabos = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InfrastructureProvider>();

    // Contar selecionados na aba atual
    int totalSelecionados = 0;
    switch (_tabController.index) {
      case 0:
        totalSelecionados = _selectedCTOs.length;
        break;
      case 1:
        totalSelecionados = _selectedOLTs.length;
        break;
      case 2:
        totalSelecionados = _selectedCEOs.length;
        break;
      case 3:
        totalSelecionados = _selectedDIOs.length;
        break;
      case 4:
        totalSelecionados = _selectedCabos.length;
        break;
    }

    return Column(
      children: [
        // Campo de busca
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Pesquisar elementos...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Botão de Reset
                  Tooltip(
                    message: 'Limpar todos os elementos',
                    child: IconButton(
                      icon: const Icon(Icons.delete_forever),
                      color: Colors.red[700],
                      onPressed: () => _confirmResetAll(context, provider),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red[50],
                      ),
                    ),
                  ),
                ],
              ),
              // Botão "Selecionar tudo" quando há busca ativa
              if (_searchController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.select_all),
                      label: const Text('Selecionar todos os resultados'),
                      onPressed: () => _selecionarTodosFiltrados(context, _searchController.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[50],
                        foregroundColor: Colors.blue,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Barra com botão de deletar selecionados
        if (totalSelecionados > 0)
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.amber[900]
                  : Colors.amber[50],
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.amber[700]!
                      : Colors.amber[200]!,
                  width: 2,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Texto do topo com contador destacado
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.amber[300]
                            : Colors.amber[700],
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$totalSelecionados selecionado${totalSelecionados > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: MediaQuery.of(context).size.width > 600 ? 16 : 14,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.amber[100]
                                : Colors.amber[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Botões em linha com scroll horizontal
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Botão Select All
                      SizedBox(
                        height: 40,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.select_all, size: 18),
                          label: const Text('Selecionar tudo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          onPressed: () => _selecionarTodosFiltrados(context, _searchController.text),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            elevation: 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 40,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Editar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          onPressed: () => _showBulkEditDialog(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            elevation: 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 40,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.delete_sweep, size: 18),
                          label: const Text('Deletar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          onPressed: () => _confirmBulkDelete(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            elevation: 2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 40,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.clear, size: 18),
                          label: const Text('Deselecionar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          onPressed: () {
                            setState(() {
                              _selectedCTOs.clear();
                              _selectedOLTs.clear();
                              _selectedCEOs.clear();
                              _selectedDIOs.clear();
                              _selectedCabos.clear();
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).brightness == Brightness.dark
                                ? Colors.amber[100]
                                : Colors.amber[800],
                            side: BorderSide(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.amber[100]!
                                  : Colors.amber[400]!,
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.blue[900]
                  : Colors.blue[50],
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.blue[700]!
                      : Colors.blue[200]!,
                  width: 1,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.list,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.blue[300]
                      : Colors.blue[700],
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${provider.ctos.length + provider.olts.length + provider.ceos.length + provider.dios.length + provider.cabos.length} elemento${(provider.ctos.length + provider.olts.length + provider.ceos.length + provider.dios.length + provider.cabos.length) > 1 ? 's' : ''} total',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: MediaQuery.of(context).size.width > 600 ? 15 : 13,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.blue[100]
                          : Colors.blue[900],
                    ),
                  ),
                ),
                // Botão Select All
                SizedBox(
                  height: 40,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.select_all, size: 18),
                    label: const Text('Selecionar tudo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    onPressed: () => _selecionarTodosFiltrados(context, _searchController.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: 'CTOs (${provider.ctos.length})'),
            Tab(text: 'OLTs (${provider.olts.length})'),
            Tab(text: 'CEOs (${provider.ceos.length})'),
            Tab(text: 'DIOs (${provider.dios.length})'),
            Tab(text: 'Cabos (${provider.cabos.length})'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildCTOsList(provider, _searchController.text),
              _buildOLTsList(provider, _searchController.text),
              _buildCEOsList(provider, _searchController.text),
              _buildDIOsList(provider, _searchController.text),
              _buildCabosList(provider, _searchController.text),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCTOsList(InfrastructureProvider provider, String searchQuery) {
    final filtrados = provider.ctos
        .where((cto) => cto.nome.toLowerCase().contains(searchQuery))
        .toList();

    if (provider.ctos.isEmpty) {
      return const Center(
        child: Text('Nenhuma CTO cadastrada'),
      );
    }

    if (filtrados.isEmpty && searchQuery.isNotEmpty) {
      return Center(
        child: Text('Nenhuma CTO encontrada com "$searchQuery"'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: filtrados.length,
      itemBuilder: (context, index) {
        final cto = filtrados[index];
        final isSelected = _selectedCTOs.contains(cto.id);
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        
        return Card(
          color: isSelected 
            ? (isDarkMode ? Colors.green[900] : Colors.green[50]) 
            : null,
          child: ListTile(
            leading: Checkbox(
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value ?? false) {
                    _selectedCTOs.add(cto.id);
                  } else {
                    _selectedCTOs.remove(cto.id);
                  }
                });
              },
            ),
            title: Text(cto.nome),
            subtitle: Text(
              '${cto.numeroPortas} portas • ${cto.tipoSplitter}',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmDelete(
                context,
                'CTO',
                cto.nome,
                () => provider.removeCTO(cto.id),
              ),
            ),
            onTap: () {
              ElementDetailsSheet.showCTO(
                context,
                cto,
                onEdit: () {
                  print('DEBUG elements_list: Abrindo CTOFormScreen em modo edição');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CTOFormScreen(cto: cto),
                    ),
                  ).then((_) {
                    // Após retornar do formulário, fechar o sheet para reabri-lo com dados atualizados
                    Navigator.pop(context);
                  });
                },
                onDelete: () {
                  Navigator.pop(context);
                  _confirmDelete(
                    context,
                    'CTO',
                    cto.nome,
                    () => provider.removeCTO(cto.id),
                  );
                },
                onNavigate: widget.onNavigateToMap != null
                    ? () {
                        Navigator.pop(context);
                        widget.onNavigateToMap!(cto.posicao, elementType: 'CTO', elementId: cto.id);
                      }
                    : null,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildOLTsList(InfrastructureProvider provider, String searchQuery) {
    final filtrados = provider.olts
        .where((olt) => olt.nome.toLowerCase().contains(searchQuery))
        .toList();

    if (provider.olts.isEmpty) {
      return const Center(
        child: Text('Nenhuma OLT cadastrada'),
      );
    }

    if (filtrados.isEmpty && searchQuery.isNotEmpty) {
      return Center(
        child: Text('Nenhuma OLT encontrada com "$searchQuery"'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: filtrados.length,
      itemBuilder: (context, index) {
        final olt = filtrados[index];
        final isSelected = _selectedOLTs.contains(olt.id);
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        
        return Card(
          color: isSelected 
            ? (isDarkMode ? Colors.red[900] : Colors.red[50]) 
            : null,
          child: ListTile(
            leading: Checkbox(
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value ?? false) {
                    _selectedOLTs.add(olt.id);
                  } else {
                    _selectedOLTs.remove(olt.id);
                  }
                });
              },
            ),
            title: Text(olt.nome),
            subtitle: Text(
              '${olt.numeroSlots} slots • ${olt.totalPONs} PONs',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmDelete(
                context,
                'OLT',
                olt.nome,
                () => provider.removeOLT(olt.id),
              ),
            ),
            onTap: () {
              ElementDetailsSheet.showOLT(
                context,
                olt,
                onEdit: () {
                  print('DEBUG elements_list: Abrindo OLTFormScreen em modo edição');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OLTFormScreen(olt: olt),
                    ),
                  ).then((_) {
                    // Após retornar do formulário, fechar o sheet para reabri-lo com dados atualizados
                    Navigator.pop(context);
                  });
                },
                onDelete: () {
                  Navigator.pop(context);
                  _confirmDelete(
                    context,
                    'OLT',
                    olt.nome,
                    () => provider.removeOLT(olt.id),
                  );
                },
                onNavigate: widget.onNavigateToMap != null
                    ? () {
                        Navigator.pop(context);
                        widget.onNavigateToMap!(olt.posicao, elementType: 'OLT', elementId: olt.id);
                      }
                    : null,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCEOsList(InfrastructureProvider provider, String searchQuery) {
    final filtrados = provider.ceos
        .where((ceo) => ceo.nome.toLowerCase().contains(searchQuery))
        .toList();

    if (provider.ceos.isEmpty) {
      return const Center(
        child: Text('Nenhuma CEO cadastrada'),
      );
    }

    if (filtrados.isEmpty && searchQuery.isNotEmpty) {
      return Center(
        child: Text('Nenhuma CEO encontrada com "$searchQuery"'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: filtrados.length,
      itemBuilder: (context, index) {
        final ceo = filtrados[index];
        final isSelected = _selectedCEOs.contains(ceo.id);
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        
        return Card(
          color: isSelected 
            ? (isDarkMode ? Colors.orange[900] : Colors.orange[50]) 
            : null,
          child: ListTile(
            leading: Checkbox(
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value ?? false) {
                    _selectedCEOs.add(ceo.id);
                  } else {
                    _selectedCEOs.remove(ceo.id);
                  }
                });
              },
            ),
            title: Text(ceo.nome),
            subtitle: Text(
              'Capacidade: ${ceo.capacidadeFusoes} fusões',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmDelete(
                context,
                'CEO',
                ceo.nome,
                () => provider.removeCEO(ceo.id),
              ),
            ),
            onTap: () {
              ElementDetailsSheet.showCEO(
                context,
                ceo,
                onEdit: () {
                  print('DEBUG elements_list: Abrindo CEOFormScreen em modo edição');
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CEOFormScreen(ceo: ceo),
                    ),
                  ).then((_) {
                    // Após retornar do formulário, os dados já estarão atualizados no provider
                  });
                },
                onDelete: () {
                  Navigator.pop(context);
                  _confirmDelete(
                    context,
                    'CEO',
                    ceo.nome,
                    () => provider.removeCEO(ceo.id),
                  );
                },
                onNavigate: widget.onNavigateToMap != null
                    ? () {
                        Navigator.pop(context);
                        widget.onNavigateToMap!(ceo.posicao, elementType: 'CEO', elementId: ceo.id);
                      }
                    : null,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDIOsList(InfrastructureProvider provider, String searchQuery) {
    final filtrados = provider.dios
        .where((dio) => dio.nome.toLowerCase().contains(searchQuery))
        .toList();

    if (provider.dios.isEmpty) {
      return const Center(
        child: Text('Nenhuma DIO cadastrada'),
      );
    }

    if (filtrados.isEmpty && searchQuery.isNotEmpty) {
      return Center(
        child: Text('Nenhuma DIO encontrada com "$searchQuery"'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: filtrados.length,
      itemBuilder: (context, index) {
        final dio = filtrados[index];
        final isSelected = _selectedDIOs.contains(dio.id);
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        
        return Card(
          color: isSelected 
            ? (isDarkMode ? Colors.purple[900] : Colors.purple[50]) 
            : null,
          child: ListTile(
            leading: Checkbox(
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value ?? false) {
                    _selectedDIOs.add(dio.id);
                  } else {
                    _selectedDIOs.remove(dio.id);
                  }
                });
              },
            ),
            title: Text(dio.nome),
            subtitle: Text(
              '${dio.numeroPortas} portas',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmDelete(
                context,
                'DIO',
                dio.nome,
                () => provider.removeDIO(dio.id),
              ),
            ),
            onTap: () {
              ElementDetailsSheet.showDIO(
                context,
                dio,
                onEdit: () {
                  print('DEBUG elements_list: Abrindo DIOFormScreen em modo edição');
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DIOFormScreen(dio: dio),
                    ),
                  ).then((_) {
                    // Após retornar do formulário, os dados já estarão atualizados no provider
                  });
                },
                onDelete: () {
                  Navigator.pop(context);
                  _confirmDelete(
                    context,
                    'DIO',
                    dio.nome,
                    () => provider.removeDIO(dio.id),
                  );
                },
                onNavigate: widget.onNavigateToMap != null
                    ? () {
                        Navigator.pop(context);
                        widget.onNavigateToMap!(dio.posicao, elementType: 'DIO', elementId: dio.id);
                      }
                    : null,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCabosList(InfrastructureProvider provider, String searchQuery) {
    final filtrados = provider.cabos
        .where((cabo) => cabo.nome.toLowerCase().contains(searchQuery))
        .toList();

    if (provider.cabos.isEmpty) {
      return const Center(
        child: Text('Nenhum cabo cadastrado'),
      );
    }

    if (filtrados.isEmpty && searchQuery.isNotEmpty) {
      return Center(
        child: Text('Nenhum cabo encontrado com "$searchQuery"'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: filtrados.length,
      itemBuilder: (context, index) {
        final cabo = filtrados[index];
        final isSelected = _selectedCabos.contains(cabo.id);
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        
        return Card(
          color: isSelected 
            ? (isDarkMode ? Colors.blue[900] : Colors.blue[50]) 
            : null,
          child: ListTile(
            leading: Checkbox(
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value ?? false) {
                    _selectedCabos.add(cabo.id);
                  } else {
                    _selectedCabos.remove(cabo.id);
                  }
                });
              },
            ),
            title: Text(cabo.nome),
            subtitle: Text(
              '${cabo.configuracao.totalFibras} fibras • ${(cabo.metragem ?? cabo.calcularMetragem()).toStringAsFixed(0)} m',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmDelete(
                context,
                'Cabo',
                cabo.nome,
                () => provider.removeCabo(cabo.id),
              ),
            ),
            onTap: () {
              ElementDetailsSheet.showCabo(
                context,
                cabo,
                onEdit: () {
                  print('DEBUG elements_list: Abrindo CaboFormScreen em modo edição');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CaboFormScreen(cabo: cabo),
                    ),
                  );
                },
                onDelete: () {
                  Navigator.pop(context);
                  _confirmDelete(
                    context,
                    'Cabo',
                    cabo.nome,
                    () => provider.removeCabo(cabo.id),
                  );
                },
                onNavigate: widget.onNavigateToMap != null
                    ? () {
                        Navigator.pop(context);
                        final midLat = cabo.rota.map((p) => p.latitude).reduce((a, b) => a + b) / cabo.rota.length;
                        final midLng = cabo.rota.map((p) => p.longitude).reduce((a, b) => a + b) / cabo.rota.length;
                        widget.onNavigateToMap!(LatLng(midLat, midLng), elementType: 'Cabo', elementId: cabo.id);
                      }
                    : null,
              );
            },
          ),
        );
      },
    );
  }

  void _confirmDelete(
    BuildContext context,
    String tipo,
    String nome,
    VoidCallback onConfirm,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        title: Text(
          'Excluir $tipo?',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        content: Text(
          'Deseja realmente excluir "$nome"?',
          style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.blue),
            ),
          ),
          TextButton(
            onPressed: () {
              onConfirm();
              Navigator.pop(context);
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmBulkDelete(BuildContext context) {
    final provider = context.read<InfrastructureProvider>();
    final totalSelecionados = _selectedCTOs.length +
        _selectedOLTs.length +
        _selectedCEOs.length +
        _selectedDIOs.length +
        _selectedCabos.length;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        title: Text(
          'Excluir em lote?',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        content: Text(
          'Deseja realmente excluir $totalSelecionados elemento${totalSelecionados > 1 ? 's' : ''}?',
          style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.blue),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Mostrar progressbar
              _showDeleteProgressDialog(context, provider, totalSelecionados);
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteProgressDialog(BuildContext context, InfrastructureProvider provider, int total) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DeleteProgressDialog(
        totalItems: total,
        onExecute: () async {
          const chunkSize = 15; // Deletar 15 itens por vez para lotes
          
          // Deletar CTOs em chunks
          final ctosList = _selectedCTOs.toList();
          for (int i = 0; i < ctosList.length; i += chunkSize) {
            final end = (i + chunkSize).clamp(0, ctosList.length);
            final chunk = ctosList.sublist(i, end);
            
            for (final id in chunk) {
              provider.removeCTO(id);
            }
            
            await Future.delayed(const Duration(milliseconds: 30));
          }
          
          // Deletar OLTs em chunks
          final oltsList = _selectedOLTs.toList();
          for (int i = 0; i < oltsList.length; i += chunkSize) {
            final end = (i + chunkSize).clamp(0, oltsList.length);
            final chunk = oltsList.sublist(i, end);
            
            for (final id in chunk) {
              provider.removeOLT(id);
            }
            
            await Future.delayed(const Duration(milliseconds: 30));
          }
          
          // Deletar CEOs em chunks
          final ceosList = _selectedCEOs.toList();
          for (int i = 0; i < ceosList.length; i += chunkSize) {
            final end = (i + chunkSize).clamp(0, ceosList.length);
            final chunk = ceosList.sublist(i, end);
            
            for (final id in chunk) {
              provider.removeCEO(id);
            }
            
            await Future.delayed(const Duration(milliseconds: 30));
          }
          
          // Deletar DIOs em chunks
          final diosList = _selectedDIOs.toList();
          for (int i = 0; i < diosList.length; i += chunkSize) {
            final end = (i + chunkSize).clamp(0, diosList.length);
            final chunk = diosList.sublist(i, end);
            
            for (final id in chunk) {
              provider.removeDIO(id);
            }
            
            await Future.delayed(const Duration(milliseconds: 30));
          }
          
          // Deletar Cabos em chunks
          final cabosList = _selectedCabos.toList();
          for (int i = 0; i < cabosList.length; i += chunkSize) {
            final end = (i + chunkSize).clamp(0, cabosList.length);
            final chunk = cabosList.sublist(i, end);
            
            for (final id in chunk) {
              provider.removeCabo(id);
            }
            
            await Future.delayed(const Duration(milliseconds: 30));
          }

          // Limpar seleção
          if (mounted) {
            setState(() {
              _selectedCTOs.clear();
              _selectedOLTs.clear();
              _selectedCEOs.clear();
              _selectedDIOs.clear();
              _selectedCabos.clear();
            });
          }
        },
      ),
    );
  }

  void _showClearAllProgressDialog(
    BuildContext context,
    InfrastructureProvider provider,
    int totalItems,
    int totalCTOs,
    int totalOLTs,
    int totalCEOs,
    int totalDIOs,
    int totalCabos,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ClearAllProgressDialog(
        totalItems: totalItems,
        totalCTOs: totalCTOs,
        totalOLTs: totalOLTs,
        totalCEOs: totalCEOs,
        totalDIOs: totalDIOs,
        totalCabos: totalCabos,
        onExecute: () async {
          // Deletar TODOS em chunks para evitar travamento
          const chunkSize = 20; // Deletar 20 itens por vez
          
          // Copiar listas para evitar modificação durante iteração
          final ctosCopy = provider.ctos.toList();
          final oltsCopy = provider.olts.toList();
          final ceosCopy = provider.ceos.toList();
          final diosCopy = provider.dios.toList();
          final cabosCopy = provider.cabos.toList();

          // Deletar CTOs em chunks
          for (int i = 0; i < ctosCopy.length; i += chunkSize) {
            final end = (i + chunkSize).clamp(0, ctosCopy.length);
            final chunk = ctosCopy.sublist(i, end);
            
            for (final cto in chunk) {
              provider.removeCTO(cto.id);
            }
            
            await Future.delayed(const Duration(milliseconds: 50));
          }

          // Deletar OLTs em chunks
          for (int i = 0; i < oltsCopy.length; i += chunkSize) {
            final end = (i + chunkSize).clamp(0, oltsCopy.length);
            final chunk = oltsCopy.sublist(i, end);
            
            for (final olt in chunk) {
              provider.removeOLT(olt.id);
            }
            
            await Future.delayed(const Duration(milliseconds: 50));
          }

          // Deletar CEOs em chunks
          for (int i = 0; i < ceosCopy.length; i += chunkSize) {
            final end = (i + chunkSize).clamp(0, ceosCopy.length);
            final chunk = ceosCopy.sublist(i, end);
            
            for (final ceo in chunk) {
              provider.removeCEO(ceo.id);
            }
            
            await Future.delayed(const Duration(milliseconds: 50));
          }

          // Deletar DIOs em chunks
          for (int i = 0; i < diosCopy.length; i += chunkSize) {
            final end = (i + chunkSize).clamp(0, diosCopy.length);
            final chunk = diosCopy.sublist(i, end);
            
            for (final dio in chunk) {
              provider.removeDIO(dio.id);
            }
            
            await Future.delayed(const Duration(milliseconds: 50));
          }

          // Deletar Cabos em chunks
          for (int i = 0; i < cabosCopy.length; i += chunkSize) {
            final end = (i + chunkSize).clamp(0, cabosCopy.length);
            final chunk = cabosCopy.sublist(i, end);
            
            for (final cabo in chunk) {
              provider.removeCabo(cabo.id);
            }
            
            await Future.delayed(const Duration(milliseconds: 50));
          }

          // Limpar seleções
          if (mounted) {
            setState(() {
              _selectedCTOs.clear();
              _selectedOLTs.clear();
              _selectedCEOs.clear();
              _selectedDIOs.clear();
              _selectedCabos.clear();
            });
          }
        },
      ),
    );
  }

  void _confirmResetAll(BuildContext context, InfrastructureProvider provider) {
    final totalCTOs = provider.ctos.length;
    final totalOLTs = provider.olts.length;
    final totalCEOs = provider.ceos.length;
    final totalDIOs = provider.dios.length;
    final totalCabos = provider.cabos.length;
    final totalItens = totalCTOs + totalOLTs + totalCEOs + totalDIOs + totalCabos;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (totalItens == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ℹ️ Nenhum elemento para limpar'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        title: Text(
          '⚠️ Limpar TODOS os elementos?',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Essa ação NÃO pode ser desfeita! Será deletado:',
              style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(height: 12),
            if (totalCTOs > 0)
              Text(
                '  🟢 $totalCTOs CTO${totalCTOs > 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
            if (totalOLTs > 0)
              Text(
                '  🔴 $totalOLTs OLT${totalOLTs > 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
            if (totalCEOs > 0)
              Text(
                '  🟠 $totalCEOs CEO${totalCEOs > 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
            if (totalDIOs > 0)
              Text(
                '  🟣 $totalDIOs DIO${totalDIOs > 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
            if (totalCabos > 0)
              Text(
                '  🔵 $totalCabos Cabo${totalCabos > 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
            const SizedBox(height: 12),
            Text(
              'TOTAL: $totalItens elemento${totalItens > 1 ? 's' : ''}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.red,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.blue),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Mostrar progressbar
              _showClearAllProgressDialog(context, provider, totalItens, totalCTOs, totalOLTs, totalCEOs, totalDIOs, totalCabos);
            },
            child: const Text(
              'Limpar Tudo',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _selecionarTodosFiltrados(BuildContext context, String searchQuery) {
    final provider = context.read<InfrastructureProvider>();

    setState(() {
      switch (_tabController.index) {
        case 0:
          // CTOs filtrados
          final filtrados = provider.ctos
              .where((cto) => cto.nome.toLowerCase().contains(searchQuery.toLowerCase()))
              .toList();
          for (final cto in filtrados) {
            _selectedCTOs.add(cto.id);
          }
          break;
        case 1:
          // OLTs filtrados
          final filtrados = provider.olts
              .where((olt) => olt.nome.toLowerCase().contains(searchQuery.toLowerCase()))
              .toList();
          for (final olt in filtrados) {
            _selectedOLTs.add(olt.id);
          }
          break;
        case 2:
          // CEOs filtrados
          final filtrados = provider.ceos
              .where((ceo) => ceo.nome.toLowerCase().contains(searchQuery.toLowerCase()))
              .toList();
          for (final ceo in filtrados) {
            _selectedCEOs.add(ceo.id);
          }
          break;
        case 3:
          // DIOs filtrados
          final filtrados = provider.dios
              .where((dio) => dio.nome.toLowerCase().contains(searchQuery.toLowerCase()))
              .toList();
          for (final dio in filtrados) {
            _selectedDIOs.add(dio.id);
          }
          break;
        case 4:
          // Cabos filtrados
          final filtrados = provider.cabos
              .where((cabo) => cabo.nome.toLowerCase().contains(searchQuery.toLowerCase()))
              .toList();
          for (final cabo in filtrados) {
            _selectedCabos.add(cabo.id);
          }
          break;
      }
    });

    // Feedback visual
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Todos os resultados foram selecionados'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showBulkEditDialog(BuildContext context) {
    final provider = context.read<InfrastructureProvider>();
    
    // Determinar o tipo de elemento e quantidade selecionada
    String elementType = '';
    int selectedCount = 0;
    
    switch (_tabController.index) {
      case 0:
        elementType = 'CTO';
        selectedCount = _selectedCTOs.length;
        break;
      case 1:
        elementType = 'OLT';
        selectedCount = _selectedOLTs.length;
        break;
      case 2:
        elementType = 'CEO';
        selectedCount = _selectedCEOs.length;
        break;
      case 3:
        elementType = 'DIO';
        selectedCount = _selectedDIOs.length;
        break;
      case 4:
        elementType = 'Cabo';
        selectedCount = _selectedCabos.length;
        break;
    }

    if (selectedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Selecione pelo menos um elemento'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Mostrar diálogo de edição em lote baseado no tipo
    showDialog(
      context: context,
      builder: (context) => _BulkEditDialog(
        elementType: elementType,
        selectedCount: selectedCount,
        selectedIds: _getSelectedIdsForCurrentTab(),
        provider: provider,
        onComplete: () {
          setState(() {
            // Limpar seleções após edição
            _selectedCTOs.clear();
            _selectedOLTs.clear();
            _selectedCEOs.clear();
            _selectedDIOs.clear();
            _selectedCabos.clear();
          });
        },
      ),
    );
  }

  Set<String> _getSelectedIdsForCurrentTab() {
    switch (_tabController.index) {
      case 0:
        return _selectedCTOs;
      case 1:
        return _selectedOLTs;
      case 2:
        return _selectedCEOs;
      case 3:
        return _selectedDIOs;
      case 4:
        return _selectedCabos;
      default:
        return {};
    }
  }
}

/// Widget de diálogo com progressbar para deletar elementos
class _DeleteProgressDialog extends StatefulWidget {
  final int totalItems;
  final Future<void> Function() onExecute;

  const _DeleteProgressDialog({
    required this.totalItems,
    required this.onExecute,
  });

  @override
  State<_DeleteProgressDialog> createState() => _DeleteProgressDialogState();
}

class _DeleteProgressDialogState extends State<_DeleteProgressDialog> {
  @override
  void initState() {
    super.initState();
    _executeDelete();
  }

  Future<void> _executeDelete() async {
    await widget.onExecute();
    // Auto-close após conclusão
    if (mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${widget.totalItems} elemento${widget.totalItems > 1 ? 's' : ''} deletado${widget.totalItems > 1 ? 's' : ''}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return WillPopScope(
      onWillPop: () async => false,
      child: Dialog(
        insetAnimationDuration: const Duration(milliseconds: 300),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Deletando elementos...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
                  ),
                ),
                const SizedBox(height: 24),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    minHeight: 12,
                    backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${widget.totalItems} item${widget.totalItems > 1 ? 'ns' : ''}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget para Clear All com progressbar detalhado
class _ClearAllProgressDialog extends StatefulWidget {
  final int totalItems;
  final int totalCTOs;
  final int totalOLTs;
  final int totalCEOs;
  final int totalDIOs;
  final int totalCabos;
  final Future<void> Function() onExecute;

  const _ClearAllProgressDialog({
    required this.totalItems,
    required this.totalCTOs,
    required this.totalOLTs,
    required this.totalCEOs,
    required this.totalDIOs,
    required this.totalCabos,
    required this.onExecute,
  });

  @override
  State<_ClearAllProgressDialog> createState() => _ClearAllProgressDialogState();
}

class _ClearAllProgressDialogState extends State<_ClearAllProgressDialog> {
  @override
  void initState() {
    super.initState();
    _executeDelete();
  }

  Future<void> _executeDelete() async {
    await widget.onExecute();
    // Auto-close após conclusão
    if (mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🗑️ ${widget.totalItems} elemento${widget.totalItems > 1 ? 's' : ''} removido${widget.totalItems > 1 ? 's' : ''}! Mapa resetado!'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return WillPopScope(
      onWillPop: () async => false,
      child: Dialog(
        insetAnimationDuration: const Duration(milliseconds: 300),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450, maxHeight: 400),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Limpando todos os elementos...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 24),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    minHeight: 12,
                    backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                  ),
                ),
                const SizedBox(height: 24),
                if (widget.totalCTOs > 0)
                  _buildProgressItem(
                    '🟢 CTOs',
                    '${widget.totalCTOs} item${widget.totalCTOs > 1 ? 'ns' : ''}',
                    isDarkMode,
                  ),
                if (widget.totalOLTs > 0)
                  _buildProgressItem(
                    '🔴 OLTs',
                    '${widget.totalOLTs} item${widget.totalOLTs > 1 ? 'ns' : ''}',
                    isDarkMode,
                  ),
                if (widget.totalCEOs > 0)
                  _buildProgressItem(
                    '🟠 CEOs',
                    '${widget.totalCEOs} item${widget.totalCEOs > 1 ? 'ns' : ''}',
                    isDarkMode,
                  ),
                if (widget.totalDIOs > 0)
                  _buildProgressItem(
                    '🟣 DIOs',
                    '${widget.totalDIOs} item${widget.totalDIOs > 1 ? 'ns' : ''}',
                    isDarkMode,
                  ),
                if (widget.totalCabos > 0)
                  _buildProgressItem(
                    '🔵 Cabos',
                    '${widget.totalCabos} item${widget.totalCabos > 1 ? 'ns' : ''}',
                    isDarkMode,
                  ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Total: ${widget.totalItems} elemento${widget.totalItems > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.red[300] : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressItem(String label, String count, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
          Text(
            count,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget de diálogo para edição em lote
class _BulkEditDialog extends StatefulWidget {
  final String elementType;
  final int selectedCount;
  final Set<String> selectedIds;
  final InfrastructureProvider provider;
  final VoidCallback onComplete;

  const _BulkEditDialog({
    required this.elementType,
    required this.selectedCount,
    required this.selectedIds,
    required this.provider,
    required this.onComplete,
  });

  @override
  State<_BulkEditDialog> createState() => _BulkEditDialogState();
}

class _BulkEditDialogState extends State<_BulkEditDialog> {
  // Campos editáveis comuns
  String? _novaDescricao;
  
  // CTO específicos
  int? _novoNumeroPortas;
  String? _novoTipoSplitter;
  
  // DIO específicos
  String? _novoTipoDIO;
  
  // OLT específicos
  int? _novoNumeroSlots;
  String? _novoFabricante;
  String? _novoModelo;
  
  // CEO específicos
  int? _novaCapacidadeFusoes;
  String? _novoTipoCEO;
  
  // Cabo específicos
  ConfiguracaoCabo? _novaConfiguracaoCabo;
  String? _novoTipoInstalacao;
  
  // Flags de aplicação
  bool _aplicarDescricao = false;
  bool _aplicarNumeroPortas = false;
  bool _aplicarTipoSplitter = false;
  bool _aplicarTipoDIO = false;
  bool _aplicarNumeroSlots = false;
  bool _aplicarFabricante = false;
  bool _aplicarModelo = false;
  bool _aplicarCapacidadeFusoes = false;
  bool _aplicarTipoCEO = false;
  bool _aplicarConfiguracaoCabo = false;
  bool _aplicarTipoInstalacao = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('✏️ Editar ${widget.selectedCount} ${widget.elementType}${widget.selectedCount > 1 ? 's' : ''} em lote'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Marque os campos que deseja alterar:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // ========== DESCRIÇÃO (COMUM A TODOS) ==========
            CheckboxListTile(
              title: const Text('Descrição'),
              value: _aplicarDescricao,
              onChanged: (value) => setState(() => _aplicarDescricao = value ?? false),
            ),
            if (_aplicarDescricao)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Nova descrição',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onChanged: (value) => _novaDescricao = value,
                ),
              ),
            
            // ========== CTO ==========
            if (widget.elementType == 'CTO') ...[
              CheckboxListTile(
                title: const Text('Número de Portas'),
                value: _aplicarNumeroPortas,
                onChanged: (value) => setState(() => _aplicarNumeroPortas = value ?? false),
              ),
              if (_aplicarNumeroPortas)
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  child: DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Número de portas',
                      border: OutlineInputBorder(),
                    ),
                    items: [4, 8, 12, 16, 24, 32, 48].map((portas) {
                      return DropdownMenuItem(
                        value: portas,
                        child: Text('$portas portas'),
                      );
                    }).toList(),
                    onChanged: (value) => _novoNumeroPortas = value,
                  ),
                ),
              
              CheckboxListTile(
                title: const Text('Tipo de Splitter'),
                value: _aplicarTipoSplitter,
                onChanged: (value) => setState(() => _aplicarTipoSplitter = value ?? false),
              ),
              if (_aplicarTipoSplitter)
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Tipo de splitter',
                      border: OutlineInputBorder(),
                    ),
                    items: ['1:2', '1:4', '1:8', '1:16', '1:32', '1:64'].map((tipo) {
                      return DropdownMenuItem(
                        value: tipo,
                        child: Text(tipo),
                      );
                    }).toList(),
                    onChanged: (value) => _novoTipoSplitter = value,
                  ),
                ),
            ],
            
            // ========== DIO ==========
            if (widget.elementType == 'DIO') ...[
              CheckboxListTile(
                title: const Text('Número de Portas'),
                value: _aplicarNumeroPortas,
                onChanged: (value) => setState(() => _aplicarNumeroPortas = value ?? false),
              ),
              if (_aplicarNumeroPortas)
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  child: DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Número de portas',
                      border: OutlineInputBorder(),
                    ),
                    items: [4, 8, 12, 16, 24, 32, 48].map((portas) {
                      return DropdownMenuItem(
                        value: portas,
                        child: Text('$portas portas'),
                      );
                    }).toList(),
                    onChanged: (value) => _novoNumeroPortas = value,
                  ),
                ),
              
              CheckboxListTile(
                title: const Text('Tipo de DIO'),
                value: _aplicarTipoDIO,
                onChanged: (value) => setState(() => _aplicarTipoDIO = value ?? false),
              ),
              if (_aplicarTipoDIO)
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Tipo de DIO',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Rack', 'Parede', 'Piso'].map((tipo) {
                      return DropdownMenuItem(
                        value: tipo,
                        child: Text(tipo),
                      );
                    }).toList(),
                    onChanged: (value) => _novoTipoDIO = value,
                  ),
                ),
            ],
            
            // ========== OLT ==========
            if (widget.elementType == 'OLT') ...[
              CheckboxListTile(
                title: const Text('Número de Slots'),
                value: _aplicarNumeroSlots,
                onChanged: (value) => setState(() => _aplicarNumeroSlots = value ?? false),
              ),
              if (_aplicarNumeroSlots)
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  child: DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Número de slots',
                      border: OutlineInputBorder(),
                    ),
                    items: [1, 2, 4, 8, 16].map((slots) {
                      return DropdownMenuItem(
                        value: slots,
                        child: Text('$slots slots'),
                      );
                    }).toList(),
                    onChanged: (value) => _novoNumeroSlots = value,
                  ),
                ),
              
              CheckboxListTile(
                title: const Text('Fabricante'),
                value: _aplicarFabricante,
                onChanged: (value) => setState(() => _aplicarFabricante = value ?? false),
              ),
              if (_aplicarFabricante)
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Fabricante',
                      hintText: 'ex: Huawei, ZTE, Nokia',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => _novoFabricante = value,
                  ),
                ),
              
              CheckboxListTile(
                title: const Text('Modelo'),
                value: _aplicarModelo,
                onChanged: (value) => setState(() => _aplicarModelo = value ?? false),
              ),
              if (_aplicarModelo)
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Modelo',
                      hintText: 'ex: MA5680T',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => _novoModelo = value,
                  ),
                ),
            ],
            
            // ========== CEO ==========
            if (widget.elementType == 'CEO') ...[
              CheckboxListTile(
                title: const Text('Capacidade de Fusões'),
                value: _aplicarCapacidadeFusoes,
                onChanged: (value) => setState(() => _aplicarCapacidadeFusoes = value ?? false),
              ),
              if (_aplicarCapacidadeFusoes)
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  child: DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Capacidade de fusões',
                      border: OutlineInputBorder(),
                    ),
                    items: [12, 24, 36, 48, 72].map((cap) {
                      return DropdownMenuItem(
                        value: cap,
                        child: Text('$cap fusões'),
                      );
                    }).toList(),
                    onChanged: (value) => _novaCapacidadeFusoes = value,
                  ),
                ),
              
              CheckboxListTile(
                title: const Text('Tipo de CEO'),
                value: _aplicarTipoCEO,
                onChanged: (value) => setState(() => _aplicarTipoCEO = value ?? false),
              ),
              if (_aplicarTipoCEO)
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Tipo de CEO',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Aérea', 'Subterrânea', 'Poste'].map((tipo) {
                      return DropdownMenuItem(
                        value: tipo,
                        child: Text(tipo),
                      );
                    }).toList(),
                    onChanged: (value) => _novoTipoCEO = value,
                  ),
                ),
            ],
            
            // ========== CABO ==========
            if (widget.elementType == 'Cabo') ...[
              CheckboxListTile(
                title: const Text('Tipo de Fibra'),
                value: _aplicarConfiguracaoCabo,
                onChanged: (value) => setState(() => _aplicarConfiguracaoCabo = value ?? false),
              ),
              if (_aplicarConfiguracaoCabo)
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  child: DropdownButtonFormField<ConfiguracaoCabo>(
                    decoration: const InputDecoration(
                      labelText: 'Tipo de fibra',
                      border: OutlineInputBorder(),
                    ),
                    items: ConfiguracaoCabo.values.map((config) {
                      return DropdownMenuItem(
                        value: config,
                        child: Text(config.nome),
                      );
                    }).toList(),
                    onChanged: (value) => _novaConfiguracaoCabo = value,
                  ),
                ),
              
              CheckboxListTile(
                title: const Text('Tipo de Instalação'),
                value: _aplicarTipoInstalacao,
                onChanged: (value) => setState(() => _aplicarTipoInstalacao = value ?? false),
              ),
              if (_aplicarTipoInstalacao)
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Tipo de instalação',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Aéreo', 'Subterrâneo', 'Espinado'].map((tipo) {
                      return DropdownMenuItem(
                        value: tipo,
                        child: Text(tipo),
                      );
                    }).toList(),
                    onChanged: (value) => _novoTipoInstalacao = value,
                  ),
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _aplicarEdicao,
          child: const Text('Aplicar'),
        ),
      ],
    );
  }

  void _aplicarEdicao() async {
    // Validar se pelo menos um campo foi selecionado
    if (!_aplicarDescricao && !_aplicarNumeroPortas && !_aplicarTipoSplitter && 
        !_aplicarTipoDIO && !_aplicarNumeroSlots && !_aplicarFabricante && 
        !_aplicarModelo && !_aplicarCapacidadeFusoes && !_aplicarTipoCEO && 
        !_aplicarConfiguracaoCabo && !_aplicarTipoInstalacao) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Selecione pelo menos um campo para editar'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    Navigator.pop(context); // Fechar diálogo

    // Mostrar progresso
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _BulkEditProgressDialog(
        elementType: widget.elementType,
        selectedIds: widget.selectedIds,
        provider: widget.provider,
        novaDescricao: _aplicarDescricao ? _novaDescricao : null,
        // CTO
        novoNumeroPortas: _aplicarNumeroPortas ? _novoNumeroPortas : null,
        novoTipoSplitter: _aplicarTipoSplitter ? _novoTipoSplitter : null,
        // DIO
        novoTipoDIO: _aplicarTipoDIO ? _novoTipoDIO : null,
        // OLT
        novoNumeroSlots: _aplicarNumeroSlots ? _novoNumeroSlots : null,
        novoFabricante: _aplicarFabricante ? _novoFabricante : null,
        novoModelo: _aplicarModelo ? _novoModelo : null,
        // CEO
        novaCapacidadeFusoes: _aplicarCapacidadeFusoes ? _novaCapacidadeFusoes : null,
        novoTipoCEO: _aplicarTipoCEO ? _novoTipoCEO : null,
        // Cabo
        novaConfiguracaoCabo: _aplicarConfiguracaoCabo ? _novaConfiguracaoCabo : null,
        novoTipoInstalacao: _aplicarTipoInstalacao ? _novoTipoInstalacao : null,
        onComplete: widget.onComplete,
      ),
    );
  }
}

/// Widget de progresso para edição em lote
class _BulkEditProgressDialog extends StatefulWidget {
  final String elementType;
  final Set<String> selectedIds;
  final InfrastructureProvider provider;
  final String? novaDescricao;
  // CTO
  final int? novoNumeroPortas;
  final String? novoTipoSplitter;
  // DIO
  final String? novoTipoDIO;
  // OLT
  final int? novoNumeroSlots;
  final String? novoFabricante;
  final String? novoModelo;
  // CEO
  final int? novaCapacidadeFusoes;
  final String? novoTipoCEO;
  // Cabo
  final ConfiguracaoCabo? novaConfiguracaoCabo;
  final String? novoTipoInstalacao;
  final VoidCallback onComplete;

  const _BulkEditProgressDialog({
    required this.elementType,
    required this.selectedIds,
    required this.provider,
    this.novaDescricao,
    this.novoNumeroPortas,
    this.novoTipoSplitter,
    this.novoTipoDIO,
    this.novoNumeroSlots,
    this.novoFabricante,
    this.novoModelo,
    this.novaCapacidadeFusoes,
    this.novoTipoCEO,
    this.novaConfiguracaoCabo,
    this.novoTipoInstalacao,
    required this.onComplete,
  });

  @override
  State<_BulkEditProgressDialog> createState() => _BulkEditProgressDialogState();
}

class _BulkEditProgressDialogState extends State<_BulkEditProgressDialog> {
  int _processados = 0;
  bool _concluido = false;

  @override
  void initState() {
    super.initState();
    _executarEdicao();
  }

  Future<void> _executarEdicao() async {
    final total = widget.selectedIds.length;

    for (final id in widget.selectedIds) {
      await _editarElemento(id);
      
      if (mounted) {
        setState(() {
          _processados++;
        });
      }
      
      await Future.delayed(const Duration(milliseconds: 10)); // Pequeno delay
    }

    if (mounted) {
      setState(() {
        _concluido = true;
      });
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        Navigator.pop(context);
        widget.onComplete();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $total ${widget.elementType}${total > 1 ? 's' : ''} editado${total > 1 ? 's' : ''} com sucesso!'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _editarElemento(String id) async {
    switch (widget.elementType) {
      case 'CTO':
        final cto = widget.provider.ctos.firstWhere((c) => c.id == id);
        final ctoAtualizado = CTOModel(
          id: cto.id,
          nome: cto.nome,
          posicao: cto.posicao,
          descricao: widget.novaDescricao ?? cto.descricao,
          numeroPortas: widget.novoNumeroPortas ?? cto.numeroPortas,
          tipoSplitter: widget.novoTipoSplitter ?? cto.tipoSplitter,
          numeroCTO: cto.numeroCTO,
          portas: cto.portas,
          caboEntradaId: cto.caboEntradaId,
          cabosSaidaIds: cto.cabosSaidaIds,
          dataCriacao: cto.dataCriacao,
          dataAtualizacao: DateTime.now(),
        );
        widget.provider.updateCTO(ctoAtualizado);
        break;
        
      case 'OLT':
        final olt = widget.provider.olts.firstWhere((o) => o.id == id);
        final oltAtualizado = OLTModel(
          id: olt.id,
          nome: olt.nome,
          posicao: olt.posicao,
          descricao: widget.novaDescricao ?? olt.descricao,
          ipAddress: olt.ipAddress,
          numeroSlots: widget.novoNumeroSlots ?? olt.numeroSlots,
          slots: widget.novoNumeroSlots != null && widget.novoNumeroSlots != olt.numeroSlots
              ? List.generate(
                  widget.novoNumeroSlots!,
                  (i) => SlotOLT(
                    numero: i + 1,
                    numeroPONs: 16,
                  ),
                )
              : olt.slots,
          fabricante: widget.novoFabricante ?? olt.fabricante,
          modelo: widget.novoModelo ?? olt.modelo,
          cabosConectadosIds: olt.cabosConectadosIds,
          dataCriacao: olt.dataCriacao,
          dataAtualizacao: DateTime.now(),
        );
        widget.provider.updateOLT(oltAtualizado);
        break;
        
      case 'CEO':
        final ceo = widget.provider.ceos.firstWhere((c) => c.id == id);
        final ceoAtualizado = CEOModel(
          id: ceo.id,
          nome: ceo.nome,
          posicao: ceo.posicao,
          descricao: widget.novaDescricao ?? ceo.descricao,
          capacidadeFusoes: widget.novaCapacidadeFusoes ?? ceo.capacidadeFusoes,
          tipo: widget.novoTipoCEO ?? ceo.tipo,
          fusoes: ceo.fusoes,
          numeroCEO: ceo.numeroCEO,
          cabosConectadosIds: ceo.cabosConectadosIds,
          dataCriacao: ceo.dataCriacao,
          dataAtualizacao: DateTime.now(),
        );
        widget.provider.updateCEO(ceoAtualizado);
        break;
        
      case 'DIO':
        final dio = widget.provider.dios.firstWhere((d) => d.id == id);
        final dioAtualizado = DIOModel(
          id: dio.id,
          nome: dio.nome,
          posicao: dio.posicao,
          descricao: widget.novaDescricao ?? dio.descricao,
          numeroPortas: widget.novoNumeroPortas ?? dio.numeroPortas,
          tipo: widget.novoTipoDIO ?? dio.tipo,
          portas: widget.novoNumeroPortas != null && widget.novoNumeroPortas != dio.numeroPortas
              ? List.generate(
                  widget.novoNumeroPortas!,
                  (i) => PortaDIO(numero: i + 1),
                )
              : dio.portas,
          numeroDIO: dio.numeroDIO,
          cabosConectadosIds: dio.cabosConectadosIds,
          dataCriacao: dio.dataCriacao,
          dataAtualizacao: DateTime.now(),
        );
        widget.provider.updateDIO(dioAtualizado);
        break;
        
      case 'Cabo':
        final cabo = widget.provider.cabos.firstWhere((c) => c.id == id);
        
        // Processar descrição mantendo as keys
        final descricaoAtual = cabo.descricao ?? '';
        final descricaoKeys = descricaoAtual.contains('--- KEYS ---') 
            ? descricaoAtual.substring(descricaoAtual.indexOf('--- KEYS ---'))
            : '';
        
        String novaDescricaoCompleta;
        if (widget.novaDescricao != null) {
          // Manter as keys se existirem
          novaDescricaoCompleta = descricaoKeys.isNotEmpty 
              ? '${widget.novaDescricao}\n\n$descricaoKeys'
              : widget.novaDescricao!;
        } else {
          novaDescricaoCompleta = descricaoAtual;
        }
        
        // Criar cabo atualizado com novos valores
        final caboAtualizado = CaboModel(
          id: cabo.id,
          nome: cabo.nome,
          rota: cabo.rota,
          descricao: novaDescricaoCompleta,
          configuracao: widget.novaConfiguracaoCabo ?? cabo.configuracao,
          tipoInstalacao: widget.novoTipoInstalacao ?? cabo.tipoInstalacao,
          metragem: cabo.metragem,
          tubos: widget.novaConfiguracaoCabo != null 
              ? null // Gera novos tubos automaticamente
              : cabo.tubos,
          pontoInicioId: cabo.pontoInicioId,
          pontoFimId: cabo.pontoFimId,
          elementosIntermediariosIds: cabo.elementosIntermediariosIds,
          dataCriacao: cabo.dataCriacao,
          dataAtualizacao: DateTime.now(),
        );
        widget.provider.updateCabo(caboAtualizado);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final total = widget.selectedIds.length;
    final progresso = total > 0 ? _processados / total : 0.0;

    return WillPopScope(
      onWillPop: () async => _concluido,
      child: AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        title: Text(
          '✏️ Editando elementos...',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(
              value: progresso,
              backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              '$_processados / $total ${widget.elementType}${total > 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            if (_concluido)
              Text(
                '✅ Concluído!',
                style: TextStyle(
                  color: isDarkMode ? Colors.green[300] : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
