# Sistema de Cache Offline de Tiles - Fluxo Completo

## 🎯 Objetivo
Carregar tiles do mapa offline quando não há internet, e automaticamente recarregar quando a conexão voltar.

## 📊 Fluxo de Dados

### 1️⃣ **Quando há Internet - Carregamento Normal**
```
┌─────────────────────────────────────────┐
│ Usuário move/zoom no mapa               │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ flutter_map pede tile (z/x/y)           │
│ ex: 18/103097/139976.png                │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ CachedTileProvider._loadImageAsync()    │
│ 1. Verificar se está em _failedTiles?   │
│    ✗ Não → continuar                    │
│    ✓ Sim → pular cache, tentar rede     │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ 2. Buscar em cache local                │
│    ~/.config/marker_infra/tile_cache/   │
│    18/103097/139976.png                 │
└──────────────┬──────────────────────────┘
               │
        ┌──────┴──────┐
        │             │
    Encontrou?    NÃO
        │             │
       SIM            ▼
        │      ┌──────────────────────┐
        │      │ 3. Tentar baixar da  │
        │      │ rede (com retry)     │
        │      │ Tentativa 1/3        │
        │      └─────────┬────────────┘
        │                │
        ▼                │
   ┌────────────┐   ┌────┴────┐
   │ Sucesso! 🎉│   │  Erro?  │
   │ Retornar   │   └────┬────┘
   │ imagem     │        │
   │            │   ┌────┴─────────────────┐
   │ + Salvar   │   │ SocketException?     │
   │ em cache   │   │ TimeoutException?    │
   │ + Registrar│   │                      │
   │ em BD      │   │ Erros de rede!       │
   └────────────┘   │ → NÃO marcar falhado│
                    │ → Retornar exceção  │
                    │ → Tentar denovo +1  │
                    │                      │
                    └────┬────────────────┘
                         │
                    ┌────┴──────────────┐
                    │ Após 3 tentativas?│
                    └────┬──────────────┘
                         │
                    ┌────┴──────────────────┐
                    │ Erro real ou timeout? │
                    │ → Marcar como falhado │
                    │ → Relançar exceção    │
                    └───────────┬───────────┘
                                │
                                ▼
                         ┌──────────────┐
                         │ Flutter Map  │
                         │ mostra X     │
                         └──────────────┘
```

### 2️⃣ **Quando SEM Internet - Modo Offline**
```
┌─────────────────────────────────────────┐
│ ❌ Host lookup failed: tile.osm.org     │
│ (SocketException)                        │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ CachedTileProvider catch(SocketException)│
│ → NÃO marcar como falhado               │
│ → Relançar exceção                      │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ Flutter Map tenta carregar da memória   │
│ ou cache                                 │
└──────────────┬──────────────────────────┘
               │
        ┌──────┴──────┐
        │             │
    Tem em cache?  NÃO
        │             │
       SIM            ▼
        │      ┌──────────────┐
        │      │ Mostra X     │
        │      │ (vazio)      │
        │      └──────────────┘
        │
        ▼
   ┌───────────┐
   │ Sucesso! 🎉
   │ Mostrar   │
   │ tile cacheado
   │ (modo offline)
   └───────────┘
```

