# 🔇 Filtrar Logs de Gralloc

Os logs de `gralloc4` aparecem do Android nativo e atrapalham a visualização dos logs do Flutter.

## Opção 1: Script PowerShell (Recomendado no Windows)

```powershell
.\clean_logs.ps1
```

## Opção 2: Script Batch

```cmd
clean_logs.bat
```

## Opção 3: Comando Direto

```bash
adb logcat --clear && adb logcat -v threadtime "*:V" gralloc4:S gralloc:S BpBinder:S Parcel:S hwc:S
```

## O que este filtro faz:

- **Suprime logs de:**
  - `gralloc4` - Graphics allocation driver
  - `gralloc` - Graphics allocation
  - `BpBinder` - Android IPC
  - `Parcel` - Android serialization
  - `hwc` - Hardware Composer

- **Mantém logs de:**
  - `flutter` - Seu app
  - `I/` - Info
  - `W/` - Warning  
  - `E/` - Error
  - Todos os outros tags

## Via VS Code:

Você pode criar uma tarefa no `tasks.json`:

```json
{
  "label": "Clean Logcat",
  "type": "shell",
  "command": ".\\clean_logs.ps1",
  "presentation": {
    "echo": true,
    "reveal": "always",
    "focus": false
  }
}
```

Depois rodar com `Ctrl+Shift+B` e selecionar "Clean Logcat"
