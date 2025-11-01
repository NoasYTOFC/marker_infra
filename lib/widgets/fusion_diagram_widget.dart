import 'package:flutter/material.dart';
import '../services/fusion_diagram_service.dart';

/// Função auxiliar para determinar se uma cor é escura
bool _isColorDark(Color? color) {
  if (color == null) return false;
  // Calcula a luminância da cor usando a fórmula padrão
  final luminance = (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) / 255;
  return luminance < 0.5;
}

/// Cria um contorno adaptativo em 8 direções com cor baseada no contraste
List<Shadow> _criarContomoAdaptativo(Color cor) {
  final outlineColor = _isColorDark(cor) ? Colors.white : Colors.black;
  return [
    Shadow(color: outlineColor, blurRadius: 0, offset: const Offset(-1, -1)),
    Shadow(color: outlineColor, blurRadius: 0, offset: const Offset(1, -1)),
    Shadow(color: outlineColor, blurRadius: 0, offset: const Offset(-1, 1)),
    Shadow(color: outlineColor, blurRadius: 0, offset: const Offset(1, 1)),
    Shadow(color: outlineColor, blurRadius: 0, offset: const Offset(0, -1)),
    Shadow(color: outlineColor, blurRadius: 0, offset: const Offset(0, 1)),
    Shadow(color: outlineColor, blurRadius: 0, offset: const Offset(-1, 0)),
    Shadow(color: outlineColor, blurRadius: 0, offset: const Offset(1, 0)),
  ];
}

/// Cria um contorno adaptativo em BoxShadow para ícones
List<BoxShadow> _criarContomoAdaptativoBoxShadow(Color cor) {
  final outlineColor = _isColorDark(cor) ? Colors.white : Colors.black;
  return [
    BoxShadow(color: outlineColor, blurRadius: 0, offset: const Offset(-1, -1)),
    BoxShadow(color: outlineColor, blurRadius: 0, offset: const Offset(1, -1)),
    BoxShadow(color: outlineColor, blurRadius: 0, offset: const Offset(-1, 1)),
    BoxShadow(color: outlineColor, blurRadius: 0, offset: const Offset(1, 1)),
    BoxShadow(color: outlineColor, blurRadius: 0, offset: const Offset(0, -1)),
    BoxShadow(color: outlineColor, blurRadius: 0, offset: const Offset(0, 1)),
    BoxShadow(color: outlineColor, blurRadius: 0, offset: const Offset(-1, 0)),
    BoxShadow(color: outlineColor, blurRadius: 0, offset: const Offset(1, 0)),
    // Sombra suave embaixo
    BoxShadow(color: Colors.black38, blurRadius: 2, offset: const Offset(0, 2)),
  ];
}

/// Widget que desenha uma fibra com sua cor
class FibraWidget extends StatelessWidget {
  final FibraVisual fibra;
  final VoidCallback? onTap;
  final bool isSelected;
  
