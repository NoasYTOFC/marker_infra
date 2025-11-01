import 'package:flutter/material.dart';

class HelpScreen extends StatefulWidget {
  final int initialIndex;

  const HelpScreen({super.key, this.initialIndex = 0});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  late int _selectedIndex;

  final List<_HelpSection> _sections = [
    _HelpSection(
      title: '📍 Mapa',
      icon: Icons.map,
      description: 'Visualize e gerencie sua infraestrutura',
      items: [
        _HelpItem(
          title: 'Visualizar Elementos',
          description: 'Veja CTOs, OLTs, CEOs, DIOs e Cabos no mapa em tempo real com cores diferentes para cada tipo.',
        ),
        _HelpItem(
          title: 'Clicar em um Elemento',
          description: 'Toque em qualquer marcador para ver detalhes, editar ou deletar o elemento.',
        ),
        _HelpItem(
          title: 'Ferramentas de Zoom',
          description: 'Use os botões +/- no canto superior direito ou use o gesto de pinça para aumentar/diminuir zoom.',
        ),
        _HelpItem(
          title: '📍 Minha Localização',
          description: 'Clique no botão de GPS para centralizar o mapa na sua posição atual.',
        ),
        _HelpItem(
          title: '🔍 Pesquisar Coordenadas',
          description: 'Use o botão de lupa para buscar um local digitando latitude e longitude. Suporta dois modos: separado ou combinado.',
        ),
        _HelpItem(
          title: '📏 Medir Distâncias',
          description: 'Clique no botão de régua, depois clique no mapa para adicionar pontos. A distância será calculada automaticamente.',
        ),
        _HelpItem(
          title: '🗺️ Legenda',
          description: 'Clique no botão de legenda para ver as cores e significados de cada elemento e tipo de cabo.',
        ),
      ],
    ),
    _HelpSection(
      title: '➕ Adicionar Elementos',
      icon: Icons.add_circle,
      description: 'Como criar novos elementos na infraestrutura',
      items: [
        _HelpItem(
          title: 'Clicar no Botão Adicionar',
          description: 'No mapa, clique no botão flutuante azul "Adicionar" para abrir o menu de criação.',
        ),
        _HelpItem(
          title: 'Selecionar Tipo',
          description: 'Escolha entre CTO, OLT, CEO, DIO ou Cabo. Cada um tem características diferentes.',
        ),
        _HelpItem(
          title: 'Clicar no Mapa para Posicionar',
          description: 'Para itens pontuais (CTO, OLT, CEO, DIO): clique uma vez no mapa para escolher a localização.',
        ),
        _HelpItem(
          title: 'Definir Rota do Cabo',
          description: 'Para cabos: clique no mapa múltiplas vezes para traçar a rota. Use "Desfazer" se errar. Mínimo 2 pontos.',
        ),
        _HelpItem(
          title: 'Inserir Coordenadas Manualmente',
          description: 'Expanda a seção "Inserir Coordenadas" para digitar latitude e longitude ao invés de clicar no mapa.',
        ),
        _HelpItem(
          title: 'Confirmar Posição',
          description: 'Quando satisfeito com a localização, clique "OK" para prosseguir com os detalhes do elemento.',
        ),
        _HelpItem(
          title: 'Preencher Formulário',
          description: 'Complete as informações do elemento (nome, descrição, configurações técnicas, etc).',
        ),
        _HelpItem(
          title: 'Salvar',
          description: 'Clique no botão "Salvar" para criar o elemento. Ele aparecerá imediatamente no mapa.',
        ),
      ],
    ),
    _HelpSection(
      title: '✏️ Editar Elementos',
      icon: Icons.edit,
      description: 'Modifique elementos existentes',
      items: [
        _HelpItem(
          title: 'Abrir Detalhes',
          description: 'Clique no elemento no mapa para abrir o painel de detalhes.',
        ),
        _HelpItem(
          title: 'Clicar em Editar',
          description: 'No painel de detalhes, clique no botão "Editar" (lápis) para entrar no modo de edição.',
        ),
        _HelpItem(
          title: 'Modificar Localização',
          description: 'Se precisar mover o elemento, clique "Alterar Localização" e siga os passos de posicionamento novamente.',
        ),
        _HelpItem(
          title: 'Modificar Detalhes',
          description: 'Altere nome, descrição, configurações técnicas e outras informações conforme necessário.',
        ),
        _HelpItem(
          title: 'Salvar Mudanças',
          description: 'Clique "Salvar" para aplicar as alterações. O elemento será atualizado no mapa.',
        ),
      ],
    ),
    _HelpSection(
      title: '🗑️ Deletar Elementos',
      icon: Icons.delete,
      description: 'Remove elementos da infraestrutura',
      items: [
        _HelpItem(
          title: 'Abrir Detalhes',
          description: 'Clique no elemento no mapa para abrir o painel de detalhes.',
        ),
        _HelpItem(
          title: 'Clicar em Deletar',
          description: 'No painel de detalhes, clique no botão "Deletar" (lixeira).',
        ),
        _HelpItem(
          title: 'Confirmar Exclusão',
          description: 'Uma caixa de confirmação aparecerá. Confirme para deletar permanentemente o elemento.',
        ),
        _HelpItem(
          title: 'Elemento Deletado',
          description: 'O elemento será removido imediatamente do mapa e da lista de elementos.',
        ),
      ],
    ),
    _HelpSection(
      title: '📋 Lista de Elementos',
      icon: Icons.list,
      description: 'Gerencie seus elementos em formato de lista',
      items: [
        _HelpItem(
          title: 'Abrir Lista',
          description: 'Clique na aba "Elementos" na barra inferior para ver todos os elementos em lista.',
        ),
        _HelpItem(
          title: 'Filtrar por Tipo',
          description: 'Use as abas no topo para filtrar elementos: CTO, OLT, CEO, DIO ou Cabos.',
        ),
        _HelpItem(
          title: 'Visualizar Detalhes',
          description: 'Clique em um elemento da lista para ver seus detalhes completos.',
        ),
        _HelpItem(
          title: 'Navegar no Mapa',
          description: 'Use o botão "📍 Ver no Mapa" para centralizar o mapa no elemento selecionado.',
        ),
        _HelpItem(
          title: 'Editar ou Deletar',
          description: 'Assim como no mapa, você pode editar ou deletar elementos a partir da lista.',
        ),
      ],
    ),
    _HelpSection(
      title: '📊 Estatísticas',
      icon: Icons.analytics,
      description: 'Analise dados sobre sua infraestrutura',
      items: [
        _HelpItem(
          title: 'Abrir Estatísticas',
          description: 'Clique na aba "Estatísticas" na barra inferior para ver gráficos e dados.',
        ),
        _HelpItem(
          title: 'Visualizar Gráficos',
          description: 'Veja gráficos sobre quantidade de elementos, distribuição, e outras métricas.',
        ),
        _HelpItem(
          title: 'Dados em Tempo Real',
          description: 'Os gráficos são atualizados automaticamente quando você adiciona, edita ou deleta elementos.',
        ),
      ],
    ),
    _HelpSection(
      title: '💾 Importar/Exportar',
      icon: Icons.import_export,
      description: 'Backup e compartilhamento de dados',
      items: [
        _HelpItem(
          title: 'Abrir Menu',
          description: 'Clique no ícone de importar/exportar no canto superior direito do AppBar.',
        ),
        _HelpItem(
          title: 'Exportar Dados',
          description: 'Clique "Exportar" para fazer download de seus dados em formato JSON. Serve como backup.',
        ),
        _HelpItem(
          title: 'Importar Dados',
          description: 'Clique "Importar" e selecione um arquivo JSON para restaurar seus dados. Você será perguntado se deseja fusionar ou substituir.',
        ),
        _HelpItem(
          title: 'Smart Merge',
          description: 'Ao importar, o app automaticamente mescla dados novos com os existentes, comparando timestamps para evitar perda de informações.',
        ),
      ],
    ),
    _HelpSection(
      title: '🔧 Dicas Avançadas',
      icon: Icons.lightbulb,
      description: 'Truques e dicas úteis',
      items: [
        _HelpItem(
          title: 'Arraste para Mover',
          description: 'Pressione e segure um elemento no mapa, então arraste para mover sua localização durante a edição.',
        ),
        _HelpItem(
          title: 'Glow Effect',
          description: 'Quando você está editando um elemento, ele recebe um brilho colorido para destacá-lo facilmente.',
        ),
        _HelpItem(
          title: 'Salvo Automaticamente',
          description: 'Todos os dados são salvos automaticamente no seu dispositivo. Não se preocupe em perder informações!',
        ),
        _HelpItem(
          title: 'Fusões em CEOs',
          description: 'Cada CEO pode conter múltiplas fusões. As fusões são gerenciadas separadamente e rastreiam entrada/saída de cabos.',
        ),
        _HelpItem(
          title: 'Dois Modos de Coordenadas',
          description: 'Ao adicionar elementos, você pode clicar no mapa OU digitar coordenadas manualmente. Escolha o que preferir!',
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final section = _sections[_selectedIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('❓ Ajuda'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Menu horizontal de seções
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: List.generate(_sections.length, (index) {
                  final isSelected = index == _selectedIndex;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: FilterChip(
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _selectedIndex = index);
                      },
                      label: Text(_sections[index].title),
                      avatar: Icon(_sections[index].icon, size: 18),
                      backgroundColor: Colors.grey[200],
                      selectedColor: Colors.blue.shade100,
                      labelStyle: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.blue : Colors.black87,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          const Divider(height: 1),
          // Conteúdo da seção
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cabeçalho da seção
                    Row(
                      children: [
                        Icon(
                          section.icon,
                          size: 32,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                section.title,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                section.description,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    // Items da seção
                    ...section.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    )),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpSection {
  final String title;
  final IconData icon;
  final String description;
  final List<_HelpItem> items;

  _HelpSection({
    required this.title,
    required this.icon,
    required this.description,
    required this.items,
  });
}

class _HelpItem {
  final String title;
  final String description;

  _HelpItem({
    required this.title,
    required this.description,
  });
}
