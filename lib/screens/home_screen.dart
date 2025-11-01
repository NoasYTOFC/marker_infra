import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io';
import 'map_screen.dart';
import 'elements_list_screen.dart';
import 'import_export_screen.dart';
import 'statistics_screen.dart';
import 'routes_analysis_screen.dart';
import '../widgets/help_dialog.dart';

class HomeScreen extends StatefulWidget {
  final File? sharedFile;

  const HomeScreen({super.key, this.sharedFile});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isMeasurementActive = false;
  bool _isPositionPickerActive = false;
  final GlobalKey<MapScreenState> _mapKey = GlobalKey<MapScreenState>();

  @override
  void initState() {
    super.initState();
    // Se um arquivo foi compartilhado, ir para a tela de import/export
    print('🏠 HomeScreen initState - sharedFile: ${widget.sharedFile?.path ?? "null"}');
    _checkSharedFile();
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Verificar se um arquivo foi adicionado depois que o widget foi construído
    if (widget.sharedFile != null && oldWidget.sharedFile == null) {
      print('🔄 HomeScreen atualizado com novo arquivo: ${widget.sharedFile?.path}');
      _checkSharedFile();
    }
  }

  void _checkSharedFile() {
    if (widget.sharedFile != null) {
      print('✅ Arquivo detectado! Mostrando diálogo...');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _navigateToImportWithFile(widget.sharedFile!);
        }
      });
    } else {
      print('❌ Nenhum arquivo compartilhado');
    }
  }

  void _navigateToImportWithFile(File file) {
    print('📂 Navegando para importação com arquivo: ${file.path}');
    // Mostrar diálogo de confirmação
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('💬 Mostrando diálogo de confirmação');
      showDialog(
        context: context,
        builder: (ctx) {
          final isDarkMode = Theme.of(ctx).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
            title: Text(
              'Importar Arquivo',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            content: Text(
              'Deseja importar o arquivo:\n\n${file.path.split('/').last}?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  print('❌ Usuário cancelou importação');
                  Navigator.of(ctx).pop();
                },
                child: Text(
                  'Cancelar',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.blue,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  print('✅ Usuário confirmou importação');
                  Navigator.of(ctx).pop();
                  // Abrir tela de importação com o arquivo
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ImportExportScreen(sharedFile: file),
                    ),
                  );
                },
                child: const Text('Importar'),
              ),
            ],
          );
        },
      );
    });
  }

  void _navigateToMap(LatLng? location, {String? elementType, String? elementId}) {
    setState(() {
      _currentIndex = 0; // Índice da aba do mapa
    });
    
    // Aguardar a mudança de aba e renderização do mapa
    if (location != null) {
      // Delay para garantir que o mapa está renderizado
      Future.delayed(const Duration(milliseconds: 500), () {
        final mapState = _mapKey.currentState;
        
        if (mapState != null) {
          mapState.centerOnLocation(location, zoom: 18.0);
          
          // Destacar o elemento se informações foram fornecidas
          if (elementType != null && elementId != null) {
            mapState.highlightElement(elementId, elementType);
          }
        }
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('InfraPlan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.import_export),
            tooltip: 'Importar/Exportar',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ImportExportScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Ajuda',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const HelpDialog(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Sobre',
            onPressed: () => _showAboutDialog(context),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          MapScreen(
            key: _mapKey,
            onMeasurementModeChanged: (isActive) {
              setState(() {
                _isMeasurementActive = isActive;
              });
            },
            onPositionPickerModeChanged: (isActive) {
              setState(() {
                _isPositionPickerActive = isActive;
              });
            },
          ),
          ElementsListScreen(
            onNavigateToMap: _navigateToMap,
          ),
          const StatisticsScreen(),
          const RoutesAnalysisScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Mapa',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_outlined),
            selectedIcon: Icon(Icons.list),
            label: 'Elementos',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Estatísticas',
          ),
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route),
            label: 'Análise',
          ),
        ],
      ),
      floatingActionButton: (_currentIndex == 0 && !_isMeasurementActive && !_isPositionPickerActive)
          ? FloatingActionButton.extended(
              onPressed: () => _showAddMenu(context),
              icon: const Icon(Icons.add),
              label: const Text('Adicionar'),
            )
          : null,
    );
  }

  void _showAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.router, color: Colors.green),
              title: const Text('CTO'),
              subtitle: const Text('Caixa de Terminação Óptica'),
              onTap: () {
                Navigator.pop(context);
                // Iniciar seleção de posição no mapa
                setState(() => _currentIndex = 0); // Ir para aba do mapa
                Future.delayed(const Duration(milliseconds: 100), () {
                  _mapKey.currentState?.startPositionPicking('CTO');
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.cable, color: Colors.blue),
              title: const Text('Cabo'),
              subtitle: const Text('Cabo de Fibra Óptica'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 0);
                Future.delayed(const Duration(milliseconds: 100), () {
                  _mapKey.currentState?.startPositionPicking('Cabo');
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.dns, color: Colors.red),
              title: const Text('OLT'),
              subtitle: const Text('Optical Line Terminal'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 0);
                Future.delayed(const Duration(milliseconds: 100), () {
                  _mapKey.currentState?.startPositionPicking('OLT');
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_ethernet, color: Colors.orange),
              title: const Text('CEO'),
              subtitle: const Text('Caixa de Emenda Óptica'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 0);
                Future.delayed(const Duration(milliseconds: 100), () {
                  _mapKey.currentState?.startPositionPicking('CEO');
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.hub, color: Colors.purple),
              title: const Text('DIO'),
              subtitle: const Text('Distribuidor Interno Óptico'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 0);
                Future.delayed(const Duration(milliseconds: 100), () {
                  _mapKey.currentState?.startPositionPicking('DIO');
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Infraestrutura de Redes',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.network_check, size: 64),
      children: [
        const Text(
          'Aplicativo para gerenciamento de infraestrutura de redes de fibra óptica.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Recursos:\n'
          '• Gerenciamento de CTOs, OLTs, CEOs, DIOs e Cabos\n'
          '• Suporte completo a KMZ/KML com sistema de KEYS\n'
          '• Padrão ABNT para configuração de fibras\n'
          '• Diagramas e conexões\n'
          '• Estatísticas e relatórios',
        ),
      ],
    );
  }
}
