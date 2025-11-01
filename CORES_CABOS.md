# 🌈 Guia de Cores dos Cabos de Fibra Óptica

## Sistema de Cores por Quantidade de Fibras

O aplicativo utiliza **cores específicas** para cada tipo de cabo, facilitando a identificação visual no mapa.

### 📊 Tabela de Cores

| Tipo de Cabo | Fibras | Cor | RGB | Visualização |
|--------------|--------|-----|-----|--------------|
| **2FO** | 2 fibras | 🟡 Amarelo | 255, 221, 0 | Cabo de baixa capacidade |
| **4FO** | 4 fibras | 🔵 Azul Índigo | 64, 81, 181 | Cabo residencial |
| **6FO** | 6 fibras | 🟣 Roxo | 103, 58, 183 | Cabo pequeno porte |
| **12FO** | 12 fibras | 🔵 Ciano | 0, 188, 212 | Cabo padrão distribuição |
| **24FO** | 24 fibras | 🔴 Vermelho | 244, 67, 54 | Cabo backbone local |
| **36FO** | 36 fibras | 🟣 Roxo Escuro | 156, 39, 176 | Cabo alta capacidade |
| **48FO** | 48 fibras | 🟠 Laranja | 255, 152, 0 | Cabo distribuição grande |
| **72FO** | 72 fibras | 🟢 Verde | 76, 175, 80 | Cabo backbone médio |
| **96FO** | 96 fibras | 🔵 Teal | 0, 150, 136 | Cabo alta densidade |
| **144FO** | 144 fibras | 🔵 Índigo | 63, 81, 181 | Cabo backbone principal |

## 🎯 Aplicações Típicas

### 2FO - Amarelo (255, 221, 0)
- **Uso:** Drop final cliente
- **Distância típica:** 50-200m
- **Aplicação:** Última milha, entrada cliente

### 4FO - Azul Índigo (64, 81, 181)
- **Uso:** Derivação pequena
- **Distância típica:** 100-300m
- **Aplicação:** Atendimento residencial, pequenos prédios

### 6FO - Roxo (103, 58, 183)
- **Uso:** Ramais secundários
- **Distância típica:** 200-500m
- **Aplicação:** Pequenos condomínios, ruas curtas

### 12FO - Ciano (0, 188, 212)
- **Uso:** Distribuição padrão
- **Distância típica:** 300-1000m
- **Aplicação:** Ruas, bairros, CTOs padrão

### 24FO - Vermelho (244, 67, 54)
- **Uso:** Backbone local
- **Distância típica:** 500-2000m
- **Aplicação:** Interligação de bairros, áreas comerciais

### 36FO - Roxo Escuro (156, 39, 176)
- **Uso:** Distribuição de alta capacidade
- **Distância típica:** 1-3 km
- **Aplicação:** Grandes áreas, múltiplas CTOs

### 48FO - Laranja (255, 152, 0)
- **Uso:** Distribuição principal
- **Distância típica:** 1-5 km
- **Aplicação:** Interligação de setores, grandes áreas

### 72FO - Verde (76, 175, 80)
- **Uso:** Backbone médio porte
- **Distância típica:** 2-10 km
- **Aplicação:** Conexão entre POPs, grandes redes

### 96FO - Teal (0, 150, 136)
- **Uso:** Alta densidade
- **Distância típica:** 5-15 km
- **Aplicação:** Redes metropolitanas, interligações

### 144FO - Índigo (63, 81, 181)
- **Uso:** Backbone principal
- **Distância típica:** 10+ km
- **Aplicação:** Anel óptico, espinha dorsal da rede

## 📐 Padrão ABNT - Configuração de Tubos

### Cabos Pequenos (2-6 FO)
- **2FO:** 1 tubo, 2 fibras/tubo
- **4FO:** 2 tubos, 2 fibras/tubo
- **6FO:** 3 tubos, 2 fibras/tubo

