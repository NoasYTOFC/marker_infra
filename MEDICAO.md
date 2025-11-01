# 📏 Guia da Ferramenta de Medição de Distâncias

## Como Usar

### Ativar a Ferramenta

1. Na tela do mapa, localize o botão com ícone de **régua** (📏) no canto superior direito
2. Clique no botão - ele ficará **vermelho** quando ativo
3. Um painel de informações aparecerá na parte inferior da tela

### Medir Distâncias

1. **Adicionar Pontos:**
   - Com a ferramenta ativa, clique em qualquer local do mapa
   - Cada clique adiciona um ponto numerado (1, 2, 3, ...)
   - Uma linha vermelha conecta os pontos

2. **Visualizar Medidas:**
   - O painel mostra:
     - Número total de pontos
     - Distância total do percurso
     - Distância de cada segmento (1→2, 2→3, etc)

3. **Desfazer:**
   - Clique no botão **↶** (Undo) para remover o último ponto

4. **Limpar Tudo:**
   - Clique no botão **×** (Clear) para remover todos os pontos

5. **Desativar:**
   - Clique novamente no botão da régua
   - Todos os pontos serão automaticamente removidos

## Exemplos de Uso

### 1. Medir Distância Entre Dois Pontos

```
1. Ative a ferramenta
2. Clique no ponto inicial (ex: uma CTO)
3. Clique no ponto final (ex: outra CTO)
4. Veja a distância direta entre eles
```

**Resultado:** "Total: 245.50 m"

### 2. Medir Percurso de Cabo

```
1. Ative a ferramenta
2. Clique no ponto inicial
3. Clique em cada poste ao longo da rota
4. Clique no ponto final
5. Veja a metragem total e de cada trecho
```

**Resultado:**
```
5 pontos
Distância total: 1.25 km

Segmentos:
  1→2: 285.30 m
  2→3: 312.45 m
  3→4: 298.70 m
  4→5: 356.20 m
```

### 3. Planejar Nova Instalação

```
1. Ative a ferramenta
2. Marque o ponto de partida (OLT)
3. Marque pontos intermediários (postes, passagens)
4. Marque o destino (cliente)
5. Use a distância total para calcular cabo necessário
```

**Dica:** Adicione 10-15% na metragem para folga e emendas!

## Informações Técnicas

### Precisão

- Usa o algoritmo de **Haversine** para calcular distâncias geodésicas
- Considera a curvatura da Terra
- Precisão de até **centímetros**

### Unidades

- **Metros (m)**: Para distâncias menores que 1 km
- **Quilômetros (km)**: Para distâncias iguais ou maiores que 1 km
- Conversão automática

### Formato de Exibição

```
Menos de 1 km:    "245.50 m"
1 km ou mais:     "1.25 km"
```

## Recursos Visuais

### Pontos de Medição

- **Formato:** Círculos vermelhos numerados
- **Numeração:** Sequencial (1, 2, 3...)
- **Borda:** Branca para melhor visibilidade

### Linha de Medição

- **Cor:** Vermelha
- **Espessura:** 3 pixels
- **Borda:** Branca para contraste
- **Estilo:** Linha contínua conectando todos os pontos

### Painel de Informações

- **Posição:** Parte inferior da tela
- **Layout:** Card com fundo branco
- **Conteúdo:**
  - Título "Medição"
  - Botões de ação (Undo, Clear)
  - Contadores
  - Lista de segmentos

## Dicas e Truques

### ✅ Boas Práticas

1. **Zoom adequado:** Use zoom 15-18 para maior precisão
2. **Pontos estratégicos:** Marque mudanças de direção
3. **Organização:** Marque de forma sequencial
4. **Anotações:** Anote as medidas importantes antes de limpar

### 🎯 Casos de Uso

#### Planejamento de Rede
- Medir distância entre OLT e áreas de cobertura
- Calcular cabo necessário para expansões
- Verificar viabilidade de rotas

#### Manutenção
- Medir distância até ponto de falha
- Calcular cabo para reparos
- Planejar logística de equipes

#### Orçamentos
- Calcular metragens precisas
- Estimar custos de cabo
- Dimensionar materiais (postes, abraçadeiras, etc)

#### Documentação
- Registrar distâncias reais de instalação
- Criar relatórios técnicos
- Validar plantas e projetos

## Atalhos e Controles

| Ação | Como Fazer |
|------|------------|
| Ativar/Desativar | Clicar no botão 📏 |
| Adicionar ponto | Clicar no mapa (quando ativo) |
| Desfazer último | Clicar em ↶ |
| Limpar tudo | Clicar em × |
| Ver mais detalhes | Observar painel inferior |

## Limitações

- ⚠️ **Medição em linha reta:** A ferramenta mede distância geodésica
- ⚠️ **Relevo:** Não considera diferenças de altitude
- ⚠️ **Obstáculos:** Não detecta obstáculos físicos
- ⚠️ **Precisão do mapa:** Depende do zoom e qualidade do mapa base

## Solução de Problemas

### Não consigo adicionar pontos
- ✓ Verifique se a ferramenta está ativa (botão vermelho)
- ✓ Tente clicar em áreas visíveis do mapa
- ✓ Ajuste o zoom se necessário

### Medidas parecem erradas
- ✓ Verifique se clicou nos pontos corretos
- ✓ Use zoom maior para precisão
- ✓ Considere que é medição em linha reta

### Painel não aparece
- ✓ Role a tela para baixo
- ✓ Reduza o zoom se o painel estiver fora da vista
- ✓ Reative a ferramenta

## Próximas Versões

Recursos planejados:
- 📊 Exportar medições para relatório
- 💾 Salvar medições frequentes
- 🗺️ Considerar altitude (3D)
- 📸 Capturar screenshot da medição
- ✏️ Adicionar anotações aos pontos

---

**Desenvolvido para facilitar o trabalho de profissionais de infraestrutura de redes** 🎯
