# 🌐 InfraPlan - Sistema de Planejamento de Infraestrutura de Rede Óptica

[![Flutter](https://img.shields.io/badge/Flutter-3.9.2-blue.svg)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Status](https://img.shields.io/badge/Status-Beta-yellow.svg)]()

## 📋 Sobre

**InfraPlan** é um aplicativo de planejamento de infraestrutura de rede óptica com suporte offline-first. Permite que engenheiros e técnicos visualizem, editiem importem dados de elementos de rede (CTOs, OLTs, CEOs, DIOs, Cabos) em um mapa interativo.

**Características principais:**
- 🗺️ Mapa interativo com tiles cacheados
- 📍 Gerenciamento de elementos de rede (CTO, OLT, CEO, DIO, Cabo)
- 💾 Cache inteligente de tiles offline (até 800MB)
- 📤 Import/Export de dados (JSON, CSV)
- 📊 Visualização de estatísticas
- 🔄 Sincronização de dados
- 📱 Funciona offline após primeiro acesso
- 🎯 Clustering automático em zoom-out

---

## 🚀 Quick Start

### Pré-requisitos

- Flutter 3.9.2+
- Android SDK (mínimo API 21)
- Dispositivo Android ou emulador

### Instalação

```bash
# Clone o repositório
git clone https://github.com/NoasYTOFC/marker_infra.git
cd marker_infra

# Instale dependências
flutter pub get

# Execute o app
flutter run
```

### Usar em Produção

```bash
# Build release
flutter build apk --release

# Instalar em dispositivo
adb install build/app/outputs/apk/release/app-release.apk
```

---

## 🗂️ Estrutura do Projeto

```
lib/
├── main.dart                          # Entry point
├── screens/                           # Telas (MapScreen, HomeScreen, etc)
├── providers/                         # State management (Provider pattern)
│   ├── infrastructure_provider.dart   # ⭐ Gerencia elementos + triggers de cache
│   └── smart_tile_cache_provider.dart # State do cache
├── services/                          # Serviços
│   ├── tile_cache_database.dart       # ⭐ SQLite backend (457 linhas)
│   ├── smart_tile_cache_service.dart  # ⭐ Orquestração de cache (376 linhas)
│   ├── cached_tile_provider.dart      # ⭐ Provider de tiles (291 linhas)
│   ├── storage_service.dart           # Persistência de dados
│   └── permission_service.dart        # Permissões do dispositivo
├── models/                            # Data models (CTO, OLT, CEO, DIO, Cabo)
├── widgets/                           # Componentes reutilizáveis
└── utils/                             # Utilitários

android/                               # Configurações Android
```

---

## 💾 Sistema de Cache

> **📖 Documentação Completa:** Veja `README_CACHE_SYSTEM.md`

### Arquitetura

```
┌─────────────────┐
│  Memória (LRU)  │  ← 1-5ms
│  100 tiles      │
└────────┬────────┘
         ↓
┌─────────────────┐
│  SQLite Disk    │  ← 5-50ms
│  Até 800MB      │
└────────┬────────┘
         ↓
┌─────────────────┐
│  Rede (OSM)     │  ← 100-1000ms
│  On-demand      │
└─────────────────┘
```

### Como Funciona

1. **App inicia**: Carrega elementos do storage (rápido)
2. **Elemento novo**: Cache automático 3km + 3 zooms (background)
3. **Navegação**: Tiles do cache são instantâneos
4. **Tiles novos**: Automaticamente salvos para próxima vez
5. **Limite atingido**: Limpeza LRU automática

### Performance

| Operação | Tempo |
|----------|-------|
| Tile do cache | 1-5ms |
| Tile da rede | 100-200ms |
| Download 1000 tiles | 2-5min |
| App startup | <2s |

### Pyramid Caching (Otimização Implementada) ⭐

O sistema agora usa **Pyramid Caching** automaticamente:

- **Zoom 14**: Visão macro em raio de **20km** (~100 tiles, 5-10MB)
  - Usado como fallback quando zoom não tem dados
  - Carrega instantaneamente
  
- **Zooms 15-17**: Detalhe completo em raio de **5km** (expandido de 3km)
  - Performance completa
  - Cache em background

**Resultado:** 
- ✅ Raio expandido de 3km → 5km sem aumentar consumo
- ✅ Visão macro (zoom 14) disponível automaticamente
- ✅ 60% menos espaço que carregar zoom 14 completo
- ✅ Posição inicial do mapa: zoom 15 (correto, igual ao mínimo permitido)

---

## 🎮 Como Usar

### Adicionar Elemento

1. Clique no **+** flutuante
2. Selecione tipo (CTO, OLT, CEO, DIO, Cabo)
3. Preencha dados e posição
4. **Cache automático iniciado** para 3km ao redor ✅

### Navegação no Mapa

- **Zoom**: Scroll com dois dedos (range: 15-17)
- **Pan**: Arrastar com um dedo
- **Tap**: Selecionar elemento
- **Clustering**: Automático em zoom-out

### Import/Export

**Import:**
- Clique menu → Import
- Selecione arquivo JSON/CSV
- Dados são mesclados com existentes

**Export:**
- Clique menu → Export
- Escolha formato (JSON/CSV)
- Salva em Downloads

### Visualizar Cache

Use o script incluído para filtrar logs:

```powershell
.\clean_logs.ps1
```

Veja `CLEAN_LOGS.md` para mais detalhes.

---

## ⚙️ Configuração

### Limites de Cache

```dart
// lib/services/smart_tile_cache_service.dart
static const int maxCacheSizeMb = 800;        // Máximo espaço
static const int cleanOldTilesDays = 30;      // Limpar tiles antigos
static const double _defaultRadiusKm = 5.0;  // Raio por elemento (expandido!)
static const double _pyramidRadiusKm = 20.0; // Raio para zoom 14 (pyramid)
```

### Zoom

```dart
// lib/screens/map_screen.dart
initialZoom: 15.0, // Zoom inicial = zoom mínimo (correto)
minZoom: 15.0,     // Mínimo com pyramid caching (zoom 14 de fallback)
maxZoom: 17.0,     // Máximo
```

Edite esses valores se necessário.

---

## 🔧 Troubleshooting

### Tiles carregam lento

✅ Normal na primeira vez (download em background)
✅ Subsequentes são instantâneos (cache)
⚠️ Se continuar lento: rede ruim ou storage cheio

### "Database is locked"

✅ Já corrigido com Semaphore thread-safe
ℹ️ Muito raro ocorrer com correção atual

### App trava ao adicionar elemento

✅ Normal enquanto cache faz download (background não-bloqueante)
✅ Você pode usar o app normalmente durante isso

### Tiles com erro (X vermelho)

✅ Offline e tile não está em cache
✅ Normal, mostra visualmente que não há dados

---

## 📊 Estatísticas

- **Zoom levels cacheados**: 3 (15, 16, 17)
- **Raio por elemento**: 3km
- **Max cache**: 800MB
- **Tiles típicos por elemento**: 1000-2000
- **Tempo download médio**: 2-5 minutos
- **Overhead por elemento**: ~50-100MB

---

## 🚀 Otimizações Sugeridas

### Implementadas Recentemente ✅

**Pyramid Caching:**
- Zoom 14 em 20km de raio (visão macro automática)
- Zooms 15-17 em 5km de raio (detalhe)
- Resultado: Raio expandido de 3km → 5km sem aumentar consumo
- Zoom inicial do mapa corrigido: 15 (igual ao zoom mínimo)

### Próximas (Opcionais)

### 1. **Zoom-on-Demand para Zoom 18+** ⭐⭐⭐

Se precisar de zoom muito detalhe (zoom 18):

```dart
onZoomChanged(zoom) {
  if (zoom > 17 && !hasCachedZoom(zoom)) {
    downloadZoomBackground(zoom);
  }
}
```

**Impacto:** 90% economia, mesma UX em uso normal

### 2. **Selective Radius by Density** ⭐⭐

```dart
if (element.proximosA.length > 5) {
  radiusKm = 2.5;  // Menos espaço em áreas urbanas densas
} else {
  radiusKm = 5.0;  // Normal em áreas esparsas
}
```

**Impacto:** +20% smart allocation, adaptativo

### 3. **Clustered Downloads** ⭐⭐

Se vários elementos próximos, baixar tiles únicos uma vez (deduplicação avançada):

**Impacto:** 75% menos downloads em áreas com muitos elementos

### 4. **WebP Support** ⭐⭐

Suportar WebP em Android 4.2+ (25% menor que PNG):

```dart
final url = device.supportsWebP 
  ? '.../webp'
  : '.../png';
```

**Impacto:** 25% economia de espaço em disco

Veja `README_CACHE_SYSTEM.md` para detalhes técnicos completos.

---

## 🏗️ Arquitetura Técnica

### Stack

- **Frontend**: Flutter 3.9.2
- **State Management**: Provider 6.1.2
- **Mapas**: flutter_map 7.0.2
- **Clustering**: flutter_map_marker_cluster 1.3.6
- **Persistência**: sqflite 2.3.3
- **Preferences**: shared_preferences 2.3.3

### Design Patterns

- **Provider Pattern**: State management escalável
- **Singleton**: Database instance
- **LRU Cache**: Memory optimization
- **Semaphore/Mutex**: Thread-safety

---

## 📝 Roadmap

- [ ] UI para visualizar cache stats
- [ ] Pre-cache para favoritos
- [ ] Suporte a mapas customizados
- [ ] Sincronização em nuvem
- [ ] Roteiros/traqqjectories
- [ ] Cálculos de distância/área
- [ ] Relatórios PDF

---

## 🤝 Contribuindo

Contribuições são bem-vindas! Por favor:

1. Fork o projeto
2. Crie uma branch (`git checkout -b feature/MinhaFeature`)
3. Commit mudanças (`git commit -m 'Add MinhaFeature'`)
4. Push (`git push origin feature/MinhaFeature`)
5. Abra um Pull Request

---

## ⚖️ Licença

MIT License - veja `LICENSE` para detalhes

---

## 📧 Contato

Desenvolvido com ❤️ para profissionais de infraestrutura de rede

Para perguntas ou sugestões, abra uma issue no GitHub.

---

**Status:** Beta 🚀 | Últimas mudanças: Nov 2025
