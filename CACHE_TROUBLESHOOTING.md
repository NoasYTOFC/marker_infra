# Troubleshooting - Tiles Não Carregando do Cache

## 🔍 Diagnóstico: Por que tiles não estão sendo carregados?

### Cenário 1: Debug vs Release
**Problema:** Tiles funcionam em DEBUG mas não em RELEASE (ou vice-versa)

**Causas possíveis:**
1. **Diretórios diferentes por modo**
   - DEBUG e RELEASE podem ter different `ApplicationSupportDirectory` paths
   - SQLite database pode estar em local diferente

2. **Cache limpo entre builds**
   - Alguns emuladores/dispositivos limpam cache ao fazer rebuild
   - Android: cache pode estar em `data/data/com.app/cache/`
   - iOS: cache em `~/Library/Caches/`

**Solução:**
```dart
// Sempre usar o mesmo diretório
final appDir = await getApplicationSupportDirectory();
final cacheDir = '${appDir.path}/tile_cache';
```

### Cenário 2: Banco de Dados (SQLite) Desatualizado
**Problema:** Arquivo existe no disco mas não está no banco de dados

**O que acontece:**
```
1. Arquivo salvo em: ~/.config/marker_infra/tile_cache/18/103097/139976.png
2. Mas TileCacheDatabase NÃO tem registro desse tile
3. CachedTileProvider procura no BD
4. Não encontra → tenta network novamente
5. Network falha → não mostra tile
```

**Como verificar:**
No console, procure por mensagens:
```
⚠️ Arquivo do cache não existe: /path/to/file.png (banco desatualizado?)
✅ Tile encontrado no cache: /path/to/file.png
```

**Solução:**
```dart
// Verificar se arquivo existe E está no BD antes de carregar
final cachedPath = await CachedTileProvider.getCachedTilePath(z, x, y);
if (cachedPath != null) {
  final file = File(cachedPath);
  final fileExists = await file.exists();
  
  if (fileExists) {
    // OK! Carregar
  } else {
    // Arquivo deletado mas BD não sabe
    // Tentar network novamente
  }
}
```

### Cenário 3: Set `_failedTiles` Está Travando Tiles
**Problema:** Tiles ficam marcados como "falhados" e nunca recarregam

**O que acontece:**
```
1. Tile falha de carregar (erro de rede)
2. Marcado em _failedTiles
3. Da próxima vez, pula cache e tenta network
4. Se ainda falhar, continua marcado para sempre
5. Mesmo quando internet voltar, não carrega
```

**Solução Implementada:**
```dart
// Diferenciar erros:
if (e is SocketException || e is TimeoutException) {
  // Erro de rede - NÃO marcar como falhado
  // Deixar retry automático quando tiver conexão
  rethrow;
} else {
  // Erro real (HTTP 404, etc) - marcar como falhado
  _markTileAsFailed(z, x, y);
  rethrow;
}
```

### Cenário 4: Flutter Map Cache Internal
**Problema:** Flutter Map guarda tiles em cache de imagens interno

**O que acontece:**
```
1. Tile carregado e exibido
2. Flutter Map armazena em seu imageCache interno
3. Mesmo que arquivo seja deletado, Flutter Map ainda mostra
4. Quando reconecta, Flutter Map pensa que já tem a imagem
5. Não recarrega do network
```

**Solução:**
```dart
// Ao reconectar, limpar o cache de imagens
for (String tileKey in _failedTiles) {
  imageCache.evict(NetworkImage(cacheKey));
}
_failedTiles.clear();
```

### Cenário 5: Permissões de Arquivo
**Problema:** Arquivo salvo mas não pode ler depois (Android/iOS)

**Causas possíveis:**
- Android: `WRITE_EXTERNAL_STORAGE` não concedido
- iOS: App sandbox restrictions
- Windows: Permissão de arquivo negada

**Solução:**
```dart
// Verificar permissões antes de salvar
import 'package:permission_handler/permission_handler.dart';

final status = await Permission.storage.request();
if (status.isDenied) {
  debugPrint('❌ Sem permissão para salvar cache');
  return;
}
```

## 📊 Fluxo de Debugging

### Passo 1: Verificar Diretório de Cache
```bash
# Achar onde os tiles estão sendo salvos
# Listar diretório de cache
ls ~/.config/marker_infra/tile_cache/
# ou no Android:
adb shell ls /data/data/com.app/app_flutter/tile_cache/
```

### Passo 2: Checar Logs
No console Flutter, procure por:

```
✅ Tile encontrado no cache: [caminho]  # Sucesso!
⚠️ Arquivo do cache não existe: [caminho]  # Banco está errado
⚠️ Tile não está no cache de dados  # Não foi registrado no BD
❌ Erro ao carregar tile  # Problema real
📡 Erro de rede  # Erro temporário
```

### Passo 3: Verificar Banco de Dados SQLite

```dart
// Adicionar este código temporariamente para debugar
static Future<void> debugPrintAllCachedTiles() async {
  final stats = await TileCacheDatabase.getCacheStats();
  debugPrint('📊 Cache Stats: $stats');
  
  // Listar todos os tiles no banco
  final allTiles = await TileCacheDatabase.getAllTiles();
  debugPrint('📝 Total tiles no BD: ${allTiles.length}');
  for (var tile in allTiles.take(10)) {
    debugPrint('  - z=${tile['z']} x=${tile['x']} y=${tile['y']} file=${tile['file_path']}');
  }
}

// Chamar no main() para debug:
await CachedTileProvider.debugPrintAllCachedTiles();
```

### Passo 4: Limpar Cache e Testar Novamente

```dart
// Force limpar tudo
await CachedTileProvider.clearCache();

// Verificar se memória está limpa
debugPrint('Cache limpo!');
```

## 🔧 Checklist de Verificação

- [ ] Arquivo salvo no disco: `~/.config/marker_infra/tile_cache/z/x/y.png`
- [ ] Tile registrado no SQLite (via `addCachedTile`)
- [ ] Não marcado em `_failedTiles` sem motivo
- [ ] Permissões de leitura/escrita OK
- [ ] Banco de dados não corrompido
- [ ] Flutter Map cache não estorou
- [ ] Conectividade service rodando (para clear falhados)
- [ ] Debug vs Release usa mesmo diretório

## 🚨 Comum em Modo Release

**Release often cleans cache between installations!**

Se o app em RELEASE não carrega cache:
1. Certifique que não está limpando `ApplicationSupportDirectory`
2. Verifique se há code de cleanup em `main()` ou `initState()`
3. Teste sem fazer clean build completo

```bash
# Build Release normalmente
flutter build apk --release

# NÃO faça:
flutter clean  # ← APAGA CACHE!
flutter pub get
flutter build apk --release
```

## ✅ Verificação Rápida

1. **Abra o console Flutter**
2. **Mude para uma área nova sem cache**
3. **Veja os logs:**
   - `🌐 Tile da rede` = baixando
   - `💾 Arquivo salvo` = salvando em disco
   - `📝 Registrado no DB` = registrando no banco
   - `✅ Tile encontrado no cache` = carregando do cache

4. **Feche app sem internet**
5. **Abra app offline**
6. **Se mostrar tiles = ✅ Funcionando!**

---

**Última atualização:** 2025-11-03  
**Status:** Em produção com logging detalhado
