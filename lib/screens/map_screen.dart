import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;
import '../providers/infrastructure_provider.dart';
import '../models/cto_model.dart';
import '../models/olt_model.dart';
import '../models/ceo_model.dart';
import '../models/dio_model.dart';
import '../models/cabo_model.dart';
import '../utils/measurement_tool.dart';
import '../utils/position_picker.dart';
import '../widgets/element_details_sheet.dart';
import '../widgets/coordinate_search_dialog.dart';
import '../services/permission_service.dart';
import '../services/cached_tile_provider.dart';
import 'cto_form_screen.dart';
import 'olt_form_screen.dart';
import 'cabo_form_screen.dart';
import 'ceo_form_screen.dart';
import 'dio_form_screen.dart';

class MapScreen extends StatefulWidget {
  final ValueChanged<bool>? onMeasurementModeChanged;
  final ValueChanged<bool>? onPositionPickerModeChanged;
  final Function(String)? onStartPositionPicking; // Callback para iniciar posicionamento
  
  const MapScreen({
    super.key, 
    this.onMeasurementModeChanged,
    this.onPositionPickerModeChanged,
    this.onStartPositionPicking,
  });

  @override
  State<MapScreen> createState() => MapScreenState();
  
  static MapScreenState? of(BuildContext context) {
    return context.findAncestorStateOfType<MapScreenState>();
  }
}

  // Tornando a classe pública para poder ser referenciada em home_screen
class MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng _center = LatLng(-12.1367, -38.4208); // Alagoinhas-BA
  final MeasurementTool _measurementTool = MeasurementTool();
  final PositionPicker _positionPicker = PositionPicker();
  bool _showLegend = false; // Legenda começa escondida
  double _currentZoom = 15.0; // Zoom inicial = zoom mínimo (pyramid caching)  // Drag-to-move state
  bool _isDragging = false;
  int? _draggedPointIndex; // Índice do ponto sendo arrastado (para cabos)
  
  // Highlight state
  String? _highlightedElementId;
  String? _highlightedElementType;
  
  // Flag para rastrear se há formulário em bottom sheet aberto
  bool _formSheetOpen = false;

  void centerOnLocation(LatLng location, {double zoom = 17.0}) {
    _mapController.move(location, zoom);
  }
  
  void highlightElement(String elementId, String elementType) {
    setState(() {
      _highlightedElementId = elementId;
      _highlightedElementType = elementType;
    });
    // Auto-remover destaque após 5 segundos
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _highlightedElementId = null;
          _highlightedElementType = null;
        });
      }
    });
  }
  
  void clearHighlight() {
    setState(() {
      _highlightedElementId = null;
      _highlightedElementType = null;
    });
  }
  
  void startPositionPicking(String elementType, {String? editingId}) {
    setState(() {
      if (elementType == 'Cabo') {
        _positionPicker.startRoute(elementType, editingId: editingId);
        
        // Se estamos editando um cabo, carregar a rota existente
        if (editingId != null) {
          final provider = context.read<InfrastructureProvider>();
          final cabo = provider.cabos.firstWhere((c) => c.id == editingId);
          // Carregar pontos existentes para poder editar/desfazer
          _positionPicker.route.addAll(cabo.rota);
          print('DEBUG MapScreen: Carregou ${cabo.rota.length} pontos da rota existente');
        }
      } else {
        _positionPicker.startSinglePoint(elementType, editingId: editingId);
        
        // Se estamos editando um item, carregar posição existente
        if (editingId != null) {
          final provider = context.read<InfrastructureProvider>();
          LatLng? existingPosition;
          
          switch (elementType) {
            case 'CTO':
              existingPosition = provider.ctos.firstWhere((c) => c.id == editingId).posicao;
              break;
            case 'OLT':
              existingPosition = provider.olts.firstWhere((o) => o.id == editingId).posicao;
              break;
            case 'CEO':
              existingPosition = provider.ceos.firstWhere((c) => c.id == editingId).posicao;
              break;
            case 'DIO':
              existingPosition = provider.dios.firstWhere((d) => d.id == editingId).posicao;
              break;
          }
          
          if (existingPosition != null) {
            _positionPicker.selectedPosition = existingPosition;
            print('DEBUG MapScreen: Carregou posição existente: $existingPosition');
          }
        }
      }
      
      // Adicionar glow ao elemento sendo editado
      if (editingId != null) {
        _highlightedElementId = editingId;
        _highlightedElementType = elementType;
      }
    });
    // Notificar que position picker ficou ativo
    widget.onPositionPickerModeChanged?.call(true);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InfrastructureProvider>();

    return Stack(
      children: [
        FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 15.0, // Zoom inicial = zoom mínimo com pyramid caching (visão macro)
              minZoom: 15.0, // Zoom mínimo: 15 (pyramid caching suporta zoom 14)
              maxZoom: 21.0, // Zoom máximo: 21 (liberdade total, tiles on-demand após 17)
              onPositionChanged: (position, hasGesture) {
                if (hasGesture) {
                  setState(() {
                    _currentZoom = position.zoom;
                  });
                }
              },
              onTap: (tapPosition, latLng) {
                if (_measurementTool.isActive) {
                  setState(() {
                    _measurementTool.addPoint(latLng);
                  });
                } else if (_positionPicker.isActive) {
                  setState(() {
                    _positionPicker.addPoint(latLng);
                  });
                } else {
                  // Verificar se clicou em algum cabo
                  _handleMapTap(latLng, context);
                }
              },
              onLongPress: (tapPosition, latLng) {
                // Long press inicia drag-to-move
                _startDraggingPoint(latLng);
              },
            ),
            children: [
              TileLayer(
                tileProvider: CachedTileProvider(),
              ),
            // Camada invisível para detecção de clique (área maior)
            if (_currentZoom >= 13.0)
              PolylineLayer(
                polylines: _buildCableHitboxPolylines(provider.cabos),
              ),
            // Linhas de cabos visíveis (com otimização de performance)
            if (_currentZoom >= 13.0)
              PolylineLayer(
                polylines: _buildOptimizedCablePolylines(provider.cabos),
              ),
              // Glow dos cabos destacados
              PolylineLayer(
                polylines: provider.cabos
                    .where((cabo) => _highlightedElementId == cabo.id && _highlightedElementType == 'Cabo')
                    .map((cabo) {
                  return Polyline(
                    points: cabo.rota,
                    color: _getCaboColor(cabo).withOpacity(0.6),
                    strokeWidth: 16.0,
                  );
                }).toList(),
              ),
              // Linha de medição
              if (_measurementTool.points.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _measurementTool.points,
                      color: Colors.red,
                      strokeWidth: 3.0,
                      borderColor: Colors.white,
                      borderStrokeWidth: 1.0,
                    ),
                  ],
                ),
              // Marcadores invisíveis para cabos REMOVIDOS - usando detecção de toque otimizada
              // Marcadores com clustering inteligente (zoom + quantidade de itens)
              // Clustering desabilitado em zoom >= 15 para ver todos os itens
              // VIEWPORT CULLING: renderizar apenas elementos visíveis = MUITA performance
              // RENDERIZADO POR ÚLTIMO = PRIORIDADE MAIOR no clique
              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  maxClusterRadius: _calculateDynamicClusterRadius(
                    provider.ctos.length + 
                    provider.olts.length + 
                    provider.ceos.length + 
                    provider.dios.length,
                  ).round(),
                  size: const Size(40, 40),
                  markers: [
                    // VIEWPORT CULLING: Renderizar apenas elementos na tela + margem
                    ...provider.ctos
                        .where((cto) => _isPointInViewport(cto.posicao))
                        .map((cto) => _buildCTOMarker(cto)),
                    ...provider.olts
                        .where((olt) => _isPointInViewport(olt.posicao))
                        .map((olt) => _buildOLTMarker(olt)),
                    ...provider.ceos
                        .where((ceo) => _isPointInViewport(ceo.posicao))
                        .map((ceo) => _buildCEOMarker(ceo)),
                    ...provider.dios
                        .where((dio) => _isPointInViewport(dio.posicao))
                        .map((dio) => _buildDIOMarker(dio)),
                  ],
                  builder: (context, markers) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.blue,
                      ),
                      child: Center(
                        child: Text(
                          markers.length.toString(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Pontos de medição
              if (_measurementTool.points.isNotEmpty)
                MarkerLayer(
                  markers: _measurementTool.points.asMap().entries.map((entry) {
                    return Marker(
                      point: entry.value,
                      width: 30,
                      height: 30,
                      alignment: Alignment.center, // Centralizar
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            '${entry.key + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              // Linha da rota sendo desenhada (position picker - cabos)
              if (_positionPicker.isActive && _positionPicker.isRouteMode && _positionPicker.route.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _positionPicker.route,
                      color: Colors.blue,
                      strokeWidth: 4.0,
                      borderColor: Colors.white,
                      borderStrokeWidth: 1.0,
                    ),
                  ],
                ),
              // Marcadores de posição sendo selecionada
              if (_positionPicker.isActive)
                MarkerLayer(
                  markers: [
                    // Para itens pontuais - mostrar marcador único
                    if (!_positionPicker.isRouteMode && _positionPicker.selectedPosition != null)
                      Marker(
                        point: _positionPicker.selectedPosition!,
                        width: 50,
                        height: 50,
                        alignment: Alignment.center, // Centralizar
                        child: GestureDetector(
                          onLongPressStart: (details) {
                            _startDraggingPoint(_positionPicker.selectedPosition!);
                          },
                          onLongPressMoveUpdate: (details) {
                            if (_isDragging) {
                              try {
                                final point = _mapController.camera.pointToLatLng(
                                  math.Point(details.globalPosition.dx, details.globalPosition.dy) as dynamic
                                );
                                _updateDragPosition(point);
                              } catch (e) {
                                print('DEBUG: Erro ao converter ponto: $e');
                              }
                            }
                          },
                          onLongPressEnd: (details) {
                            if (_isDragging) {
                              _endDragging();
                            }
                          },
                          child: Icon(
                            _getPositionPickerIcon(),
                            color: Colors.blue,
                            size: 40,
                            shadows: const [
                              Shadow(color: Colors.white, blurRadius: 4),
                              Shadow(color: Colors.white, blurRadius: 8),
                            ],
                          ),
                        ),
                      ),
                    // Para rotas - mostrar pontos numerados
                    if (_positionPicker.isRouteMode)
                      ..._positionPicker.route.asMap().entries.map((entry) {
                        return Marker(
                          point: entry.value,
                          width: 30,
                          height: 30,
                          alignment: Alignment.center, // Centralizar
                          child: GestureDetector(
                            onLongPressStart: (details) {
                              _startDraggingPoint(entry.value);
                            },
                            onLongPressMoveUpdate: (details) {
                              if (_isDragging) {
                                try {
                                  final point = _mapController.camera.pointToLatLng(
                                    math.Point(details.globalPosition.dx, details.globalPosition.dy) as dynamic
                                  );
                                  _updateDragPosition(point);
                                } catch (e) {
                                  print('DEBUG: Erro ao converter ponto: $e');
                                }
                              }
                            },
                            onLongPressEnd: (details) {
                              if (_isDragging) {
                                _endDragging();
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: Center(
                                child: Text(
                                  '${entry.key + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
          ],
        ),
        // Painel de controle
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            children: [
              FloatingActionButton(
                heroTag: 'measurement',
                mini: true,
                backgroundColor: _measurementTool.isActive ? Colors.red : null,
                child: const Icon(Icons.straighten),
                onPressed: () {
                  setState(() {
                    _measurementTool.toggle();
                    widget.onMeasurementModeChanged?.call(_measurementTool.isActive);
                  });
                },
                tooltip: 'Medir distâncias',
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: 'zoom_in',
                mini: true,
                child: const Icon(Icons.add),
                onPressed: () {
                  _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom + 1,
                  );
                },
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: 'zoom_out',
                mini: true,
                child: const Icon(Icons.remove),
                onPressed: () {
                  _mapController.move(
                    _mapController.camera.center,
                    _mapController.camera.zoom - 1,
                  );
                },
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: 'legend',
                mini: true,
                backgroundColor: _showLegend ? Colors.blue : null,
                child: const Icon(Icons.legend_toggle),
                onPressed: () {
                  setState(() {
                    _showLegend = !_showLegend;
                  });
                },
                tooltip: 'Mostrar/Ocultar Legenda',
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: 'my_location',
                mini: true,
                child: const Icon(Icons.my_location),
                onPressed: () async {
                  // Mostrar loading
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🔍 Buscando sua localização...'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                  
                  // Obter localização atual
                  final position = await PermissionService.getCurrentLocation();
                  
                  if (!mounted) return;
                  
                  if (position != null) {
                    // Centralizar no mapa
                    final location = LatLng(position.latitude, position.longitude);
                    setState(() {
                      _center = location;
                      _currentZoom = 17.0;
                    });
                    _mapController.move(_center, _currentZoom);
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('📍 Localização: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('❌ Não foi possível obter sua localização'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: 'search_coordinates',
                mini: true,
                child: const Icon(Icons.search),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => CoordinateSearchDialog(
                      onSearch: (location) {
                        setState(() {
                          _center = location;
                          _currentZoom = 17.0;
                        });
                        _mapController.move(_center, _currentZoom);
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('📍 Coordenadas: ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}'),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  );
                },
                tooltip: 'Pesquisar Coordenadas',
              ),
            ],
          ),
        ),
        // Botão de Atribuições (OpenStreetMap)
        Positioned(
          bottom: 16,
          left: 16,
          child: FloatingActionButton(
            heroTag: 'map_attribution',
            mini: true,
            backgroundColor: Colors.white70,
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
                  return AlertDialog(
                    backgroundColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                    title: Text(
                      '🗺️ Atribuições do Mapa',
                      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                    ),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Este mapa utiliza dados de:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '© OpenStreetMap Contributors',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // Abrir link em navegador
                              print('Abrir: https://www.openstreetmap.org/copyright');
                              launchUrl(Uri.parse('https://www.openstreetmap.org/copyright'));
                            },
                            child: Text(
                              'www.openstreetmap.org/copyright',
                              style: TextStyle(
                                color: isDarkMode ? Colors.blue[300] : Colors.blue,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Licença:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Os dados estão disponíveis sob a licença Open Data Commons Open Database License (ODbL)',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Fechar',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
            tooltip: 'Atribuições do Mapa',
            child: const Text(
              '©',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),
        ),
        if (_measurementTool.isActive)
          Positioned(
            bottom: 16,
            right: 16,
            left: 16,
            child: MeasurementInfo(
              tool: _measurementTool,
              onClear: () {
                setState(() {
                  _measurementTool.clear();
                });
              },
              onUndo: () {
                setState(() {
                  _measurementTool.removeLastPoint();
                });
              },
            ),
          ),
        // Controles do position picker
        if (_positionPicker.isActive)
          Positioned(
            bottom: 16,
            right: 16,
            left: 16,
            child: PositionPickerControls(
              picker: _positionPicker,
              onConfirm: () {
                _handlePositionConfirm();
              },
              onCancel: () {
                setState(() {
                  _positionPicker.clear();
                  _highlightedElementId = null;
                  _highlightedElementType = null;
                });
                // Notificar que position picker foi desativado
                widget.onPositionPickerModeChanged?.call(false);
              },
              onUndo: _positionPicker.isRouteMode ? () {
                setState(() {
                  _positionPicker.removeLastRoutePoint();
                });
              } : null,
            ),
          ),
        // Legenda
        if (!_measurementTool.isActive && !_positionPicker.isActive && _showLegend)
          Positioned(
            bottom: 16,
            left: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Legenda',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.expand_more, size: 18),
                          onPressed: () => _showFullLegend(context),
                          tooltip: 'Ver legenda completa',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildLegendItem(Icons.router, 'CTO', Colors.green),
                    _buildLegendItem(Icons.dns, 'OLT', Colors.red),
                    _buildLegendItem(Icons.settings_ethernet, 'CEO', Colors.orange),
                    _buildLegendItem(Icons.hub, 'DIO', Colors.purple),
                    const Divider(height: 16),
                    const Text('Cabos:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    _buildCableLegendItem('2FO', ConfiguracaoCabo.fo2.cor),
                    _buildCableLegendItem('4FO', ConfiguracaoCabo.fo4.cor),
                    _buildCableLegendItem('6FO', ConfiguracaoCabo.fo6.cor),
                    _buildCableLegendItem('12FO', ConfiguracaoCabo.fo12.cor),
                    _buildCableLegendItem('24FO', ConfiguracaoCabo.fo24.cor),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLegendItem(IconData icon, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildCableLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 3,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  
  // TODO: Implementar drag-to-move com arquitetura melhorada
  // void _startDragging(LatLng latLng) {
  //   print('DEBUG: _startDragging chamado em $latLng');
  //   setState(() {
  //     _isDragging = true;
  //     
  //     // Se é modo de rota (Cabo), encontrar o ponto mais próximo
  //     if (_positionPicker.isRouteMode) {
  //       double minDistance = double.infinity;
  //       int closestIndex = -1;
  //       
  //       for (int i = 0; i < _positionPicker.route.length; i++) {
  //         final distance = _distance(latLng, _positionPicker.route[i]);
  //         if (distance < minDistance) {
  //           minDistance = distance;
  //           closestIndex = i;
  //         }
  //       }
  //       
  //       // Se muito perto de um ponto (menos de 30 metros), arrastar esse ponto
  //       if (minDistance < 30) {
  //         _draggedPointIndex = closestIndex;
  //         print('DEBUG: Começou drag do ponto $closestIndex da rota');
  //       } else {
  //         // Senão, parar drag
  //         _isDragging = false;
  //       }
  //     } else {
  //       // Se é modo single-point, sempre permite drag
  //       print('DEBUG: Começou drag do ponto único');
  //     }
  //   });
  //   
  //   // Agora aguardar por gestos de movimento no mapa
  //   _setupDragListener();
  // }
  
  // Calcular distância entre dois pontos em metros (em coordenadas)
  double _getDistanceInMeters(LatLng p1, LatLng p2) {
    const R = 6371000; // Raio da terra em metros
    final lat1 = p1.latitude * math.pi / 180;
    final lat2 = p2.latitude * math.pi / 180;
    final dLat = (p2.latitude - p1.latitude) * math.pi / 180;
    final dLon = (p2.longitude - p1.longitude) * math.pi / 180;
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c; // Distância em metros
  }
  
  void _startDraggingPoint(LatLng latLng) {
    if (!_positionPicker.isActive) return;
    
    // Se é modo de rota, encontrar ponto mais próximo
    if (_positionPicker.isRouteMode) {
      double minDistance = double.infinity;
      int closestIndex = -1;
      
      for (int i = 0; i < _positionPicker.route.length; i++) {
        final distance = _getDistanceInMeters(latLng, _positionPicker.route[i]);
        if (distance < minDistance) {
          minDistance = distance;
          closestIndex = i;
        }
      }
      
      // Se muito perto de um ponto (menos de 50 metros), começar drag
      if (minDistance < 50 && closestIndex >= 0) {
        setState(() {
          _isDragging = true;
          _draggedPointIndex = closestIndex;
        });
        print('DEBUG: Começou drag do ponto $closestIndex (distância: $minDistance m)');
      }
    } else {
      // Para single-point, sempre permite drag
      setState(() {
        _isDragging = true;
      });
      print('DEBUG: Começou drag do ponto único');
    }
  }
  
  void _updateDragPosition(LatLng newPosition) {
    if (!_isDragging) return;
    
    setState(() {
      if (_positionPicker.isRouteMode && _draggedPointIndex != null) {
        _positionPicker.route[_draggedPointIndex!] = newPosition;
        print('DEBUG: Atualizado ponto $_draggedPointIndex para $newPosition');
      } else if (!_positionPicker.isRouteMode) {
        _positionPicker.selectedPosition = newPosition;
        print('DEBUG: Atualizado ponto único para $newPosition');
      }
    });
  }
  
  void _endDragging() {
    setState(() {
      _isDragging = false;
      _draggedPointIndex = null;
    });
    print('DEBUG: Drag finalizado');
  }
  
  // TODO: Implementar drag-to-move com GestureDetector apropriado
  // void _updateDragPosition(LatLng newPosition) {
  //   if (!_isDragging) return;
  //   
  //   setState(() {
  //     if (_positionPicker.isRouteMode && _draggedPointIndex != null) {
  //       // Mover o ponto da rota
  //       _positionPicker.route[_draggedPointIndex!] = newPosition;
  //       print('DEBUG: Atualizado ponto $_draggedPointIndex para $newPosition');
  //     } else {
  //       // Mover o ponto único
  //       _positionPicker.selectedPosition = newPosition;
  //       print('DEBUG: Atualizado ponto único para $newPosition');
  //     }
  //   });
  // }
  //
  // void _endDragging() {
  //   setState(() {
  //     _isDragging = false;
  //     _draggedPointIndex = null;
  //   });
  //   print('DEBUG: Drag finalizado');
  // }

  void _showFullLegend(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
          title: Text(
            'Legenda Completa',
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Elementos',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                _buildLegendItem(Icons.router, 'CTO - Caixa de Terminação Óptica', Colors.green),
                _buildLegendItem(Icons.dns, 'OLT - Optical Line Terminal', Colors.red),
                _buildLegendItem(Icons.settings_ethernet, 'CEO - Caixa de Emenda Óptica', Colors.orange),
                _buildLegendItem(Icons.hub, 'DIO - Distribuidor Interno Óptico', Colors.purple),
                Divider(color: isDarkMode ? Colors.grey[700] : Colors.grey[300], height: 24),
                Text(
                  'Cabos de Fibra Óptica',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                _buildCableLegendItem('2FO - 2 Fibras', ConfiguracaoCabo.fo2.cor),
                _buildCableLegendItem('4FO - 4 Fibras', ConfiguracaoCabo.fo4.cor),
                _buildCableLegendItem('6FO - 6 Fibras', ConfiguracaoCabo.fo6.cor),
                _buildCableLegendItem('12FO - 12 Fibras', ConfiguracaoCabo.fo12.cor),
                _buildCableLegendItem('24FO - 24 Fibras', ConfiguracaoCabo.fo24.cor),
                _buildCableLegendItem('36FO - 36 Fibras', ConfiguracaoCabo.fo36.cor),
                _buildCableLegendItem('48FO - 48 Fibras', ConfiguracaoCabo.fo48.cor),
                _buildCableLegendItem('72FO - 72 Fibras', ConfiguracaoCabo.fo72.cor),
                _buildCableLegendItem('96FO - 96 Fibras', ConfiguracaoCabo.fo96.cor),
                _buildCableLegendItem('144FO - 144 Fibras', ConfiguracaoCabo.fo144.cor),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Fechar',
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.blue,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Marker _buildCTOMarker(CTOModel cto) {
    final isHighlighted = _highlightedElementId == cto.id && _highlightedElementType == 'CTO';
    if (cto.id == _highlightedElementId) {
      print('DEBUG _buildCTOMarker: CTO ${cto.nome} - id match! isHighlighted=$isHighlighted, type=$_highlightedElementType');
    }
    
    return Marker(
      point: cto.posicao,
      width: 60,
      height: 50,  // Aumentado para acomodar label
      alignment: Alignment.topCenter,
      child: IgnorePointer(
        ignoring: _positionPicker.isActive,
        child: GestureDetector(
          onLongPressStart: (details) {
            _startDraggingPoint(cto.posicao);
          },
          onLongPressMoveUpdate: (details) {
            if (_isDragging) {
              try {
                final point = _mapController.camera.pointToLatLng(
                  math.Point(details.globalPosition.dx, details.globalPosition.dy) as dynamic
                );
                _updateDragPosition(point);
              } catch (e) {
                print('DEBUG: Erro ao converter ponto: $e');
              }
            }
          },
          onLongPressEnd: (details) {
            if (_isDragging) {
              _endDragging();
            }
          },
          onTap: () {
            if (_measurementTool.isActive) {
              setState(() {
                _measurementTool.addPoint(cto.posicao);
              });
              return;
            }
            
            final provider = context.read<InfrastructureProvider>();
            ElementDetailsSheet.showCTO(
            context,
            cto,
            onEdit: () {
              print('DEBUG map_screen: Abrindo CTOFormScreen em modo edição');
              print('DEBUG map_screen: Passando onRequestPositionPick callback');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CTOFormScreen(
                    cto: cto,
                    onRequestPositionPick: () {
                      print('DEBUG map_screen: onRequestPositionPick CHAMADO!');
                      print('DEBUG map_screen: Chamando startPositionPicking(CTO) com ID ${cto.id}');
                      Navigator.pop(context);
                      startPositionPicking('CTO', editingId: cto.id);
                    },
                  ),
                ),
              ).then((_) {
                Navigator.pop(context);
              });
            },
            onDelete: () {
              Navigator.pop(context);
              _confirmDelete('CTO', cto.nome, () => provider.removeCTO(cto.id));
            },
          );
        },
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // Ícone
            Container(
              decoration: isHighlighted
                  ? BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green.withOpacity(0.3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.8),
                          blurRadius: 12,
                          spreadRadius: 4,
                        ),
                      ],
                    )
                  : null,
              child: const Icon(
                Icons.router,
                color: Colors.green,
                size: 32,
              ),
            ),
            // Label
            Positioned(
              top: 32,
              child: Container(
                width: 60,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: Colors.green.withOpacity(0.5), width: 0.5),
                ),
                child: Center(
                  child: Text(
                    cto.nome,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.green,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      ), // Fecha IgnorePointer
    );
  }

  Marker _buildOLTMarker(OLTModel olt) {
    final isHighlighted = _highlightedElementId == olt.id && _highlightedElementType == 'OLT';
    
    return Marker(
      point: olt.posicao,
      width: 60,
      height: 50,  // Aumentado para acomodar label
      alignment: Alignment.topCenter,
      child: IgnorePointer(
        ignoring: _positionPicker.isActive,
        child: GestureDetector(
          onLongPressStart: (details) {
            _startDraggingPoint(olt.posicao);
          },
          onLongPressMoveUpdate: (details) {
            if (_isDragging) {
              try {
                final point = _mapController.camera.pointToLatLng(
                  math.Point(details.globalPosition.dx, details.globalPosition.dy) as dynamic
                );
                _updateDragPosition(point);
              } catch (e) {
                print('DEBUG: Erro ao converter ponto: $e');
              }
            }
          },
          onLongPressEnd: (details) {
            if (_isDragging) {
              _endDragging();
            }
          },
          onTap: () {
            if (_measurementTool.isActive) {
              setState(() {
                _measurementTool.addPoint(olt.posicao);
              });
              return;
            }
            
            final provider = context.read<InfrastructureProvider>();
            ElementDetailsSheet.showOLT(
            context,
            olt,
            onEdit: () {
              print('DEBUG map_screen: Abrindo OLTFormScreen em modo edição');
              print('DEBUG map_screen: Passando onRequestPositionPick callback');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OLTFormScreen(
                    olt: olt,
                    onRequestPositionPick: () {
                      print('DEBUG map_screen: onRequestPositionPick CHAMADO!');
                      print('DEBUG map_screen: Chamando startPositionPicking(OLT) com ID ${olt.id}');
                      Navigator.pop(context);
                      startPositionPicking('OLT', editingId: olt.id);
                    },
                  ),
                ),
              ).then((_) {
                Navigator.pop(context);
              });
            },
            onDelete: () {
              Navigator.pop(context);
              _confirmDelete('OLT', olt.nome, () => provider.removeOLT(olt.id));
            },
          );
        },
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // Ícone
            Container(
              decoration: isHighlighted
                  ? BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.withOpacity(0.3),
                      boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.8), blurRadius: 12, spreadRadius: 4)],
                    )
                  : null,
              child: const Icon(
                Icons.dns,
                color: Colors.red,
                size: 32,
              ),
            ),
            // Label
            Positioned(
              top: 32,
              child: Container(
                width: 60,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: Colors.red.withOpacity(0.5), width: 0.5),
                ),
                child: Center(
                  child: Text(
                    olt.nome,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.red,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      ), // Fecha IgnorePointer
    );
  }

  Marker _buildCEOMarker(CEOModel ceo) {
    final provider = context.read<InfrastructureProvider>();
    final isHighlighted = _highlightedElementId == ceo.id && _highlightedElementType == 'CEO';
    
    return Marker(
      point: ceo.posicao,
      width: 60,
      height: 50,  // Aumentado para acomodar label
      alignment: Alignment.topCenter,
      child: IgnorePointer(
        ignoring: _positionPicker.isActive,
        child: GestureDetector(
          onLongPressStart: (details) {
            _startDraggingPoint(ceo.posicao);
          },
          onLongPressMoveUpdate: (details) {
            if (_isDragging) {
              try {
                final point = _mapController.camera.pointToLatLng(
                  math.Point(details.globalPosition.dx, details.globalPosition.dy) as dynamic
                );
                _updateDragPosition(point);
              } catch (e) {
                print('DEBUG: Erro ao converter ponto: $e');
              }
            }
          },
          onLongPressEnd: (details) {
            if (_isDragging) {
              _endDragging();
            }
          },
          onTap: () {
            if (_measurementTool.isActive) {
              setState(() {
                _measurementTool.addPoint(ceo.posicao);
              });
              return;
            }
            
            ElementDetailsSheet.showCEO(
            context,
            ceo,
            onEdit: () {
              print('DEBUG map_screen: Abrindo CEOFormScreen em modo edição');
              print('DEBUG map_screen: Passando onRequestPositionPick callback');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CEOFormScreen(
                    ceo: ceo,
                    onRequestPositionPick: () {
                      print('DEBUG map_screen: onRequestPositionPick CHAMADO!');
                      print('DEBUG map_screen: Chamando startPositionPicking(CEO) com ID ${ceo.id}');
                      Navigator.pop(context);
                      startPositionPicking('CEO', editingId: ceo.id);
                    },
                  ),
                ),
              ).then((_) {
                Navigator.pop(context);
              });
            },
            onDelete: () {
              Navigator.pop(context);
              _confirmDelete(
                'CEO',
                ceo.nome,
                () => provider.removeCEO(ceo.id),
              );
            },
          );
        },
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // Ícone
            Container(
              decoration: isHighlighted
                  ? BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.orange.withOpacity(0.3),
                      boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.8), blurRadius: 12, spreadRadius: 4)],
                    )
                  : null,
              child: const Icon(
                Icons.settings_ethernet,
                color: Colors.orange,
                size: 32,
              ),
            ),
            // Label
            Positioned(
              top: 32,
              child: Container(
                width: 60,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: Colors.orange.withOpacity(0.5), width: 0.5),
                ),
                child: Center(
                  child: Text(
                    ceo.nome,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.orange,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      ), // Fecha IgnorePointer
    );
  }

  Marker _buildDIOMarker(DIOModel dio) {
    final provider = context.read<InfrastructureProvider>();
    final isHighlighted = _highlightedElementId == dio.id && _highlightedElementType == 'DIO';
    
    return Marker(
      point: dio.posicao,
      width: 60,
      height: 50,  // Aumentado para acomodar label
      alignment: Alignment.topCenter,
      child: IgnorePointer(
        ignoring: _positionPicker.isActive,
        child: GestureDetector(
          onLongPressStart: (details) {
            _startDraggingPoint(dio.posicao);
          },
          onLongPressMoveUpdate: (details) {
            if (_isDragging) {
              try {
                final point = _mapController.camera.pointToLatLng(
                  math.Point(details.globalPosition.dx, details.globalPosition.dy) as dynamic
                );
                _updateDragPosition(point);
              } catch (e) {
                print('DEBUG: Erro ao converter ponto: $e');
              }
            }
          },
          onLongPressEnd: (details) {
            if (_isDragging) {
              _endDragging();
            }
          },
          onTap: () {
            if (_measurementTool.isActive) {
              setState(() {
                _measurementTool.addPoint(dio.posicao);
              });
              return;
            }
            
            ElementDetailsSheet.showDIO(
            context,
            dio,
            onEdit: () {
              print('DEBUG map_screen: Abrindo DIOFormScreen em modo edição');
              print('DEBUG map_screen: Passando onRequestPositionPick callback');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DIOFormScreen(
                    dio: dio,
                    onRequestPositionPick: () {
                      print('DEBUG map_screen: onRequestPositionPick CHAMADO!');
                      print('DEBUG map_screen: Chamando startPositionPicking(DIO) com ID ${dio.id}');
                      Navigator.pop(context);
                      startPositionPicking('DIO', editingId: dio.id);
                    },
                  ),
                ),
              ).then((_) {
                Navigator.pop(context);
              });
            },
            onDelete: () {
              Navigator.pop(context);
              _confirmDelete(
                'DIO',
                dio.nome,
                () => provider.removeDIO(dio.id),
              );
            },
          );
        },
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // Ícone
            Container(
              decoration: isHighlighted
                  ? BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.purple.withOpacity(0.3),
                      boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.8), blurRadius: 12, spreadRadius: 4)],
                    )
                  : null,
              child: const Icon(
                Icons.hub,
                color: Colors.purple,
                size: 32,
              ),
            ),
            // Label
            Positioned(
              top: 32,
              child: Container(
                width: 60,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: Colors.purple.withOpacity(0.5), width: 0.5),
                ),
                child: Center(
                  child: Text(
                    dio.nome,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.purple,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      ), // Fecha IgnorePointer
    );
  }

  /// Constrói polylines INVISÍVEIS com área de clique maior (hitbox)
  List<Polyline> _buildCableHitboxPolylines(List<CaboModel> cabos) {
    // Mesmas otimizações de quantidade
    int maxCables;
    if (_currentZoom < 14) {
      maxCables = 200;
    } else if (_currentZoom < 15) {
      maxCables = 500;
    } else if (_currentZoom < 17) {
      maxCables = 800;
    } else {
      maxCables = cabos.length;
    }
    
    final visibleCabos = _getVisibleCabos(cabos);
    final cabosToRender = visibleCabos.take(maxCables).toList();
    
    return cabosToRender.map((cabo) {
      // IMPORTANTE: Hitbox usa ROTA COMPLETA para cliques precisos
      // Não simplificar a hitbox para garantir que o clique funcione em toda a rota
      
      return Polyline(
        points: cabo.rota, // Rota completa, sem simplificação
        color: Colors.transparent, // Invisível
        // Área de clique MUITO maior que a linha visível
        strokeWidth: _currentZoom < 14 ? 20.0 : (_currentZoom < 16 ? 25.0 : 30.0),
        hitValue: cabo.id, // Associa o ID do cabo à polyline
      );
    }).toList();
  }

  /// Constrói polylines otimizadas de cabos baseado no zoom
  List<Polyline> _buildOptimizedCablePolylines(List<CaboModel> cabos) {
    // Otimização 1: Limitar quantidade total em zooms baixos
    int maxCables;
    if (_currentZoom < 14) {
      maxCables = 200;
    } else if (_currentZoom < 15) {
      maxCables = 500;
    } else if (_currentZoom < 17) {
      maxCables = 800; // NOVO: Limitar até zoom 17
    } else {
      maxCables = cabos.length; // Só mostrar tudo em zoom muito próximo
    }
    
    // Otimização 2: Culling - renderizar apenas cabos visíveis
    final visibleCabos = _getVisibleCabos(cabos);
    final cabosToRender = visibleCabos.take(maxCables).toList();
    
    return cabosToRender.map((cabo) {
      // Otimização 3: Simplificar geometria em zooms baixos
      final simplifiedRoute = _simplifyRoute(cabo.rota, _currentZoom);
      
      return Polyline(
        points: simplifiedRoute,
        color: _getCaboColor(cabo),
        strokeWidth: _currentZoom < 14 ? 2.0 : (_currentZoom < 16 ? 3.0 : 4.0),
      );
    }).toList();
  }
  
  /// VIEWPORT CULLING: Filtra elementos que estão visíveis no viewport atual
  /// Reduz drasticamente a quantidade de elementos renderizados fora da tela
  bool _isPointInViewport(LatLng point) {
    try {
      final bounds = _mapController.camera.visibleBounds;
      // Margem adicional para que elementos apareçam suavemente ao entrar na tela
      final latDelta = (bounds.north - bounds.south) * 0.5; // 50% de margem (maior buffer)
      final lngDelta = (bounds.east - bounds.west) * 0.5;
      
      final expandedNorth = bounds.north + latDelta;
      final expandedSouth = bounds.south - latDelta;
      final expandedEast = bounds.east + lngDelta;
      final expandedWest = bounds.west - lngDelta;
      
      return point.latitude >= expandedSouth &&
             point.latitude <= expandedNorth &&
             point.longitude >= expandedWest &&
             point.longitude <= expandedEast;
    } catch (e) {
      // Se o mapa não foi inicializado, retornar true para renderizar
      return true;
    }
  }

  /// Filtra cabos que estão visíveis no viewport atual
  List<CaboModel> _getVisibleCabos(List<CaboModel> cabos) {
    // Verificar se o mapa já foi inicializado
    try {
      // Obter bounds da tela com margem
      final bounds = _mapController.camera.visibleBounds;
      final latDelta = (bounds.north - bounds.south) * 0.2; // 20% de margem
      final lngDelta = (bounds.east - bounds.west) * 0.2;
      
      final expandedNorth = bounds.north + latDelta;
      final expandedSouth = bounds.south - latDelta;
      final expandedEast = bounds.east + lngDelta;
      final expandedWest = bounds.west - lngDelta;
      
      return cabos.where((cabo) {
        // Verificar se algum ponto do cabo está visível
        return cabo.rota.any((point) =>
          point.latitude >= expandedSouth &&
          point.latitude <= expandedNorth &&
          point.longitude >= expandedWest &&
          point.longitude <= expandedEast
        );
      }).toList();
    } catch (e) {
      // Se o mapa não foi inicializado ainda, retornar todos os cabos
      return cabos;
    }
  }

  /// DESATIVADO: Simplificação removida para preservar rotas exatas
  /// Sempre retorna a rota completa
  List<LatLng> _simplifyRoute(List<LatLng> route, double zoom) {
    // Sempre retornar rota completa - sem simplificação
    return route;
  }

  Color _getCaboColor(CaboModel cabo) {
    // Retorna a cor específica do tipo de cabo
    return cabo.configuracao.cor;
  }

  /// Detecta clique em cabos sem usar marcadores invisíveis (muito mais eficiente!)
  void _handleMapTap(LatLng tapPoint, BuildContext context) {
    final provider = context.read<InfrastructureProvider>();
    
    // Só verificar cabos visíveis e renderizados
    int maxCables;
    if (_currentZoom < 14) {
      maxCables = 200;
    } else if (_currentZoom < 15) {
      maxCables = 500;
    } else if (_currentZoom < 17) {
      maxCables = 800;
    } else {
      maxCables = provider.cabos.length;
    }
    
    final cabosVisiveis = _getVisibleCabos(provider.cabos).take(maxCables).toList();
    
    // Tolerância MAIOR para facilitar o clique (mesma da hitbox)
    final toleranciaMetros = _currentZoom >= 16 
        ? 15.0  // ~15 pixels em zoom alto
        : (_currentZoom >= 14 
            ? 20.0  // ~20 pixels em zoom médio
            : 25.0); // ~25 pixels em zoom baixo
    
    CaboModel? caboClicado;
    double menorDistancia = double.infinity;
    
    // Percorrer todos os cabos visíveis
    for (final cabo in cabosVisiveis) {
      // IMPORTANTE: Usar rota COMPLETA para detecção de cliques
      // Garante que o usuário possa clicar em qualquer parte do cabo
      
      // Verificar cada segmento do cabo
      for (int i = 0; i < cabo.rota.length - 1; i++) {
        final p1 = cabo.rota[i];
        final p2 = cabo.rota[i + 1];
        
        // Calcular distância do ponto clicado ao segmento (em graus)
        final distanciaGraus = _distanciaAoSegmento(tapPoint, p1, p2);
        
        // Converter para metros (aproximadamente)
        final distanciaMetros = distanciaGraus * 111000;
        
        // Converter tolerância em metros para graus baseado no zoom
        final toleranciaGraus = toleranciaMetros / (_mapController.camera.zoom * 1000);
        
        if (distanciaGraus < toleranciaGraus && distanciaMetros < menorDistancia) {
          menorDistancia = distanciaMetros;
          caboClicado = cabo;
        }
      }
    }
    
    // Se encontrou um cabo próximo, abrir detalhes
    if (caboClicado != null) {
      ElementDetailsSheet.showCabo(
        context,
        caboClicado,
        onEdit: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CaboFormScreen(
                cabo: caboClicado,
                onRequestRoutePick: () {
                  Navigator.pop(context);
                  startPositionPicking('Cabo', editingId: caboClicado!.id);
                },
              ),
            ),
          );
        },
        onDelete: () {
          Navigator.pop(context);
          _confirmDelete(
            'Cabo',
            caboClicado!.nome,
            () => provider.removeCabo(caboClicado!.id),
          );
        },
      );
    }
  }

  /// Calcula raio de clustering DINÂMICO baseado em zoom + quantidade de itens
  double _calculateDynamicClusterRadius(int totalItems) {
    // Desabilitar clustering em zoom muito alto (zoom 17+)
    if (_currentZoom >= 17) {
      return 0; // Nenhum clustering
    }
    
    // SENSÍVEL: Agrupa itens muito próximos
    final itensPorCluster = 2.0;
    final cluster = (totalItems / itensPorCluster).ceil();
    
    // Matriz de clustering por zoom
    if (_currentZoom < 10) {
      // Zoom muito baixo: clustering agressivo
      return math.min(200.0, 100.0 + (cluster * 2.0).toDouble());
    } else if (_currentZoom < 12) {
      // Zoom baixo: clustering moderado
      return math.min(150.0, 80.0 + (cluster * 1.5).toDouble());
    } else if (_currentZoom < 14) {
      // Zoom médio: clustering leve
      return math.min(100.0, 50.0 + (cluster * 1.0).toDouble());
    } else if (_currentZoom < 16) {
      // Zoom alto: clustering bem leve
      return math.min(60.0, 30.0 + (cluster * 0.5).toDouble());
    } else {
      // Zoom muito alto: sem clustering
      return 0;
    }
  }

  /// Calcula a distância mínima de um ponto a um segmento de linha
  double _distanciaAoSegmento(LatLng ponto, LatLng segmentoP1, LatLng segmentoP2) {
    final x = ponto.longitude;
    final y = ponto.latitude;
    final x1 = segmentoP1.longitude;
    final y1 = segmentoP1.latitude;
    final x2 = segmentoP2.longitude;
    final y2 = segmentoP2.latitude;
    
    final A = x - x1;
    final B = y - y1;
    final C = x2 - x1;
    final D = y2 - y1;
    
    final dot = A * C + B * D;
    final lenSq = C * C + D * D;
    
    double param = -1;
    if (lenSq != 0) {
      param = dot / lenSq;
    }
    
    double xx, yy;
    
    if (param < 0) {
      xx = x1;
      yy = y1;
    } else if (param > 1) {
      xx = x2;
      yy = y2;
    } else {
      xx = x1 + param * C;
      yy = y1 + param * D;
    }
    
    final dx = x - xx;
    final dy = y - yy;
    
    return math.sqrt(dx * dx + dy * dy);
  }

  
  IconData _getPositionPickerIcon() {
    switch (_positionPicker.elementType) {
      case 'CTO':
        return Icons.router;
      case 'OLT':
        return Icons.dns;
      case 'CEO':
        return Icons.settings_ethernet;
      case 'DIO':
        return Icons.hub;
      default:
        return Icons.place;
    }
  }
  
  void _handlePositionConfirm() {
    print('DEBUG MapScreen _handlePositionConfirm: iniciado');
    print('DEBUG MapScreen canConfirm: ${_positionPicker.canConfirm}');
    
    if (!_positionPicker.canConfirm) {
      print('DEBUG MapScreen: canConfirm = false, abortando');
      return;
    }
    
    final elementType = _positionPicker.elementType ?? '';
    final editingId = _positionPicker.editingElementId;
    print('DEBUG MapScreen elementType: $elementType');
    print('DEBUG MapScreen editingId: $editingId');
    print('DEBUG MapScreen isEditing: ${_positionPicker.isEditing}');
    print('DEBUG MapScreen isRouteMode: ${_positionPicker.isRouteMode}');
    
    // Se estamos editando, atualizamos o elemento existente diretamente
    if (_positionPicker.isEditing && editingId != null) {
      final provider = context.read<InfrastructureProvider>();
      
      if (_positionPicker.isRouteMode) {
        // Atualizar rota do cabo
        print('DEBUG MapScreen: Atualizando rota do Cabo ID=$editingId');
        final cabo = provider.cabos.firstWhere((c) => c.id == editingId);
        final updatedCabo = CaboModel(
          id: cabo.id,
          nome: cabo.nome,
          descricao: cabo.descricao,
          rota: List<LatLng>.from(_positionPicker.route),
          configuracao: cabo.configuracao,
          tipoInstalacao: cabo.tipoInstalacao,
          metragem: cabo.metragem,
          tubos: cabo.tubos,
          pontoInicioId: cabo.pontoInicioId,
          pontoFimId: cabo.pontoFimId,
          elementosIntermediariosIds: cabo.elementosIntermediariosIds,
          dataCriacao: cabo.dataCriacao,
        );
        provider.updateCabo(updatedCabo);
      } else if (_positionPicker.selectedPosition != null) {
        // Atualizar posição do elemento
        final position = _positionPicker.selectedPosition!;
        print('DEBUG MapScreen: Atualizando posição de $elementType ID=$editingId');
        
        switch (elementType) {
          case 'CTO':
            final cto = provider.ctos.firstWhere((c) => c.id == editingId);
            final updated = CTOModel(
              id: cto.id,
              nome: cto.nome,
              posicao: position,
              numeroCTO: cto.numeroCTO,
              numeroPortas: cto.numeroPortas,
              tipoSplitter: cto.tipoSplitter,
              descricao: cto.descricao,
              dataCriacao: cto.dataCriacao,
            );
            provider.updateCTO(updated);
            break;
          case 'OLT':
            final olt = provider.olts.firstWhere((o) => o.id == editingId);
            final updated = OLTModel(
              id: olt.id,
              nome: olt.nome,
              posicao: position,
              ipAddress: olt.ipAddress,
              numeroSlots: olt.numeroSlots,
              slots: olt.slots,
              fabricante: olt.fabricante,
              modelo: olt.modelo,
              cabosConectadosIds: olt.cabosConectadosIds,
              descricao: olt.descricao,
              dataCriacao: olt.dataCriacao,
            );
            provider.updateOLT(updated);
            break;
          case 'CEO':
            final ceo = provider.ceos.firstWhere((c) => c.id == editingId);
            final updated = CEOModel(
              id: ceo.id,
              nome: ceo.nome,
              posicao: position,
              capacidadeFusoes: ceo.capacidadeFusoes,
              tipo: ceo.tipo,
              fusoes: ceo.fusoes,
              numeroCEO: ceo.numeroCEO,
              cabosConectadosIds: ceo.cabosConectadosIds,
              descricao: ceo.descricao,
              dataCriacao: ceo.dataCriacao,
            );
            provider.updateCEO(updated);
            break;
          case 'DIO':
            final dio = provider.dios.firstWhere((d) => d.id == editingId);
            final updated = DIOModel(
              id: dio.id,
              nome: dio.nome,
              posicao: position,
              numeroPortas: dio.numeroPortas,
              descricao: dio.descricao,
              dataCriacao: dio.dataCriacao,
            );
            provider.updateDIO(updated);
            break;
        }
      }
      
      // Limpar picker e fechar
      setState(() {
        _positionPicker.clear();
        _highlightedElementId = null;
        _highlightedElementType = null;
      });
      
      // Notificar que position picker foi desativado
      widget.onPositionPickerModeChanged?.call(false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Localização de $elementType atualizada!'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }
    
    // Se não estamos editando, seguir o fluxo normal de criação
    // MAS: se há um formulário em bottom sheet aberto, fechar e reabrir com dados atualizados
    if (_formSheetOpen && !_positionPicker.isEditing) {
      print('DEBUG MapScreen: Formulário em bottom sheet aberto, reabrindo com posição atualizada');
      // Fechar o bottom sheet atual
      Navigator.pop(context);
      // Agora o .then() do anterior não vai interferir porque já detectou que formSheetOpen=true
      
      // Reagendar para abrir novo formulário APÓS este bottom sheet fechar
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _handlePositionConfirm(); // Chamar novamente para abrir novo formulário
        }
      });
      return;
    }
    
    // Caso contrário, criar novo formulário normalmente
    Widget? formScreen;
    if (_positionPicker.isRouteMode) {
      print('DEBUG MapScreen: Modo rota, criando CaboFormScreen');
      print('DEBUG MapScreen: route.length = ${_positionPicker.route.length}');
      
      // IMPORTANTE: Criar cópia da rota ANTES de limpar o picker
      final routeCopy = List<LatLng>.from(_positionPicker.route);
      print('DEBUG MapScreen: routeCopy.length = ${routeCopy.length}');
      
      // Cabo - passa a rota e callback para redesenhar
      formScreen = CaboFormScreen(
        initialRoute: routeCopy,  // ← Passa a CÓPIA
        onRequestRoutePick: () {
          // Reativar position picker em modo rota
          setState(() {
            _positionPicker.startRoute(elementType);
          });
        },
      );
    } else if (_positionPicker.selectedPosition != null) {
      print('DEBUG MapScreen: Modo single point');
      // Itens pontuais - passa a posição e callback
      final position = _positionPicker.selectedPosition!;
      final onRequestPick = () {
        // Reativar position picker em modo single point
        // IMPORTANTE: Fechar o bottom sheet primeiro para picker ficar visível
        Navigator.of(context).pop();
        
        setState(() {
          _positionPicker.startSinglePoint(elementType);
        });
      };
      
      switch (elementType) {
        case 'CTO':
          formScreen = CTOFormScreen(
            initialPosition: position,
            onRequestPositionPick: onRequestPick,
          );
          break;
        case 'OLT':
          formScreen = OLTFormScreen(
            initialPosition: position,
            onRequestPositionPick: onRequestPick,
          );
          break;
        case 'CEO':
          formScreen = CEOFormScreen(
            initialPosition: position,
            onRequestPositionPick: onRequestPick,
          );
          break;
        case 'DIO':
          formScreen = DIOFormScreen(
            initialPosition: position,
            onRequestPositionPick: onRequestPick,
          );
          break;
      }
    }
    
    print('DEBUG MapScreen: formScreen != null? ${formScreen != null}');
    
    if (formScreen != null) {
      print('DEBUG MapScreen: Abrindo formulário');
      // Marcar que há um formulário em bottom sheet aberto
      _formSheetOpen = true;
      
      // NÃO limpar position picker - deixar disponível para "Editar Localização"
      
      // Abrir formulário via bottom sheet
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.95,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: formScreen!,
          ),
        ),
      ).then((_) {
        // Quando o bottom sheet fecha
        _formSheetOpen = false;
        
        // Checar se é porque:
        // 1. Usuário salvou/cancelou (limpar tudo)
        // 2. Usuário quer editar localização (deixar position picker ativo)
        if (mounted) {
          if (!_positionPicker.isActive) {
            // Case 1: Bottom sheet fechou porque formulário foi salvo/cancelado
            // Limpar posição picker pois não será mais usado
            setState(() {
              _positionPicker.clear();
              _highlightedElementId = null;
              _highlightedElementType = null;
            });
            widget.onPositionPickerModeChanged?.call(false);
          } else {
            // Case 2: Position picker está ativo, formulário foi apenas "pausado"
            print('DEBUG MapScreen: Position picker ativo, aguardando seleção de localização');
            // Não fazer nada - deixar o picker ativo
          }
        }
      });
      print('DEBUG MapScreen: showModalBottomSheet chamado');
    } else {
      print('DEBUG MapScreen: formScreen é null, não abrindo nada');
    }
  }

  void _confirmDelete(String tipo, String nome, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Excluir $tipo?'),
        content: Text('Deseja realmente excluir "$nome"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
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
}

/// Dialog de progresso para download de tiles offline
