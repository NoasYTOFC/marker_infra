# 📤 Guia de Exportação KML/KMZ - Marker Infra

## Alterações Recentes (Sistema Recriado)

### ✨ Melhorias Implementadas

1. **Novo Serviço de Exportação** (`ExportService`)
   - Centralizado em `lib/services/export_service.dart`
   - Validação robusta de arquivos
   - Tratamento de erros melhorado
   - Escape correto de caracteres XML

2. **Interface Aprimorada**
   - Opção de salvar em local customizado (não compartilhamento automático)
   - Feedback visual melhorado (✅/❌ emojis)
   - Melhor tratamento de cancelamento

3. **Compatibilidade Windows**
   - Usa `FilePicker.platform.saveFile()` em vez de `Share.shareXFiles()`
   - Funciona melhor em ambiente desktop
   - Permite escolher pasta destino

## Como Usar

### Exportar como KML

```dart
await ExportService.exportToKMLFile(
  '/path/to/file.kml',
  ctos: provider.ctos,
  cabos: provider.cabos,
  olts: provider.olts,
  ceos: provider.ceos,
  dios: provider.dios,
);
```

### Exportar como KMZ (Compactado)

```dart
await ExportService.exportToKMZFile(
  '/path/to/file.kmz',
  ctos: provider.ctos,
  cabos: provider.cabos,
  olts: provider.olts,
  ceos: provider.ceos,
  dios: provider.dios,
);
```

## Estrutura dos Arquivos Exportados

### Exemplo KML

```xml
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>Infraestrutura de Rede</name>
    
    <!-- Estilos para cada tipo -->
    <Style id="cto">
      <IconStyle>
        <color>ff0000ff</color>
        <scale>1.2</scale>
      </IconStyle>
    </Style>
    
    <!-- Pastas com elementos -->
    <Folder>
      <name>CTOs</name>
      <Placemark>
        <name>CTO-001</name>
        <description>
        Descrição livre...
        
        --- KEYS ---
        TYPE: CTO
        PORTAS: 16
        ...
        </description>
        <styleUrl>#cto</styleUrl>
        <Point>
          <coordinates>-49.2827,-25.4284,0</coordinates>
        </Point>
      </Placemark>
    </Folder>
  </Document>
</kml>
```

### Arquivo KMZ

KMZ é um arquivo ZIP contendo:
- `doc.kml` - Arquivo KML interno
- (Futuramente) Imagens de ícones

## Características Técnicas

### Validações Implementadas

✅ Verificação de arquivo criado após exportação
✅ Validação de tamanho (não-vazio)
✅ Escape correto de caracteres XML especiais
✅ Tratamento de exceções com mensagens claras

### Escape XML

Caracteres especiais escapados automaticamente:
- `&` → `&amp;`
- `<` → `&lt;`
- `>` → `&gt;`
- `"` → `&quot;`
- `'` → `&apos;`

### Cores Suportadas (Formato KML)

```
- CTO:   ff0000ff (Azul)
- OLT:   ff00ff00 (Verde)
- CEO:   ffffff00 (Ciano)
- DIO:   ffff00ff (Magenta)
- Cabos: ff00ffff (Amarelo)
```

## Fluxo de Uso no App

1. Usuário clica em "Salvar como KML" ou "Salvar como KMZ (Compactado)"
2. Dialogo de salvamento abre (FilePicker)
3. Usuário escolhe pasta e nome do arquivo
4. Aplicativo valida e exporta
5. Mensagem de sucesso ou erro aparece

## Tratamento de Erros

### Cenários Tratados

| Erro | Mensagem | Ação |
|------|----------|------|
| Arquivo não criado | "Falha ao criar arquivo KML" | Mostrar erro |
| Arquivo vazio | "Arquivo KML vazio após exportação" | Mostrar erro |
| Codificação KMZ falhou | "Falha ao codificar arquivo KMZ" | Mostrar erro |
| Permissão negada | Erro do SO | Mostrar erro |
| Cancelado pelo usuário | "Exportação cancelada" | Nenhum erro |

## Importação

A importação continua funcionando com o `KMLParser` existente:
- Detecta automaticamente se tem KEYS
- Importação automática com KEYS
- Fallback para mapeamento manual sem KEYS

## Próximos Passos

- [ ] Adicionar suporte a imagens nos KMZ
- [ ] Exportação seletiva (apenas alguns tipos)
- [ ] Agendamento de exportações automáticas
- [ ] Sincronização com cloud storage

## Suporte

Para problemas de exportação:
1. Verifique permissões de pasta
2. Libere espaço em disco
3. Tente salvar em pasta do usuário (Documentos)
4. Verifique console para erros detalhados

