# 📘 Guia de Desenvolvimento - Marker Infra

## 🏗️ Estrutura do Projeto

```
lib/
├── models/              # Modelos de dados
│   ├── element_type.dart      # Enum de tipos de elementos
│   ├── cto_model.dart         # Modelo de CTO
│   ├── cabo_model.dart        # Modelo de Cabo
│   ├── olt_model.dart         # Modelo de OLT
│   ├── ceo_model.dart         # Modelo de CEO
│   └── dio_model.dart         # Modelo de DIO
│
├── providers/          # Gerenciamento de estado
│   └── infrastructure_provider.dart
│
├── screens/           # Telas da aplicação
│   ├── home_screen.dart
│   ├── map_screen.dart
│   ├── elements_list_screen.dart
│   ├── statistics_screen.dart
│   └── import_export_screen.dart
│
├── services/          # Serviços
│   └── kml_service.dart      # Import/Export KML/KMZ
│
├── utils/             # Utilitários
│   └── examples_helper.dart  # Exemplos de código
│
└── main.dart          # Ponto de entrada
```

## 🔧 Como Adicionar Novos Elementos

### 1. Criar um novo elemento programaticamente

```dart
import 'package:uuid/uuid.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

// No seu widget
final provider = context.read<InfrastructureProvider>();
const uuid = Uuid();

// Criar CTO
final cto = CTOModel(
  id: uuid.v4(),
  nome: 'CTO-001',
  posicao: LatLng(-23.5505, -46.6333),
  numeroPortas: 16,
  tipoSplitter: '1:16',
  descricao: 'Minha primeira CTO',
);

provider.addCTO(cto);
```

### 2. Criar um cabo com configuração ABNT

```dart
// Cabo de 24 fibras
final cabo = CaboModel(
  id: uuid.v4(),
  nome: 'CABO-PRINCIPAL-001',
  rota: [
    LatLng(-23.5505, -46.6333),  // Ponto inicial
    LatLng(-23.5515, -46.6343),  // Ponto intermediário
    LatLng(-23.5525, -46.6353),  // Ponto final
  ],
  configuracao: ConfiguracaoCabo.fo24,  // 24 fibras
  tipoInstalacao: 'Aéreo',
);

provider.addCabo(cabo);

// Metragem é calculada automaticamente!
print('Metragem: ${cabo.calcularMetragem()}m');
```

### 3. Configurar uma OLT completa

```dart
final olt = OLTModel(
  id: uuid.v4(),
  nome: 'OLT-CENTRAL',
  posicao: LatLng(-23.5500, -46.6320),
  ipAddress: '192.168.1.1',
  numeroSlots: 4,
  fabricante: 'ZTE',
  modelo: 'C300',
  // Slots são gerados automaticamente com 16 PONs cada
);

provider.addOLT(olt);

// Total de PONs
print('Total PONs: ${olt.totalPONs}'); // 64 (4 slots × 16 PONs)
```

## 📤 Exportação com KEYS

### Como funciona o sistema de KEYS

Ao exportar, cada elemento gera automaticamente sua descrição com KEYS:

```dart
final cto = CTOModel(
  nome: 'CTO-001',
  numeroPortas: 16,
  tipoSplitter: '1:16',
  // ...
);

print(cto.gerarDescricaoComKeys());
```

**Saída:**
```
--- KEYS ---
TYPE: CTO
PORTAS: 16
SPLITTER: 1:16
NUMERO: CTO-001
```

### Exportar projeto completo

```dart
// KML
final kmlContent = KMLExporter.generateKML(
  ctos: provider.ctos,
  cabos: provider.cabos,
  olts: provider.olts,
  ceos: provider.ceos,
  dios: provider.dios,
);

// KMZ (compactado)
final kmzBytes = await KMLExporter.generateKMZ(
  ctos: provider.ctos,
  cabos: provider.cabos,
  olts: provider.olts,
  ceos: provider.ceos,
  dios: provider.dios,
);
```

## 📥 Importação de KML/KMZ

### Importação automática (com KEYS)

```dart
// Analisar arquivo
final analysis = await KMLParser.analyzeKMZ(file);

if (analysis.hasKeys) {
  // Importação automática!
  for (final folder in analysis.folders) {
    for (final placemark in folder.placemarks) {
      if (placemark.detectedType == ElementType.cto) {
        // Criar CTO automaticamente
        final cto = CTOModel(
          id: uuid.v4(),
          nome: placemark.name,
          posicao: placemark.point!,
          numeroPortas: int.parse(placemark.keys['PORTAS'] ?? '8'),
          tipoSplitter: placemark.keys['SPLITTER'] ?? '1:8',
        );
        provider.addCTO(cto);
      }
    }
  }
}
```

### Importação com mapeamento manual

```dart
// Usuário seleciona o tipo de cada pasta
final mappings = <String, ElementType>{
  'Caixas': ElementType.cto,
  'Cabos_Rede': ElementType.cabo,
  'OLTs': ElementType.olt,
};

// Importar com base no mapeamento
_importWithMappings(analysis, mappings);
```

## 🎨 Configurações de Fibra (Padrão ABNT)

### Cores disponíveis

```dart
CoresFibras.padrao12Fibras // Lista completa

// Obter cor de uma fibra específica
final cor = CoresFibras.obterCor(5); // "Vermelho"

// Obter cor de um tubo
final corTubo = CoresFibras.obterCorTubo(2); // "Amarelo"
```