  const FibraWidget({
    super.key,
    required this.fibra,
    this.onTap,
    this.isSelected = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: fibra.cor,
              width: 5.0,
            ),
          ),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              fibra.cor.withAlpha(30),
              isSelected ? fibra.cor.withAlpha(50) : Colors.grey[50]!,
            ],
          ),
          color: isSelected 
              ? fibra.cor.withAlpha(50)
              : Colors.white,
          borderRadius: BorderRadius.circular(6.0),
          boxShadow: [
            BoxShadow(
              color: fibra.cor.withAlpha(isSelected ? 150 : 60),
              blurRadius: isSelected ? 10 : 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            // Círculo brilhante da fibra
            Container(
              width: 14.0,
              height: 14.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: fibra.cor,
                boxShadow: [
                  BoxShadow(
                    color: fibra.cor.withAlpha(200),
                    blurRadius: 6,
                    spreadRadius: 1,
                  )
                ],
              ),
            ),
            const SizedBox(width: 12.0),
            
            // Informações da fibra
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _OutlineText(
                    'Fibra ${fibra.numeroFibra}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.0,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: _OutlineText(
                      fibra.caboNome,
                      style: TextStyle(
                        fontSize: 11.0,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            
            // Badge com tipo (entrada/saída)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    fibra.cor.withAlpha(120),
                    fibra.cor.withAlpha(80),
                  ],
                ),
                borderRadius: BorderRadius.circular(4.0),
                border: Border.all(
                  color: fibra.cor,
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: fibra.cor.withAlpha(100),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    fibra.isEntrada ? 'Entrada' : 'Saída',
                    style: TextStyle(
                      fontSize: 10.0,
                      color: fibra.cor,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        // Contorno adaptativo baseado na cor da fibra
                        ..._criarContomoAdaptativo(fibra.cor),
                        // Sombra suave embaixo
                        Shadow(
                          color: Colors.black38.withAlpha(180),
                          blurRadius: 2,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4.0),
                  Icon(
                    fibra.isEntrada ? Icons.arrow_downward : Icons.arrow_upward,
                    size: 11.0,
                    color: fibra.cor,
                    shadows: _criarContomoAdaptativoBoxShadow(fibra.cor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget que desenha uma fusão individual
class FusaoDiagramWidget extends StatelessWidget {
  final FusaoVisual fusao;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final bool isSelected;
  
  const FusaoDiagramWidget({
    super.key,
    required this.fusao,
    this.onTap,
    this.onDelete,
    this.onEdit,
    this.isSelected = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSelected
                ? [
                    Colors.blue.withAlpha(40),
                    Colors.blue.withAlpha(20),
                  ]
                : [
                    Colors.white,
                    Colors.grey[50]!,
                  ],
          ),
          border: Border.all(
            color: isSelected 
                ? Colors.blue.withAlpha(200)
                : Colors.grey[200]!,
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? Colors.blue.withAlpha(100)
                  : Colors.grey[300]!.withAlpha(80),
              blurRadius: isSelected ? 12 : 6,
              offset: Offset(0, isSelected ? 4 : 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Número da fusão (header)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10.0,
                            vertical: 6.0,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue,
                                Colors.blue[700]!,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.fiber_manual_record,
                                size: 12.0,
                                color: Colors.white,
                              ),
                              SizedBox(width: 6.0),
                              Text(
                                'Fusão',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (fusao.atenuacao != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10.0,
                              vertical: 6.0,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.orange.withAlpha(150),
                                  Colors.orange.withAlpha(120),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(6.0),
                            ),
                            child: Text(
                              '📊 ${fusao.atenuacao!.toStringAsFixed(2)} dB',
                              style: const TextStyle(
                                fontSize: 11.0,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Fibra de entrada
                  FibraWidget(
                    fibra: fusao.entrada,
                    isSelected: false,
                  ),
                  
                  // Linha de fusão com animação
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Linha base
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 2.0,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blue.withAlpha(100),
                                      Colors.blue.withAlpha(50),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12.0),
                            Expanded(
                              child: Container(
                                height: 2.0,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blue.withAlpha(50),
                                      Colors.blue.withAlpha(100),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        // Ícone central com glow
                        Container(
                          padding: const EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue,
                                Colors.blue[700]!,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withAlpha(200),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.link,
                            size: 18.0,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Fibra de saída
                  FibraWidget(
                    fibra: fusao.saida,
                    isSelected: false,
                  ),
                  
                  // Informações adicionais
                  if (fusao.tecnico != null || fusao.observacao != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Container(
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.grey[100]!,
                              Colors.grey[50]!,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(
                            color: Colors.grey[200]!,
                            width: 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (fusao.tecnico != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6.0),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4.0),
                                      decoration: BoxDecoration(
                                        color: Colors.purple.withAlpha(50),
                                        borderRadius: BorderRadius.circular(3.0),
                                      ),
                                      child: const Icon(
                                        Icons.person,
                                        size: 12.0,
                                        color: Colors.purple,
                                      ),
                                    ),
                                    const SizedBox(width: 6.0),
                                    Expanded(
                                      child: _OutlineText(
                                        fusao.tecnico!,
                                        style: const TextStyle(
                                          fontSize: 11.0,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (fusao.observacao != null)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4.0),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withAlpha(50),
                                      borderRadius: BorderRadius.circular(3.0),
                                    ),
                                    child: const Icon(
                                      Icons.note,
                                      size: 12.0,
                                      color: Colors.green,
                                    ),
                                  ),
                                  const SizedBox(width: 6.0),
                                  Expanded(
                                    child: _OutlineText(
                                      fusao.observacao!,
                                      style: TextStyle(
                                        fontSize: 10.0,
                                        color: Colors.grey[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  
                  // Botões de ação
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (onDelete != null)
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: onDelete,
                              borderRadius: BorderRadius.circular(6.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10.0,
                                  vertical: 6.0,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.withAlpha(50),
                                  borderRadius: BorderRadius.circular(6.0),
                                  border: Border.all(
                                    color: Colors.red.withAlpha(100),
                                    width: 1.0,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.delete_outline,
                                      size: 14.0,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 4.0),
                                    Text(
                                      'Deletar',
                                      style: TextStyle(
                                        fontSize: 10.0,
                                        color: Colors.red,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(width: 8.0),
                        if (onEdit != null)
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: onEdit,
                              borderRadius: BorderRadius.circular(6.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10.0,
                                  vertical: 6.0,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blue.withAlpha(100),
                                      Colors.blue.withAlpha(80),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(6.0),
                                  border: Border.all(
                                    color: Colors.blue.withAlpha(150),
                                    width: 1.0,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.edit_outlined,
                                      size: 14.0,
                                      color: Colors.blue,
                                    ),
                                    SizedBox(width: 4.0),
                                    Text(
                                      'Editar',
                                      style: TextStyle(
                                        fontSize: 10.0,
                                        color: Colors.blue,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Badge de seleção no canto
            if (isSelected)
              Positioned(
                top: 8.0,
                right: 8.0,
                child: Container(
                  padding: const EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withAlpha(200),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 14.0,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Widget para estatísticas de fusão
class FusionStatisticsWidget extends StatelessWidget {
  final Map<String, dynamic> stats;
  
  const FusionStatisticsWidget({
    super.key,
    required this.stats,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.withAlpha(40),
            Colors.blue.withAlpha(20),
          ],
        ),
        border: Border.all(
          color: Colors.blue.withAlpha(100),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withAlpha(60),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue, Colors.blue[700]!],
                  ),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: const Icon(
                  Icons.analytics,
                  size: 18.0,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10.0),
              const Text(
                'Estatísticas de Fusão',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.0,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16.0),
          
          // Grid de estatísticas
          GridView(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.2,
              mainAxisSpacing: 12.0,
              crossAxisSpacing: 12.0,
            ),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _StatisticTile(
                label: 'Total',
                value: '${stats['totalFusoes']}',
                icon: Icons.link,
                color: Colors.blue,
              ),
              _StatisticTile(
                label: 'Média dB',
                value: '${(stats['atenuacaoMedia'] as double).toStringAsFixed(1)} dB',
                icon: Icons.trending_down,
                color: Colors.orange,
              ),
              _StatisticTile(
                label: 'Máxima dB',
                value: '${(stats['atenuacaoMaxima'] as double).toStringAsFixed(1)} dB',
                icon: Icons.trending_up,
                color: Colors.red,
              ),
              _StatisticTile(
                label: 'Cabos',
                value: '${stats['cabosEnvolvidosEntrada'] + stats['cabosEnvolvidosSaida']}',
                icon: Icons.cable,
                color: Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatisticTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  
  const _StatisticTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withAlpha(60),
            color.withAlpha(30),
          ],
        ),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: color.withAlpha(120),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(50),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16.0),
              const SizedBox(width: 6.0),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.0,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4.0),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 13.0,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget que desenha texto com contorno (outline) para melhor legibilidade
class _OutlineText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  
  const _OutlineText(
    this.text, {
    this.style,
    this.maxLines,
    this.overflow,
  });
  
  @override
  Widget build(BuildContext context) {
    final textStyle = style ?? const TextStyle();
    final textColor = textStyle.color ?? Colors.black;
    
    // Adaptar cor do contorno baseado na cor do texto
    final outlineColor = _isColorDark(textColor) ? Colors.white : Colors.black;
    
    return Stack(
      children: [
        // Contorno (outline) - renderizado múltiplas vezes para criar o efeito
        Text(
          text,
          maxLines: maxLines,
          overflow: overflow,
          style: textStyle.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.0
              ..color = outlineColor.withAlpha(220),
          ),
        ),
        // Texto principal
        Text(
          text,
          maxLines: maxLines,
          overflow: overflow,
          style: textStyle.copyWith(
            color: textColor,
          ),
        ),
      ],
    );
  }
}

