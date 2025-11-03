# 🗺️ Offline Map Caching - System Architecture

## 📐 Arquitetura Geral

```
┌─────────────────────────────────────────────────────────────┐
│                      MapScreen Widget                        │
│  - Exibe FlutterMap                                          │
│  - Listener para reconexão (faz zoom bounce)                │
└──────────────┬──────────────────────────────────────────────┘
               │
               ├─ TileLayer(tileProvider: CachedTileProvider())
               │
               └─ MarkerClusterLayerWidget (CTOs, OLTs, etc)

┌──────────────────────────────────────────────────────────┐
│              CachedTileProvider                           │
│  - Custom ImageProvider para tiles do mapa                │
│  - Implementa: loadImage(), obtainKey()                   │
└────────────┬─────────────────────────────────────────────┘
             │
    ┌────────┴────────┐
    │                 │
    ▼                 ▼
 ╔═════════════╗  ╔════════════╗
 ║   LOCAL     ║  ║  NETWORK   ║
 ║   CACHE     ║  ║   LOAD     ║
 ║ (SQLite +   ║  ║ (OSM API + ║
 ║  Filesystem)║  ║  Retry)    ║
 ╚═════════════╝  ╚════════════╝
    - getcachedTilePath()      - http.get(tile.url)
    - 3 tentativas fallback    - Exponential backoff
    - LRU cleanup            - 10s timeout
    - File-based persistence   - networkImage cache

┌──────────────────────────────────────────────────────────┐
│         ConnectivityService                              │
│  - Monitora conexão a cada 5 segundos                    │
│  - HTTP ping to google.com                              │
│  - Detecta transição: Offline ➜ Online                  │
│  - Chama: CachedTileProvider.clearFailedTiles()         │
└──────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│        TileCacheDatabase                                 │
│  - SQLite registry de tiles cacheados                    │
│  - getDatabase() ➜ sqflite                              │
│  - Rastreia: z, x, y, file_path, file_size             │
│  - LRU cleanup automático (max 500MB)                   │
└──────────────────────────────────────────────────────────┘
```

## 🔄 Fluxo de Carregamento de Tile

### 1️⃣ Tentativa Inicial
```
User scroll/zoom on map
    │
    └─> FlutterMap requests tile (z, x, y)
            │
            └─> CachedTileProvider.loadImage()
                    │
                    ├─> Check: Is tile marked as failed?
                    │   ├─ YES ➜ Skip cache, try network
                    │   └─ NO ➜ Check cache first
                    │
                    ├─> getCachedTilePath(z, x, y)
                    │   └─> SQLite query + File check
                    │       ├─ EXISTS ➜ Load from file ✅
                    │       └─ NOT EXISTS ➜ Try network
                    │
                    └─> If not cached: _loadImageAsync()
                            │
                            ├─> Attempt 1: http.get(tile.url)
                            ├─ Attempt 2: http.get(tile.url) [backoff 500ms]
                            ├─ Attempt 3: http.get(tile.url) [backoff 1000ms]
                            │
                            ├─ SUCCESS (status 200) ➜ decode + return ✅
                            └─ FAIL all attempts ➜ Mark as failed + rethrow ❌
```

### 2️⃣ Marcar como Falhado
```
_loadImageAsync() throws Exception
    │
    ├─> catch block
    ├─ _markTileAsFailed(z, x, y)
    │  └─> Add '$z-$x-$y' to Set<_failedTiles>
    │
    └─> rethrow ❌ (NÃO retorna imagem de erro!)
            │
            └─> Flutter Map saiba que falhou
                    │
                    ├─ Não cacheia como sucesso
                    ├─ Mostra área cinza/placeholder
                    └─ Permitirá retry no futuro
```

### 3️⃣ Monitoramento de Conectividade
```
ConnectivityService.startMonitoring()
    │
    └─> Timer.periodic(5 seconds)
            │
            ├─> Check: await _checkConnectivity()
            │   └─> http.get('https://www.google.com/') [3s timeout]
            │
            ├─ Was offline, now online? ➜ Transition detected! 🔔
            │   │
            │   ├─ debugPrint("✅ Conexão restaurada!")
            │   │
            │   └─> CachedTileProvider.clearFailedTiles()
            │       ├─ Notify listeners
            │       ├─ _failedTiles.clear()
            │       └─> MapScreen._onConnectivityChanged(true)
            │
            └─ Store state: _isConnected = true/false
```

### 4️⃣ Reconexão e Refresh
```
MapScreen._onConnectivityChanged(true)
    │
    └─> Zoom bounce animation
            │
            ├─> currentZoom + 0.01 (zoom in)
            ├─> wait 100ms
            ├─> currentZoom (zoom out to original)
            │
            └─> Triggers TileLayer rebuild! 🔄
                    │
                    └─> Next tile load skips _failedTiles
                            │
                            └─> Tries network again ✅
```

## 💾 Estrutura de Pastas