### Cabos Médios (12-24 FO)
- **12FO:** 2 tubos, 6 fibras/tubo
- **24FO:** 2 tubos, 12 fibras/tubo

### Cabos Grandes (36-144 FO)
- **36FO:** 3 tubos, 12 fibras/tubo
- **48FO:** 4 tubos, 12 fibras/tubo
- **72FO:** 6 tubos, 12 fibras/tubo
- **96FO:** 8 tubos, 12 fibras/tubo
- **144FO:** 12 tubos, 12 fibras/tubo

## 🎨 Visualização no Mapa

### No Aplicativo

Quando você visualizar o mapa:

1. **Cabos aparecem como linhas coloridas**
2. **Cada tipo tem sua cor específica**
3. **Espessura:** 4 pixels para boa visibilidade
4. **Legenda:** Canto inferior esquerdo

### Identificação Rápida

```
🟡 Amarelo = Drop/Cliente (2FO)
🔵 Azul    = Distribuição (4FO, 12FO)
🟣 Roxo    = Médio Porte (6FO, 36FO)
🔴 Vermelho = Backbone Local (24FO)
🟠 Laranja  = Grande Porte (48FO)
🟢 Verde    = Alta Capacidade (72FO)
```

## 💡 Dicas de Uso

### Planejamento Visual

1. **Cores quentes (Amarelo, Laranja, Vermelho):**
   - Indicam extremidades e distribuição
   - Fácil identificação de drops

2. **Cores frias (Azul, Ciano, Verde):**
   - Indicam backbone e alta capacidade
   - Estruturas principais da rede

3. **Cores intermediárias (Roxo, Teal):**
   - Indicam transição
   - Pontos de derivação importantes

### Organização da Rede

```
OLT/DIO (144FO - Índigo)
    ↓
Backbone Principal (72FO - Verde)
    ↓
Distribuição (24FO - Vermelho)
    ↓
Ramais (12FO - Ciano)
    ↓
Derivações (6FO - Roxo)
    ↓
Drops (2FO - Amarelo)
    ↓
Cliente
```

## 🔧 Personalização

### Modificar Cores

As cores estão definidas em:
```dart
lib/models/cabo_model.dart

// Linha ~8-17
enum ConfiguracaoCabo {
  fo2(2, 1, 'Verde, Amarelo', Color.fromRGBO(255, 221, 0, 1.0)),
  fo4(4, 2, 'Verde/Amarelo...', Color.fromRGBO(64, 81, 181, 1.0)),
  // ... etc
}
```

### Cores Customizadas

Para adicionar ou modificar cores:

1. Edite `cabo_model.dart`
2. Altere os valores RGB
3. Formato: `Color.fromRGBO(R, G, B, 1.0)`
4. Valores de 0-255 para R, G, B

## 📋 Exportação KML

### Cores no Arquivo

Ao exportar para KML/KMZ, as cores são preservadas:

```xml
<Style id="cabo_2fo">
  <LineStyle>
    <color>ff00ddf8</color> <!-- Amarelo em KML -->
    <width>3</width>
  </LineStyle>
</Style>
```

### Compatibilidade

✅ Google Earth
✅ Google Maps (importação)
✅ QGIS
✅ ArcGIS
✅ Outros visualizadores KML

## 🎓 Exemplos Práticos

### Rede FTTH Típica

```
Centro de Distribuição:
├── 144FO (Índigo) → POP Principal
├── 72FO (Verde) → Backbone anel
├── 24FO (Vermelho) → Distribuição bairros
└── 12FO (Ciano) → Ramais ruas
    └── 2FO (Amarelo) → Drops clientes
```

### Identificação Visual

No mapa, você verá:
- **Linhas grossas escuras:** Backbone (72FO+)
- **Linhas médias vermelhas:** Distribuição (24FO)
- **Linhas azuis/ciano:** Ramais (12FO)
- **Linhas finas amarelas:** Drops (2FO)

---

**Sistema de cores desenvolvido para máxima usabilidade e identificação rápida** 🎨
