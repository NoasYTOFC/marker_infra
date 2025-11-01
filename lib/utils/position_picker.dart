import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Ferramenta para escolher posições no mapa antes de criar elementos
class PositionPicker {
  LatLng? selectedPosition;
  List<LatLng> route = []; // Para cabos
  bool isActive = false;
  bool isRouteMode = false; // true para cabos, false para itens pontuais
  String? elementType; // 'CTO', 'OLT', 'CEO', 'DIO', 'Cabo'
  String? editingElementId; // ID do elemento sendo editado (null = criando novo)

  void startSinglePoint(String type, {String? editingId}) {
    elementType = type;
    isActive = true;
    isRouteMode = false;
    selectedPosition = null;
    editingElementId = editingId;
  }

  void startRoute(String type, {String? editingId}) {
    elementType = type;
    isActive = true;
    isRouteMode = true;
    route.clear();
    editingElementId = editingId;
  }

  void addPoint(LatLng point) {
    if (isRouteMode) {
      route.add(point);
    } else {
      selectedPosition = point;
    }
  }

  void setSelectedPosition(LatLng position) {
    if (!isRouteMode) {
      selectedPosition = position;
    }
  }

  void removeLastRoutePoint() {
    if (route.isNotEmpty) {
      route.removeLast();
    }
  }

  void clear() {
    selectedPosition = null;
    route.clear();
    isActive = false;
    isRouteMode = false;
    elementType = null;
    editingElementId = null;
  }

  bool get isEditing => editingElementId != null;

  bool get canConfirm {
    if (isRouteMode) {
      return route.length >= 2; // Cabo precisa de pelo menos 2 pontos
    } else {
      return selectedPosition != null; // Item precisa de 1 ponto
    }
  }

  String getInstructions() {
    if (!isActive) return '';
    
    if (isRouteMode) {
      if (route.isEmpty) {
        return 'Clique no mapa para começar a rota do cabo';
      } else if (route.length == 1) {
        return 'Clique para adicionar pontos. Mínimo 2 pontos para confirmar.';
      } else {
        return '${route.length} pontos marcados. Adicione mais ou confirme.';
      }
    } else {
      if (selectedPosition == null) {
        return 'Clique no mapa para escolher a localização do $elementType';
      } else {
        return 'Localização selecionada. Confirme para continuar.';
      }
    }
  }
}

/// Widget de controles do position picker
class PositionPickerControls extends StatefulWidget {
  final PositionPicker picker;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final VoidCallback? onUndo;

  const PositionPickerControls({
    super.key,
    required this.picker,
    required this.onConfirm,
    required this.onCancel,
    this.onUndo,
  });

  @override
  State<PositionPickerControls> createState() => _PositionPickerControlsState();
}

class _PositionPickerControlsState extends State<PositionPickerControls> {
  late TextEditingController _latController;
  late TextEditingController _lngController;
  late TextEditingController _combinedController;
  bool _showCoordinateInputs = false;
  String? _coordinateError;

  @override
  void initState() {
    super.initState();
    _latController = TextEditingController();
    _lngController = TextEditingController();
    _combinedController = TextEditingController();
    
    // Se houver uma posição selecionada, popular os campos
    if (widget.picker.selectedPosition != null) {
      _updateFromPosition(widget.picker.selectedPosition!);
    }
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    _combinedController.dispose();
    super.dispose();
  }

  void _updateFromPosition(LatLng position) {
    _latController.text = position.latitude.toStringAsFixed(6);
    _lngController.text = position.longitude.toStringAsFixed(6);
    _combinedController.text = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
  }

  void _applyCoordinates() {
    try {
      late double lat;
      late double lng;
      
      final combinedText = _combinedController.text.trim();
      if (combinedText.isNotEmpty) {
        // Formato combinado
        final parts = combinedText.split(',').map((p) => p.trim()).toList();
        if (parts.length != 2) {
          setState(() => _coordinateError = 'Formato: lat, lng');
          return;
        }
        lat = double.parse(parts[0]);
        lng = double.parse(parts[1]);
      } else {
        // Formato separado (fallback)
        lat = double.parse(_latController.text.trim());
        lng = double.parse(_lngController.text.trim());
      }
      
      if (lat < -90 || lat > 90) {
        setState(() => _coordinateError = 'Latitude: -90 a 90');
        return;
      }
      if (lng < -180 || lng > 180) {
        setState(() => _coordinateError = 'Longitude: -180 a 180');
        return;
      }
      
      final newLocation = LatLng(lat, lng);
      widget.picker.setSelectedPosition(newLocation);
      
      setState(() => _coordinateError = null);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Coordenadas atualizadas!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      setState(() => _coordinateError = 'Valores inválidos');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Título
            Row(
              children: [
                Icon(
                  _getIcon(),
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.picker.editingElementId != null
                        ? 'Editar ${widget.picker.elementType}'
                        : 'Adicionar ${widget.picker.elementType}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Instruções
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.blue.withOpacity(0.2) : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, 
                    color: isDarkMode ? Colors.blue[300] : Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.picker.getInstructions(),
                      style: TextStyle(
                        color: isDarkMode ? Colors.blue[200] : Colors.blue.shade900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // Informações
            if (widget.picker.isRouteMode && widget.picker.route.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Pontos: ${widget.picker.route.length}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            
            // Campos de coordenadas (apenas para single point)
            if (!widget.picker.isRouteMode) ...[
              ExpansionTile(
                title: const Row(
                  children: [
                    Icon(Icons.edit_location_alt, size: 18),
                    SizedBox(width: 8),
                    Text('Inserir Coordenadas'),
                  ],
                ),
                initiallyExpanded: _showCoordinateInputs,
                onExpansionChanged: (expanded) {
                  setState(() => _showCoordinateInputs = expanded);
                },
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _combinedController,
                          keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Coordenadas',
                            hintText: '-12.1367, -38.4208',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.location_on),
                            helperText: 'Formato: Latitude, Longitude',
                            errorText: _coordinateError,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _applyCoordinates,
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Aplicar Coordenadas'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            
            // Botões de ação
            Row(
              children: [
                // Desfazer (apenas para rotas)
                if (widget.picker.isRouteMode && widget.picker.route.isNotEmpty && widget.onUndo != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.onUndo,
                      icon: const Icon(Icons.undo),
                      label: const Text('Desfazer'),
                    ),
                  ),
                if (widget.picker.isRouteMode && widget.picker.route.isNotEmpty && widget.onUndo != null)
                  const SizedBox(width: 8),
                
                // Cancelar
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 8),
                
                // Confirmar
                Expanded(
                  flex: widget.picker.isRouteMode ? 1 : 2,
                  child: FilledButton.icon(
                    onPressed: widget.picker.canConfirm ? widget.onConfirm : null,
                    icon: const Icon(Icons.check),
                    label: const Text('OK'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (widget.picker.elementType) {
      case 'CTO':
        return Icons.router;
      case 'OLT':
        return Icons.dns;
      case 'CEO':
        return Icons.settings_ethernet;
      case 'DIO':
        return Icons.hub;
      case 'Cabo':
        return Icons.cable;
      default:
        return Icons.place;
    }
  }
}