### Configurações predefinidas

```dart
ConfiguracaoCabo.fo2    // 2 fibras - 1 tubo
ConfiguracaoCabo.fo4    // 4 fibras - 2 tubos
ConfiguracaoCabo.fo6    // 6 fibras - 3 tubos
ConfiguracaoCabo.fo12   // 12 fibras - 2 tubos
ConfiguracaoCabo.fo24   // 24 fibras - 2 tubos
ConfiguracaoCabo.fo36   // 36 fibras - 3 tubos
ConfiguracaoCabo.fo48   // 48 fibras - 4 tubos
ConfiguracaoCabo.fo72   // 72 fibras - 6 tubos
ConfiguracaoCabo.fo96   // 96 fibras - 8 tubos
ConfiguracaoCabo.fo144  // 144 fibras - 12 tubos

// Acessar propriedades
final config = ConfiguracaoCabo.fo24;
print('Total: ${config.totalFibras}');        // 24
print('Tubos: ${config.numeroTubos}');        // 2
print('Fibras/tubo: ${config.fibrasPorTubo}'); // 12
```

## 🔌 Sistema de Conexões

### Conectar cabo a uma CTO

```dart
final cabo = CaboModel(
  // ...
  pontoInicioId: olt.id,      // Começa na OLT
  pontoFimId: cto.id,         // Termina na CTO
);

final cto = CTOModel(
  // ...
  caboEntradaId: cabo.id,     // Cabo que chega
);
```

### Fazer fusões em CEO

```dart
final fusao = FusaoCEO(
  id: uuid.v4(),
  caboEntradaId: cabo1.id,
  fibraEntradaNumero: 1,      // Fibra 1 do cabo1
  caboSaidaId: cabo2.id,
  fibraSaidaNumero: 1,        // Conecta à fibra 1 do cabo2
  atenuacao: 0.05,            // 0.05 dB
  tecnico: 'João Silva',
);

final ceo = CEOModel(
  // ...
  fusoes: [fusao],
);

provider.addCEO(ceo);
```

### Configurar PON na OLT

```dart
// Atualizar um PON específico
final slot = olt.slots[0];     // Slot 1
final pon = slot.pons[5];      // PON 6

final ponAtualizado = pon.copyWith(
  emUso: true,
  ctoId: cto.id,
  vlan: 100,
  potenciaRx: '-22.5 dBm',
);

// Atualizar na OLT...
```

## 📊 Obter Estatísticas

```dart
final provider = context.read<InfrastructureProvider>();

// Estatísticas gerais
final stats = provider.getStatistics();

print('CTOs: ${stats['totalCTOs']}');
print('Portas ocupadas: ${stats['portasOcupadasCTO']}');
print('Total PONs: ${stats['totalPONs']}');
print('PONs ocupados: ${stats['ponsOcupados']}');
print('Metragem cabos: ${stats['totalMetragemCabos']}m');
```

## 🎯 Boas Práticas

### 1. Sempre use UUID para IDs

```dart
import 'package:uuid/uuid.dart';
const uuid = Uuid();

final id = uuid.v4(); // Gera ID único
```

### 2. Use copyWith para atualizar modelos

```dart
final ctoAtualizada = cto.copyWith(
  nome: 'Novo nome',
  numeroPortas: 32,
);

provider.updateCTO(ctoAtualizada);
```

### 3. Verifique nulos antes de acessar

```dart
final cto = provider.getCTO(id);
if (cto != null) {
  print(cto.nome);
}
```

### 4. Use Provider corretamente

```dart
// Para ler e escutar mudanças
final provider = context.watch<InfrastructureProvider>();

// Para apenas ler uma vez
final provider = context.read<InfrastructureProvider>();

// Não use dentro de métodos build repetidamente
```

## 🚀 Próximos Passos

### Para implementar telas de criação/edição:

1. Criar `screens/cto_form_screen.dart`
2. Adicionar formulário com campos
3. Usar Provider para salvar
4. Navegar de volta

### Para adicionar persistência:

1. Instalar `sqflite`
2. Criar `services/database_service.dart`
3. Implementar CRUD operations
4. Sincronizar com Provider

### Para adicionar diagrams:

1. Usar `fl_chart` ou `custom_paint`
2. Criar `widgets/connection_diagram.dart`
3. Desenhar conexões entre elementos
4. Adicionar interatividade

## 📚 Recursos Adicionais

- [Flutter Documentation](https://flutter.dev/docs)
- [Provider Package](https://pub.dev/packages/provider)
- [flutter_map](https://pub.dev/packages/flutter_map)
- [KML Reference](https://developers.google.com/kml/documentation/kmlreference)

## 🐛 Debug

### Ver todos os elementos

```dart
final provider = context.read<InfrastructureProvider>();
print('CTOs: ${provider.ctos.length}');
print('Cabos: ${provider.cabos.length}');
print('OLTs: ${provider.olts.length}');
```

### Limpar todos os dados

```dart
provider.clearAll();
```

### Adicionar dados de teste

```dart
import 'package:marker_infra/utils/examples_helper.dart';

ExamplesHelper.addExampleData(provider);
```

---

**Dúvidas?** Consulte o código de exemplo em `lib/utils/examples_helper.dart`