```
$ApplicationSupportDirectory/
├── tile_cache/                (Cache de tiles)
│   ├── 15/                    (Zoom level)
│   │   ├── 9889/              (X coordinate)
│   │   │   ├── 6267.png       (Y coordinate = tile)
│   │   │   ├── 6268.png
│   │   │   └── ...
│   │   └── 9890/
│   │       └── ...
│   ├── 16/
│   │   └── ...
│   └── manifest.json          (TileCacheDatabase)
│
└── databases/
    └── tile_cache.db          (SQLite registry)
            │
            ├─ tiles table
            │  ├─ z, x, y (coordinates)
            │  ├─ file_path
            │  ├─ file_size
            │  ├─ created_at (LRU)
            │  └─ accessed_at (LRU)
            │
            └─ Triggers cleanup when > 500MB
```

## 📊 Estado Machine

```
                    ┌────────────────┐
                    │   ONLINE       │
                    │  (Connected)   │
                    └────────────────┘
                          ▲
                    NO ERROR│
                           │
        ┌──────────────────┴──────────────────┐
        │                                     │
        │   TILE LOAD SUCCESS                 │
        │   ✅ Cache it                       │
        │   ✅ Register in SQLite             │
        │   ✅ Flutter Map caches             │
        │                                     │
        └──────────────────┬──────────────────┘
                           │
                   ERROR OR NO NET
                           │
                    ┌──────▼──────┐
                    │ OFFLINE/    │
                    │ LOAD ERROR  │
                    │ (Connected) │
                    └──────┬──────┘
                           │
            ┌──────────────┴──────────────┐
            │                             │
            │ TILE LOAD FAILED            │
            │ ❌ Mark as failed           │
            │ ❌ Don't cache              │
            │ ❌ Rethrow exception        │
            │                             │
            └──────────────┬──────────────┘
                           │
                    NO CONNECTION
                           │
                    ┌──────▼────────────┐
                    │  OFFLINE STATE    │
                    │ (Connectivity = 0)│
                    └──────┬────────────┘
                           │
                    Waiting for reconnection
                    (or retry with cache)
                           │
                    ┌──────▼────────────────┐
                    │ RECONNECTED!         │
                    │ ✅ clearFailedTiles()│
                    │ ✅ Zoom bounce       │
                    │ ✅ Force rebuild     │
                    └──────┬───────────────┘
                           │
                    RETRY TILES FROM NETWORK
                           │
            ┌──────────────┴──────────────┐
            │                             │
         SUCCESS                        FAIL
            │                             │
            ▼                             ▼
        (back to cached/online)   (back to offline/error)
```

## 🧪 Test Scenarios

### Cenário 1: Offline Simples
```
1. Abrir app com internet
2. Fazer scroll/zoom (tiles carregam do network, cacheados)
3. Desligar internet
4. Fazer scroll/zoom
   ├─ Tiles do cache: ✅ Carregam
   ├─ Tiles new (fora do cache): ❌ Cinza/placeholder
   └─ Tiles com erro anterior: ❌ Cinza/placeholder
5. Ligar internet
6. Fazer scroll/zoom
   └─ Todos tiles recarregam ✅
```

### Cenário 2: Erro Transitório
```
1. Internet instável/lenta
2. Alguns tiles falham em carregar
   └─ Marcados em _failedTiles
3. Internet volta à normalidade
   └─ Detectado por ConnectivityService (5s)
4. clearFailedTiles() chamado
5. Próximo scroll/zoom
   └─ Tiles retry e carregam ✅
```

### Cenário 3: Modo Offline Intencional
```
1. Abrir app, zoom to desired area
2. Desligar internet deliberadamente
3. Navegar somente com tiles em cache
   └─ Todas as áreas que já foram vistas: ✅
   └─ Novas áreas: ❌ Cinza
4. Cache persiste entre app restarts
   └─ Próximo launch offline continua funcionando
```

## 🔐 Segurança & Performance

| Aspecto | Implementação |
|---------|--------------|
| **Cache Size** | Max 500MB com LRU cleanup |
| **Timeout** | 10s por tile, 3s para connectivity check |
| **Retry** | 3 tentativas com backoff exponencial |
| **Thread** | Async/await, não bloqueia UI |
| **Memory** | In-memory cache (últimos ~100 tiles) + SQLite |
| **Persistence** | Survives app restart |
| **Conflict** | Erro tiles não são cacheados ✅ |

## 📱 Compatibilidade

```
Platform         | Supported | Notes
─────────────────┼───────────┼──────────────────
Windows          | ✅ YES    | HTTP ping works
Android          | ✅ YES    | Full support
iOS              | ✅ YES    | Full support
macOS            | ✅ YES    | Full support
Linux            | ✅ YES    | Full support
Web              | ✅ YES    | (Limited cache)
```

---

**Last Updated**: Nov 3, 2025
**Status**: ✅ Production Ready
**Commit**: 0f97f31
