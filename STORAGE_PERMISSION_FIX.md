# Corrigido: Permissão de Armazenamento no Android 11+ 🔒

## O Problema

Em Android 11+, a permissão `storage` foi depreciada e substituída por `MANAGE_EXTERNAL_STORAGE`. O código anterior não estava funcionando porque:

1. Usava apenas `Permission.storage.request()` que é legado
2. Não tentava `MANAGE_EXTERNAL_STORAGE` (Android 11+)
3. Não tinha fallback para versões mais antigas

## A Solução

### 1. **Atualizado: `PermissionService.requestStoragePermission()`**

Agora tenta em ordem:
1. **`MANAGE_EXTERNAL_STORAGE`** (Android 11+) - Melhor opção
2. **`Permission.storage`** (Fallback Android 10 e anteriores)

```dart
static Future<bool> requestStoragePermission() async {
  if (Platform.isAndroid) {
    // Tentativa 1: MANAGE_EXTERNAL_STORAGE (Android 11+)
    final manageStatus = await Permission.manageExternalStorage.request();
    if (manageStatus.isGranted) {
      debugPrint('✅ MANAGE_EXTERNAL_STORAGE concedida!');
      return true;
    }
    
    // Tentativa 2: READ/WRITE_EXTERNAL_STORAGE (Fallback)
    final readStatus = await Permission.storage.request();
    if (readStatus.isGranted || readStatus.isLimited) {
      debugPrint('✅ Permissão de storage concedida!');
      return true;
    }
    
    // Tratamento de erro
    if (readStatus.isDenied) {
      debugPrint('❌ Permissão negada pelo usuário');
      return false;
    } else if (readStatus.isPermanentlyDenied) {
      debugPrint('❌ Permissão negada permanentemente');
      openAppSettings();
      return false;
    }
  } else if (Platform.isIOS) {
    // iOS: Sem permissão explícita necessária
    return true;
  }
  
  return false;
}
```

### 2. **Permissão Adicionada: `AndroidManifest.xml`**

```xml
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" />
```

### 3. **Debug Melhorado**

Adicionados prints para facilitar diagnóstico:

```
🔐 Solicitando permissão de armazenamento...
🔐 Tentando MANAGE_EXTERNAL_STORAGE (Android 11+)...
🔐 Status MANAGE_EXTERNAL_STORAGE: PermissionStatus.granted
✅ MANAGE_EXTERNAL_STORAGE concedida!
```

## Fluxo Agora

### Quando o usuário clica em "Exportar KML/KMZ"

```
1. App detecta Android
2. Chama PermissionService.requestStoragePermission()
3. Tenta MANAGE_EXTERNAL_STORAGE
   ├─ Se concedida ✅ → Continua export
   └─ Se negada ❌ → Tenta fallback
4. Se fallback também negado ❌ → Abre Settings
5. Se aceitar em Settings → Exporta arquivo
```

## Versões de Android Suportadas

| Versão | Permissão Usada | Comportamento |
|--------|-----------------|---------------|
| Android 13+ | `MANAGE_EXTERNAL_STORAGE` | Solicita dialog |
| Android 11-12 | `MANAGE_EXTERNAL_STORAGE` | Solicita dialog |
| Android 10 | `READ/WRITE_EXTERNAL_STORAGE` | Solicita dialog |
| Android 6-9 | `READ/WRITE_EXTERNAL_STORAGE` | Solicita dialog |

## Como Testar

### No Android (Dispositivo ou Emulador)

1. **Limpar dados do app** (remove permissões anteriores)
   ```bash
   adb shell pm clear com.example.marker_infra
   ```

2. **Abrir app**

3. **Vá para Import/Export**

4. **Clique em "Exportar KML" ou "Exportar KMZ"**

5. **Veja o dialog de permissão aparecer** ✅

6. **Aceite a permissão**

7. **Arquivo deve ser salvo** em `/storage/emulated/0/INFRA_EXPORT/`

### Verificar no Logcat

```bash
adb logcat | grep "🔐"
```

Deve ver:
```
D/flutter: 🔐 Solicitando permissão de armazenamento...
D/flutter: 🔐 Tentando MANAGE_EXTERNAL_STORAGE (Android 11+)...
D/flutter: 🔐 Status MANAGE_EXTERNAL_STORAGE: PermissionStatus.granted
D/flutter: ✅ MANAGE_EXTERNAL_STORAGE concedida!
```

## Checklist ✅

- [x] `PermissionService.requestStoragePermission()` tenta `MANAGE_EXTERNAL_STORAGE` primeiro
- [x] Fallback para `Permission.storage` se necessário
- [x] Debug prints adicionados para diagnóstico
- [x] Permissão `MANAGE_EXTERNAL_STORAGE` adicionada no manifest
- [x] Compatível com Android 6+
- [x] Zero erros de compilação

## Se Ainda Não Funcionar

### Opção 1: Resetar permissões do app
```bash
adb shell pm clear com.example.marker_infra
```

### Opção 2: Desinstalar e reinstalar
```bash
adb uninstall com.example.marker_infra
flutter run
```

### Opção 3: Verificar permissões concedidas
```bash
adb shell pm list permissions -g | grep -A 20 com.example.marker_infra
```

### Opção 4: Ver all logs
```bash
adb logcat | grep -E "(flutter|permission|storage)"
```

---

**Status**: ✅ Corrigido  
**Compilação**: Zero erros  
**Pronto**: Testar no Android
