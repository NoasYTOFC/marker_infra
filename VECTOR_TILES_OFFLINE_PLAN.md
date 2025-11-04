# Plano de Implementação - Vector Tiles Offline (Nordeste)

## 📋 Visão Geral

Substituir/complementar raster tiles (PNG) com **vector tiles** para download offline da região do Nordeste do Brasil.

### 🎯 Benefícios
- **Tamanho**: Vector tiles = 10-50x menor que raster
- **Qualidade**: Renderização em qualquer resolução
- **Offline**: Mapbox Vector Tile format (MVT) em MBTiles
- **Funcionalidade**: Suporta estilos, themes, etc

## 🏗️ Arquitetura

### Opções de Biblioteca

| Biblioteca | Uso | Tamanho | Offline | Status |
|-----------|-----|--------|---------|--------|
| `vector_map_tiles` | Base para vector tiles | Pequeno | ✅ | Estável |
| `vector_map_tiles_mbtiles` | Provider MBTiles offline | N/A | ✅✅ | Recomendado |
| `mbtiles` | Parsing MBTiles | N/A | ✅✅ | Core |
| `maplibre` | Alternativa completa | Grande | ✅ | Overkill |

**Escolha:** `vector_map_tiles` + `vector_map_tiles_mbtiles`

### Formato MBTiles
```
MBTiles = SQLite + Tiles em PNG/MVT
Estrutura:
  metadata table (version, minzoom, maxzoom, bounds)
  tiles table (zoom_level, tile_column, tile_row, tile_data)
  images table (tile_data)
```

## 🗺️ Fluxo de Download

### 1️⃣ Download offline (Novo Botão)
```
[Baixar Mapa Nordeste] 
    ↓
Selecionar zoom levels (12-18)
    ↓
Mostrar área de cobertura no mapa
    ↓
Calcular tamanho (~500MB para vector)
    ↓
Começar download com progresso
    ↓
Salvar em ~/.config/marker_infra/offline_maps/nordeste.mbtiles
    ↓
Registrar no SQLite (próxima feature)
```

### 2️⃣ Carregamento no app
```
Abrir app
    ↓
Verificar se offline_maps/nordeste.mbtiles existe
    ↓
Se sim → usar VectorTileProvider(mbtilesPath)
    ↓
Se não → usar TileLayer normal (com cache)
```

### 3️⃣ Offline total
```
Sem internet + MBTiles carregado
    ↓
Todos os tiles vêm do arquivo local
    ↓
Performance excelente
    ↓
Sem X's de erro
```

## 💾 Dados de Origem

### Opções para vector tiles do Nordeste

1. **OpenMapTiles (Recomendado)**
   - URL: `https://data.maptiler.com/downloads/nordeste-tiles.mbtiles`
   - Tamanho: ~200-500MB para zoom 0-18
   - Cobertura: Mundo inteiro ou recorte regional

2. **Mapbox Vector Tiles**
   - URL: `https://tile.mapbox.com/data/mapbox.mapbox-streets-v8`
   - Requer API key
   - Melhor qualidade de dados

3. **Overpass API + Tippecanoe**
   - Baixar dados OSM do Nordeste
   - Converter para MVT usando `tippecanoe`
   - Empacotar em MBTiles
   - Mais controle, mas complexo

**Escolha:** OpenMapTiles (mais simples, boa qualidade)

## 📦 Implementação

### Etapa 1: Adicionar Dependências
```yaml
dependencies:
  vector_map_tiles: ^8.0.0
  vector_map_tiles_mbtiles: ^1.2.0
  mbtiles: ^0.4.2
```

### Etapa 2: Criar VectorTileProvider

```dart
// lib/services/vector_tile_provider.dart

class VectorTileProvider {
  final String mbtilesPath;
  
  VectorTileProvider({required this.mbtilesPath});
  
  /// Verificar se MBTiles existe
  Future<bool> isCached() async {
    return await File(mbtilesPath).exists();
  }
  
  /// Criar layer para flutter_map
  VectorTileLayer buildLayer() {
    return VectorTileLayer(
      tileProvider: MBTilesVectorTileProvider(
        mbtilesPath: mbtilesPath,
      ),
      theme: _buildTheme(), // Style customizado
    );
  }
  
  /// Deletar arquivo MBTiles
  Future<void> delete() async {
    final file = File(mbtilesPath);
    if (await file.exists()) {
      await file.delete();
    }
  }
  
  /// Obter informações do arquivo
  Future<Map<String, dynamic>> getInfo() async {
    // Usar mbtiles package para ler metadata
    final db = await MBTilesDb.open(mbtilesPath);
    final metadata = await db.metadata();
    return {
      'name': metadata.name,
      'version': metadata.version,
      'minzoom': metadata.minZoom,
      'maxzoom': metadata.maxZoom,
      'bounds': metadata.bounds,
      'fileSize': await File(mbtilesPath).length(),
    };
  }
}
```

### Etapa 3: UI para Download

