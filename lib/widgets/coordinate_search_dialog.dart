import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class CoordinateSearchDialog extends StatefulWidget {
  final Function(LatLng) onSearch;
  
  const CoordinateSearchDialog({
    super.key,
    required this.onSearch,
  });

  @override
  State<CoordinateSearchDialog> createState() => _CoordinateSearchDialogState();
}

class _CoordinateSearchDialogState extends State<CoordinateSearchDialog> {
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _combinedController = TextEditingController();
  bool _useCombined = true; // Default to combined format
  String? _error;

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    _combinedController.dispose();
    super.dispose();
  }

  void _search() {
    try {
      late LatLng location;
      
      if (_useCombined) {
        final text = _combinedController.text.trim();
        if (text.isEmpty) {
          setState(() => _error = 'Digite as coordenadas');
          return;
        }
        
        // Tentar parse: "-12.1367, -38.4208" ou "-12.1367,-38.4208"
        final parts = text.split(',').map((p) => p.trim()).toList();
        if (parts.length != 2) {
          setState(() => _error = 'Formato: lat,lng (ex: -12.1367, -38.4208)');
          return;
        }
        
        final lat = double.parse(parts[0]);
        final lng = double.parse(parts[1]);
        
        // Validar ranges
        if (lat < -90 || lat > 90) {
          setState(() => _error = 'Latitude deve estar entre -90 e 90');
          return;
        }
        if (lng < -180 || lng > 180) {
          setState(() => _error = 'Longitude deve estar entre -180 e 180');
          return;
        }
        
        location = LatLng(lat, lng);
      } else {
        final latText = _latController.text.trim();
        final lngText = _lngController.text.trim();
        
        if (latText.isEmpty || lngText.isEmpty) {
          setState(() => _error = 'Preencha latitude e longitude');
          return;
        }
        
        final lat = double.parse(latText);
        final lng = double.parse(lngText);
        
        if (lat < -90 || lat > 90) {
          setState(() => _error = 'Latitude deve estar entre -90 e 90');
          return;
        }
        if (lng < -180 || lng > 180) {
          setState(() => _error = 'Longitude deve estar entre -180 e 180');
          return;
        }
        
        location = LatLng(lat, lng);
      }
      
      widget.onSearch(location);
      Navigator.pop(context);
    } catch (e) {
      setState(() => _error = 'Valores inválidos. Use números decimais');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('🔍 Pesquisar Coordenadas'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Toggle entre modo combinado e separado
            Row(
              children: [
                Expanded(
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: false,
                        label: Text('Separado'),
                        icon: Icon(Icons.splitscreen),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text('Combinado'),
                        icon: Icon(Icons.merge),
                      ),
                    ],
                    selected: {_useCombined},
                    onSelectionChanged: (selected) {
                      setState(() {
                        _useCombined = selected.first;
                        _error = null;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Modo combinado
            if (_useCombined) ...[
              TextField(
                controller: _combinedController,
                keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                decoration: InputDecoration(
                  labelText: 'Coordenadas',
                  hintText: '-12.1367, -38.4208',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                  errorText: _error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Formato: Latitude, Longitude',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ] else ...[
              // Modo separado
              TextField(
                controller: _latController,
                keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                decoration: InputDecoration(
                  labelText: 'Latitude',
                  hintText: '-12.1367',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.north),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _lngController,
                keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                decoration: InputDecoration(
                  labelText: 'Longitude',
                  hintText: '-38.4208',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.east),
                  errorText: _error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Latitude: -90 a 90 | Longitude: -180 a 180',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 16),
            
            // Dica
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue.shade700, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'O mapa será centralizado nesta coordenada',
                      style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _search,
          icon: const Icon(Icons.check),
          label: const Text('Pesquisar'),
        ),
      ],
    );
  }
}
