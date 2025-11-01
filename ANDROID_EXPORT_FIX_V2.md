# Fix Android Export - Versão 2 🔧

## Problema Identificado

O erro "Bytes are required" no Android/iOS era causado pelo `FilePicker.platform.saveFile()` retornando um path que **não é gravável** nesses sistemas operacionais.

```
I/flutter (23557): Erro ao exportar KMZ: 
Invalid argument(s): Bytes are required on Android & iOS when saving a file.
```

## Solução Implementada

### Estratégia por Plataforma

1. **Android/iOS**: Usar `path_provider` para salvar em diretório seguro (Documentos da App)
2. **Desktop (Windows/Linux/macOS)**: Permitir que o usuário escolha o local com FilePicker

### Mudanças no Código

#### 1. Import de `path_provider`

```dart
import 'package:path_provider/path_provider.dart';
```

#### 2. Métodos de Export Modificados

Tanto `_exportKML()` quanto `_exportKMZ()` foram atualizados com lógica condicional:

```dart
Future<void> _exportKML() async {
  try {
    setState(() => _isLoading = true);

    final provider = context.read<InfrastructureProvider>();
    
    String filePath;
    
    // No Android/iOS, usar path_provider para diretório seguro
    if (Theme.of(context).platform == TargetPlatform.android ||
        Theme.of(context).platform == TargetPlatform.iOS) {
      final directory = await getApplicationDocumentsDirectory();
      filePath = '${directory.path}/infraestrutura_${DateTime.now().millisecondsSinceEpoch}.kml';
    } else {
      // Em desktop, permitir que o usuário escolha
      final result = await FilePicker.platform.saveFile(
        fileName: 'infraestrutura_${DateTime.now().millisecondsSinceEpoch}.kml',
        type: FileType.custom,
        allowedExtensions: ['kml'],
      );

      if (result == null) {
        // Usuário cancelou
        if (!mounted) return;
        setState(() => _isLoading = false);
        return;
      }
      filePath = result;
    }

    // Resto da lógica de export...
  }
}
```

## Por que Isso Funciona

### Problema Original
- `FilePicker.platform.saveFile()` no Android retorna paths como `/cache/...` ou outros locais não-writable
- O app não tem permissão para escrever nesses locais
- Flutter levanta erro "Bytes are required"

### Solução
- `getApplicationDocumentsDirectory()` retorna diretório seguro: `/data/data/com.example.app/files/`
- Esse diretório é **garantidamente gravável** pelo app
- `path_provider` gerencia permissões automaticamente

## Arquivos Modificados

- `lib/screens/import_export_screen.dart`:
  - ✅ Adicionado import de `path_provider`
  - ✅ Método `_exportKML()` com lógica condicional
  - ✅ Método `_exportKMZ()` com lógica condicional

## Testando a Solução

### No Android
1. Abra o app em um dispositivo/emulador Android
2. Vá para Import/Export
3. Clique em "Exportar KML" ou "Exportar KMZ"
4. ✅ Arquivo será salvo em: `/data/data/com.app/files/infraestrutura_TIMESTAMP.kml`
5. Pode ser acessado via:
   - Android Studio: Device File Explorer
   - Comando: `adb pull /data/data/com.app/files/infraestrutura_*.kml`

### No Desktop
1. Clique em "Exportar KML" ou "Exportar KMZ"
2. Dialog abre para escolher local
3. Arquivo salvo no local escolhido

## Melhorias Futuras (Opcional)

Se quiser permitir salvar em Downloads/Storage público no Android:

```dart
// Adicionar permissão no AndroidManifest.xml
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />

// Usar permission_handler package
import 'package:permission_handler/permission_handler.dart';

// Depois, usar path como:
final directory = await getExternalFilesDirectory(null); // /storage/emulated/0/Android/data/...
// OU para Downloads:
final downloadsDir = Directory('/storage/emulated/0/Download');
```

## Checklist de Verificação

- [x] Import de `path_provider` adicionado
- [x] Detecção de plataforma implementada
- [x] Android/iOS usando `getApplicationDocumentsDirectory()`
- [x] Desktop usando `FilePicker`
- [x] Tratamento de cancelamento
- [x] Mensagens de sucesso com path exibido
- [x] Zero erros de compilação

## Debugando Problemas

Se ainda houver erro:

### Verificar permissões (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### Verificar logs
```bash
adb logcat | grep flutter
```

### Verificar se diretório existe
```bash
adb shell ls -la /data/data/com.app/files/
```

### Force clear cache
```bash
adb shell pm clear com.app.package
```

---

**Status**: ✅ Implementado e compilando sem erros
**Pronto para teste no Android/iOS**