```dart
// lib/screens/offline_map_screen.dart

class OfflineMapScreen extends StatefulWidget {
  @override
  State<OfflineMapScreen> createState() => _OfflineMapScreenState();
}

class _OfflineMapScreenState extends State<OfflineMapScreen> {
  bool _downloading = false;
  double _progress = 0.0;
  String _statusMessage = '';
  
  Future<void> _downloadNordeste() async {
    setState(() => _downloading = true);
    
    try {
      // 1. Mostrar área de cobertura
      final bounds = LatLngBounds(
        LatLng(-5.0, -35.0),  // NW Nordeste
        LatLng(-10.0, -44.0), // SE Nordeste
      );
      
      // 2. Calcular tiles necessários
      final tileCount = _calculateTiles(bounds, minZoom: 12, maxZoom: 18);
      setState(() => _statusMessage = 'Calculado: $tileCount tiles (~500MB)');
      
      // 3. Mostrar confirmação
      if (!mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Baixar Mapa do Nordeste?'),
          content: Text('$tileCount tiles\nTamanho: ~500MB\nTempo: ~30min'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancelar')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('Confirmar')),
          ],
        ),
      );
      
      if (confirm != true) return;
      
      // 4. Começar download
      final nordestePath = await _getNordesteMapPath();
      
      setState(() => _statusMessage = 'Iniciando download...');
      
      // Implementar download com progresso
      // await _downloadMBTiles(bounds, nordestePath);
      
      setState(() => _statusMessage = '✅ Download concluído!');
      
    } catch (e) {
      setState(() => _statusMessage = '❌ Erro: $e');
    } finally {
      setState(() => _downloading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mapas Offline')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _downloading ? null : _downloadNordeste,
              child: Text(_downloading ? 'Baixando...' : 'Baixar Nordeste'),
            ),
            if (_downloading) ...[
              SizedBox(height: 20),
              CircularProgressIndicator(value: _progress),
              SizedBox(height: 10),
              Text('$_statusMessage\n${(_progress * 100).toStringAsFixed(1)}%'),
            ],
          ],
        ),
      ),
    );
  }
}
```

### Etapa 4: Integrar com MapScreen

```dart
// lib/screens/map_screen.dart

class MapScreenState extends State<MapScreen> {
  bool _useVectorTiles = false;
  VectorTileProvider? _vectorTileProvider;
  
  @override
  void initState() {
    super.initState();
    _checkForOfflineMap();
  }
  
  Future<void> _checkForOfflineMap() async {
    final path = await _getNordesteMapPath();
    final exists = await File(path).exists();
    
    if (exists) {
      setState(() {
        _useVectorTiles = true;
        _vectorTileProvider = VectorTileProvider(mbtilesPath: path);
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      children: [
        if (_useVectorTiles && _vectorTileProvider != null)
          _vectorTileProvider!.buildLayer()
        else
          TileLayer(
            tileProvider: CachedTileProvider(),
          ),
        // ... resto do mapa
      ],
    );
  }
}
```

## 🎨 Styling

### VectorTileTheme Customizado

```dart
VectorTileTheme buildTheme() {
  return VectorTileTheme(
    layers: [
      // Camada de ruas
      VectorTileLayer(
        name: 'roads',
        minZoom: 0,
        maxZoom: 24,
        paint: {
          'line-color': Colors.grey.toHexString(),
          'line-width': 2,
        },
      ),
      // Camada de edifícios
      VectorTileLayer(
        name: 'buildings',
        minZoom: 14,
        paint: {
          'fill-color': Colors.blue.toHexString(),
          'fill-opacity': 0.3,
        },
      ),
      // Sua customização aqui...
    ],
  );
}
```

## 📊 Comparação: Raster vs Vector

| Aspecto | Raster (OSM) | Vector (MVT) |
|---------|-------------|------------|
| Tamanho | 500MB-2GB | 50-500MB |
| Qualidade zoom | Pixelado em zoom alto | Perfeito em qualquer zoom |
| Offline | ✅ (muito espaço) | ✅✅ (compacto) |
| Performance | Média | Excelente |
| Customização | Nenhuma | Muito (temas, cores) |
| Download | Rápido inicial | Médio |
| Atualização | Manual (retira tudo) | Via patch files |

## 🚀 Próximos Passos

1. ✅ Definir arquitetura (este documento)
2. ⏳ Adicionar dependências ao pubspec.yaml
3. ⏳ Implementar VectorTileProvider
4. ⏳ Criar UI de download (OfflineMapScreen)
5. ⏳ Integrar com MapScreen
6. ⏳ Testar offline
7. ⏳ Otimizar tamanho/performance

## 💾 Armazenamento

```
~/.config/marker_infra/
  ├── tile_cache/          # Raster tiles (cache)
  │   ├── 18/103097/...
  │   └── ...
  └── offline_maps/        # Offline completo (MBTiles)
      └── nordeste.mbtiles (~500MB)
```

## 🔍 Referências

- [vector_map_tiles docs](https://pub.dev/packages/vector_map_tiles)
- [vector_map_tiles_mbtiles](https://pub.dev/packages/vector_map_tiles_mbtiles)
- [MBTiles spec](https://github.com/mapbox/mbtiles-spec)
- [OpenMapTiles](https://openmaptiles.org/)

---

**Status:** 📋 Plano Documentado  
**Próximo:** Iniciar Implementação (Etapa 1)
