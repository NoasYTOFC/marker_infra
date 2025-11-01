# 🚀 Como Executar o Marker Infra

## ✅ Pré-requisitos

1. **Flutter SDK** instalado (versão 3.9.2 ou superior)
2. **Visual Studio** (para Windows) ou **Android Studio** (para Android)
3. **Git** (opcional, para controle de versão)

## 📦 Instalação

### 1. Instalar Dependências

```bash
cd "c:\Users\primmus\Documents\Net Infra\marker_infra"
flutter pub get
```

### 2. Verificar Instalação

```bash
flutter doctor
```

Certifique-se de que não há erros críticos.

## 🖥️ Executar no Windows

```bash
flutter run -d windows
```

**Ou usando VS Code:**
1. Abra o projeto
2. Pressione `F5`
3. Selecione "Windows (windows-x64)"

## 📱 Executar no Android

### Conectar dispositivo físico:

```bash
# Habilite "Depuração USB" no Android
flutter devices
flutter run -d <DEVICE_ID>
```

### Usar emulador:

```bash
# Iniciar emulador
flutter emulators --launch <EMULATOR_ID>

# Executar app
flutter run
```

## 🧪 Testar a Aplicação

### Adicionar Dados de Exemplo

Edite `lib/main.dart` e adicione dados de exemplo:

```dart
import 'package:provider/provider.dart';
import 'providers/infrastructure_provider.dart';
import 'utils/examples_helper.dart';

// No método build de MainApp, após criar o provider:
ChangeNotifierProvider(
  create: (context) {
    final provider = InfrastructureProvider();
    // Adicionar dados de exemplo
    ExamplesHelper.addExampleData(provider);
    return provider;
  },
  child: MaterialApp(
    // ...
  ),
)
```

Isso adicionará:
- 1 OLT
- 1 DIO
- 1 CEO
- 5 CTOs
- 4 Cabos

### Testando Funcionalidades

#### 1. **Visualizar no Mapa**
- Abra o app
- Vá para aba "Mapa"
- Veja os marcadores no mapa
- Clique em qualquer marcador para ver detalhes

#### 2. **Listar Elementos**
- Vá para aba "Elementos"
- Navegue pelas abas (CTOs, OLTs, CEOs, DIOs, Cabos)
- Veja a lista de elementos

#### 3. **Ver Estatísticas**
- Vá para aba "Estatísticas"
- Veja gráficos de ocupação
- Veja contadores

#### 4. **Exportar KMZ/KML**
- Clique no ícone de importar/exportar no topo
- Clique em "Exportar como KML" ou "Exportar como KMZ"
- O arquivo será gerado com todas as KEYS
- Compartilhe ou salve

#### 5. **Importar KMZ/KML**
- Clique no ícone de importar/exportar
- Clique em "Importar KML/KMZ"
- Selecione um arquivo
- Se tiver KEYS: importação automática
- Se não tiver: mapeie as pastas manualmente

## 🐛 Problemas Comuns

### "pub get failed"

```bash
flutter clean
flutter pub get
```

### "Windows toolchain not installed"

Instale o Visual Studio 2022 com:
- Desktop development with C++
- Windows 10 SDK

### "Android SDK not found"

```bash
flutter config --android-sdk <PATH_TO_SDK>
```

### App não inicia

```bash
# Limpar build
flutter clean

# Rebuild
flutter run
```

## 📝 Desenvolvimento

### Hot Reload

Durante o desenvolvimento, use:
- `r` - Hot reload
- `R` - Hot restart
- `q` - Quit

### Debug

```bash
# Com debug detalhado
flutter run --verbose

# Release mode
flutter run --release
```

### Build para Produção

#### Windows

```bash
flutter build windows
```

Executável em: `build\windows\runner\Release\marker_infra.exe`

#### Android

```bash
flutter build apk
```

APK em: `build\app\outputs\flutter-apk\app-release.apk`

```bash
# APK dividido por arquitetura (menor)
flutter build apk --split-per-abi
```

## 📊 Performance

### Perfil de Performance

```bash
flutter run --profile
```

### Analisar tamanho do app

```bash
flutter build apk --analyze-size
```

## 🔧 Configurações Avançadas

### Alterar Nome do App

Edite `pubspec.yaml`:
```yaml
name: seu_nome_aqui
```

### Alterar Ícone

1. Adicione ícone em `assets/icon.png`
2. Use `flutter_launcher_icons` package

### Adicionar Splash Screen

Use o package `flutter_native_splash`

## 📚 Próximos Passos

1. **Adicionar Persistência**
   - Implementar SQLite
   - Salvar dados localmente

2. **Telas de Formulário**
   - Criar/editar CTOs
   - Criar/editar Cabos
   - Criar/editar OLTs, CEOs, DIOs

3. **Sistema de Diagramas**
   - Visualizar conexões
   - Diagramas interativos

4. **Relatórios**
   - Gerar PDFs
   - Exportar Excel

## 💡 Dicas

- Use `flutter pub outdated` para verificar atualizações
- Leia `DESENVOLVIMENTO.md` para detalhes técnicos
- Consulte `lib/utils/examples_helper.dart` para exemplos de código

## 📞 Suporte

Para problemas específicos:
1. Verifique os logs com `flutter run --verbose`
2. Limpe o projeto com `flutter clean`
3. Verifique `flutter doctor`

## ✨ Recursos Implementados

- ✅ Modelos completos de dados (CTO, Cabo, OLT, CEO, DIO)
- ✅ Sistema de KEYS para KML/KMZ
- ✅ Interface de mapa interativo
- ✅ Listas de elementos
- ✅ Estatísticas e gráficos
- ✅ Import/Export KMZ/KML
- ✅ Padrão ABNT para fibras
- ✅ Sistema de conexões (estrutura)
- ✅ Provider para gerenciamento de estado

## 🎯 Próximas Features

- 🔄 Formulários de criação/edição
- 🔄 Banco de dados SQLite
- 🔄 Diagramas visuais de conexões
- 🔄 GPS e localização
- 🔄 Modo offline
- 🔄 Sincronização em nuvem
- 🔄 Relatórios PDF

---

**Desenvolvido para profissionais de infraestrutura de redes no Brasil** 🇧🇷