### 3️⃣ **Quando Conexão Volta - Retry Automático**
```
┌────────────────────────────────────────┐
│ ConnectivityService.startMonitoring()  │
│ Ping Google.com a cada 5 segundos      │
└──────────────┬─────────────────────────┘
               │
               ▼
┌────────────────────────────────────────┐
│ 📡 Verificação de conectividade: Online│
└──────────────┬─────────────────────────┘
               │
        ┌──────┴──────────┐
        │                 │
    Estava offline?    NÃO
        │                 │
       SIM                ▼
        │              Continuar
        │
        ▼
   ┌──────────────────────────┐
   │ ✅ Conexão restaurada!   │
   │                          │
   │ 1. Limpar _failedTiles   │
   │ 2. Limpar Flutter Cache  │
   │ 3. Notificar listeners   │
   └─────────────┬────────────┘
                 │
                 ▼
   ┌──────────────────────────┐
   │ MapScreen recebe evento  │
   │                          │
   │ Fazer "bounce" de zoom:  │
   │ - Zoom +0.01             │
   │ - Zoom -0.01             │
   │ (força rebuild da mapa)  │
   └─────────────┬────────────┘
                 │
                 ▼
   ┌──────────────────────────┐
   │ flutter_map redesenha    │
   │ Pede os tiles denovo     │
   └─────────────┬────────────┘
                 │
                 ▼
   ┌──────────────────────────┐
   │ CachedTileProvider       │
   │ _failedTiles está vazio! │
   │ → Tenta rede novamente   │
   │ → Se tiver Internet agora│
   │ → Carrega do servidor    │
   │ → Salva em cache         │
   └──────────────┬───────────┘
                 │
                 ▼
   ┌──────────────────────────┐
   │ 🎉 Tiles carregam!       │
   │ Modo Online restaurado   │
   └──────────────────────────┘
```

## 🔑 Conceitos Importantes

### **_failedTiles Set**
- Armazena tiles que tiveram erro REAL (não de rede)
- Ex: HTTP 404, arquivo corrompido, etc
- Quando marcado: pula cache, tenta rede
- Quando limpo: pode tentar do cache novamente

### **Erros de Rede vs Erros Reais**

| Tipo | Exemplo | Ação |
|------|---------|------|
| **Rede** | SocketException, TimeoutException | ❌ NÃO marcar como falhado, deixar retry automático |
| **Real** | HTTP 404, arquivo corrompido | ✅ Marcar como falhado, retry quando conectar |

### **Fluxo de Cache**
1. **Cache em Disco**: `~/.config/marker_infra/tile_cache/z/x/y.png`
2. **Registro em BD**: Cada tile é registrado em SQLite
3. **Cache de Memória**: Flutter mantém imagens em RAM
4. **Falhas em Memória**: `_failedTiles` Set rastreia erros

## 🚀 Fluxo Final (Resumido)

```
SEM INTERNET          COM INTERNET          RECONECTA
    │                     │                     │
    ├─ Tile A (cache) → Mostra              ✅ Reload tile A
    ├─ Tile B (falha) → Mostra X          ✅ Reload tile B
    └─ Tile C (falha) → Mostra X          ✅ Reload tile C
    
Resultado:
- Usuário vê tiles que tem em cache
- Tiles falhados mostram X (vazios)
- Quando internet volta, tiles recarregam automaticamente
```

## 📝 Exemplo Real

### Cenário 1: Offline → Muitos tiles mostram X
```
❌ "Failed host lookup: tile.openstreetmap.org"
→ Erros de rede, NÃO são marcados como falhados
→ Tiles que existem em cache mostram
→ Tiles novos mostram X
```

### Cenário 2: Reconecta à internet
```
✅ "Conexão restaurada!"
→ Faz bounce de zoom
→ flutter_map redesenha
→ Tenta carregar tiles novamente
→ Desta vez, consegue carregar do servidor
→ Salva em cache para próxima vez offline
```

### Cenário 3: Próxima vez offline
```
✅ Tiles já estão em cache!
→ Carrega direto do disco
→ Sem erro de rede
→ Modo offline funciona perfeitamente
```

## 🎯 Checklist de Funcionamento

- ✅ Tiles carregam quando online
- ✅ Tiles salvam em cache automaticamente
- ✅ Cache em disco persiste entre app closes
- ✅ Modo offline mostra tiles em cache
- ✅ Erros de rede não marcam tile como "falhado"
- ✅ Quando reconecta, tenta carregar denovo
- ✅ Map faz refresh automático ao reconectar
- ✅ Funciona em Windows, Android, iOS, etc
