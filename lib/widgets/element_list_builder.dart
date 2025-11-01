import 'package:flutter/material.dart';
import '../models/cto_model.dart';
import '../models/olt_model.dart';
import '../models/ceo_model.dart';
import '../models/dio_model.dart';
import '../models/cabo_model.dart';

/// Widget reutilizável para listas com busca e seleção
class ElementListBuilder {
  /// Filtra um elemento baseado em query
  static bool matchesSearch(String elementName, String query) {
    return elementName.toLowerCase().contains(query.toLowerCase());
  }

  /// Constrói um item de lista com suporte a seleção
  static Widget buildSelectableListItem({
    required BuildContext context,
    required String id,
    required String title,
    required String subtitle,
    required CircleAvatar avatar,
    required bool isSelected,
    required VoidCallback onDelete,
    required VoidCallback onTap,
    required VoidCallback onLongPress,
    bool selectionMode = false,
  }) {
    return Card(
      color: isSelected ? Colors.blue.withOpacity(0.2) : null,
      child: ListTile(
        leading: selectionMode
            ? Checkbox(
                value: isSelected,
                onChanged: (_) => onLongPress(),
              )
            : avatar,
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: !selectionMode
            ? IconButton(
                icon: const Icon(Icons.delete),
                onPressed: onDelete,
              )
            : null,
        onTap: onTap,
        onLongPress: selectionMode ? null : onLongPress,
      ),
    );
  }

  /// Constrói lista de CTOs com filtro
  static List<CTOModel> filterCTOs(List<CTOModel> items, String query) {
    if (query.isEmpty) return items;
    return items
        .where((cto) => matchesSearch(cto.nome, query))
        .toList();
  }

  /// Constrói lista de OLTs com filtro
  static List<OLTModel> filterOLTs(List<OLTModel> items, String query) {
    if (query.isEmpty) return items;
    return items
        .where((olt) => matchesSearch(olt.nome, query))
        .toList();
  }

  /// Constrói lista de CEOs com filtro
  static List<CEOModel> filterCEOs(List<CEOModel> items, String query) {
    if (query.isEmpty) return items;
    return items
        .where((ceo) => matchesSearch(ceo.nome, query))
        .toList();
  }

  /// Constrói lista de DIOs com filtro
  static List<DIOModel> filterDIOs(List<DIOModel> items, String query) {
    if (query.isEmpty) return items;
    return items
        .where((dio) => matchesSearch(dio.nome, query))
        .toList();
  }

  /// Constrói lista de Cabos com filtro
  static List<CaboModel> filterCabos(List<CaboModel> items, String query) {
    if (query.isEmpty) return items;
    return items
        .where((cabo) => matchesSearch(cabo.nome, query))
        .toList();
  }

  /// Widget vazio com mensagem customizada
  static Widget buildEmptyState(String query, String elementType) {
    if (query.isEmpty) {
      return Center(
        child: Text('Nenhum$elementType cadastrado'),
      );
    } else {
      return Center(
        child: Text('Nenhum$elementType encontrado com "$query"'),
      );
    }
  }
}
