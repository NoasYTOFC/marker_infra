// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import 'package:latlong2/latlong.dart';
import '../models/element_type.dart';
import '../models/cto_model.dart';
import '../models/cabo_model.dart';
import '../models/olt_model.dart';
import '../models/ceo_model.dart';
import '../models/dio_model.dart';
/// Resultado da análise de um arquivo KML/KMZ
class KMLAnalysisResult {
  final List<KMLFolder> folders;
  final bool hasKeys;
  final Map<String, ElementType> detectedTypes;

  KMLAnalysisResult({
    required this.folders,
    required this.hasKeys,
    required this.detectedTypes,
  });
}

/// Pasta dentro do KML
class KMLFolder {
  final String name;
  final List<KMLPlacemark> placemarks;
  final List<KMLFolder> subfolders;

  KMLFolder({
    required this.name,
    required this.placemarks,
    required this.subfolders,
  });
}

/// Placemark (marcador ou linha) do KML
class KMLPlacemark {
  final String name;
  final String? description;
  final LatLng? point;
  final List<LatLng>? lineString;
  final Map<String, String> keys;
  final ElementType? detectedType;

  KMLPlacemark({
    required this.name,
    this.description,
    this.point,
    this.lineString,
    Map<String, String>? keys,
    this.detectedType,
  }) : keys = keys ?? {};

  bool get isPoint => point != null;
  bool get isLineString => lineString != null && lineString!.length > 1;
}

/// Parser de arquivos KML/KMZ
class KMLParser {
  /// Analisa um arquivo KMZ (compactado)
  static Future<KMLAnalysisResult> analyzeKMZ(File file) async {
    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    // Procura pelo arquivo KML principal (geralmente doc.kml)
    ArchiveFile? kmlFile;
    for (final file in archive) {
      if (file.name.toLowerCase().endsWith('.kml')) {
        kmlFile = file;
        break;
      }
    }

    if (kmlFile == null) {
      throw Exception('Nenhum arquivo KML encontrado no KMZ');
    }

    final kmlContent = String.fromCharCodes(kmlFile.content as List<int>);
    return analyzeKML(kmlContent);
  }

  /// Analisa o conteúdo de um arquivo KML
  static Future<KMLAnalysisResult> analyzeKML(String kmlContent) async {
    final document = XmlDocument.parse(kmlContent);
    final kmlElement = document.findAllElements('kml').first;
    final documentElement = kmlElement.findElements('Document').first;

    final folders = <KMLFolder>[];
    final detectedTypes = <String, ElementType>{};
    bool hasKeys = false;

    // Processa pastas
    for (final folderElement in documentElement.findElements('Folder')) {
      final folder = _parseFolder(folderElement);
      folders.add(folder);

      // Verifica se algum placemark tem KEYS
      for (final placemark in folder.placemarks) {
        if (placemark.keys.isNotEmpty) {
          hasKeys = true;
          if (placemark.detectedType != null) {
            detectedTypes[folder.name] = placemark.detectedType!;
          }
        }
      }
    }

    // Processa placemarks soltos (fora de pastas)
    final loosePlacemarks = <KMLPlacemark>[];
    for (final placemarkElement in documentElement.findElements('Placemark')) {
      final placemark = _parsePlacemark(placemarkElement);
      loosePlacemarks.add(placemark);

      if (placemark.keys.isNotEmpty) {
        hasKeys = true;
      }
    }

    if (loosePlacemarks.isNotEmpty) {
      folders.insert(
        0,
        KMLFolder(
          name: 'Elementos sem pasta',
          placemarks: loosePlacemarks,
          subfolders: [],
        ),
      );
    }

    return KMLAnalysisResult(
      folders: folders,
      hasKeys: hasKeys,
      detectedTypes: detectedTypes,
    );
  }

  static KMLFolder _parseFolder(XmlElement folderElement) {
    final name = folderElement.findElements('name').first.innerText;
    final placemarks = <KMLPlacemark>[];
    final subfolders = <KMLFolder>[];

    for (final placemarkElement in folderElement.findElements('Placemark')) {
      placemarks.add(_parsePlacemark(placemarkElement));
    }

    for (final subfolderElement in folderElement.findElements('Folder')) {
      subfolders.add(_parseFolder(subfolderElement));
    }

    return KMLFolder(
      name: name,
      placemarks: placemarks,
      subfolders: subfolders,
    );
  }

  static KMLPlacemark _parsePlacemark(XmlElement placemarkElement) {
    final name = placemarkElement.findElements('name').firstOrNull?.innerText ?? 'Sem nome';
    final description = placemarkElement.findElements('description').firstOrNull?.innerText;

    // Parse KEYS da descrição
    final keys = <String, String>{};
    ElementType? detectedType;

    if (description != null) {
      keys.addAll(CTOModel.parseKeys(description));
      if (keys.containsKey('TYPE')) {
        detectedType = ElementType.fromKey(keys['TYPE']!);
      }
    }

    // Parse coordenadas
    LatLng? point;
    List<LatLng>? lineString;

    final pointElement = placemarkElement.findElements('Point').firstOrNull;
    if (pointElement != null) {
      final coords = pointElement.findElements('coordinates').first.innerText.trim();
      point = _parseCoordinate(coords);
    }

    final lineStringElement = placemarkElement.findElements('LineString').firstOrNull;
    if (lineStringElement != null) {
      final coords = lineStringElement.findElements('coordinates').first.innerText.trim();
      lineString = _parseLineString(coords);
    }

    // ⚡ FALLBACK: Se não detectou tipo, tentar por características
    if (detectedType == null) {
      if (lineString != null && lineString.isNotEmpty) {
        // LineString sem TYPE → provavelmente é CABO
        detectedType = ElementType.cabo;
      } else if (point != null) {
        // Point sem TYPE → provavelmente é ponto de conexão
        // Tentar adivinhar pela descrição
        if (description != null) {
          final desc = description.toLowerCase();
          if (desc.contains('cto')) detectedType = ElementType.cto;
          else if (desc.contains('olt')) detectedType = ElementType.olt;
          else if (desc.contains('ceo')) detectedType = ElementType.ceo;
          else if (desc.contains('dio')) detectedType = ElementType.dio;
        }
      }
    }

    return KMLPlacemark(
      name: name,
      description: description,
      point: point,
      lineString: lineString,
      keys: keys,
      detectedType: detectedType,
    );
  }

  static LatLng _parseCoordinate(String coordString) {
    final parts = coordString.split(',');
    final lng = double.parse(parts[0].trim());
    final lat = double.parse(parts[1].trim());
    return LatLng(lat, lng);
  }

  static List<LatLng> _parseLineString(String coordString) {
    final points = <LatLng>[];
    final lines = coordString.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      final parts = trimmed.split(',');
      if (parts.length >= 2) {
        final lng = double.parse(parts[0].trim());
        final lat = double.parse(parts[1].trim());
        points.add(LatLng(lat, lng));
      }
    }

    return points;
  }
}

/// Gerador de arquivos KML/KMZ
class KMLExporter {
  /// Exporta elementos para KML
  static String generateKML({
    required List<CTOModel> ctos,
    required List<CaboModel> cabos,
    required List<OLTModel> olts,
    required List<CEOModel> ceos,
    required List<DIOModel> dios,
  }) {
    final builder = XmlBuilder();

    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element('kml', nest: () {
      builder.attribute('xmlns', 'http://www.opengis.net/kml/2.2');

      builder.element('Document', nest: () {
        builder.element('name', nest: 'Infraestrutura de Rede');

        // Estilos
        _addStyles(builder);

        // Pasta CTOs
        if (ctos.isNotEmpty) {
          builder.element('Folder', nest: () {
            builder.element('name', nest: 'CTOs');
            for (final cto in ctos) {
              _addCTOPlacemark(builder, cto);
            }
          });
        }

        // Pasta OLTs
        if (olts.isNotEmpty) {
          builder.element('Folder', nest: () {
            builder.element('name', nest: 'OLTs');
            for (final olt in olts) {
              _addOLTPlacemark(builder, olt);
            }
          });
        }

        // Pasta CEOs
        if (ceos.isNotEmpty) {
          builder.element('Folder', nest: () {
            builder.element('name', nest: 'CEOs');
            for (final ceo in ceos) {
              _addCEOPlacemark(builder, ceo);
            }
          });
        }

        // Pasta DIOs
        if (dios.isNotEmpty) {
          builder.element('Folder', nest: () {
            builder.element('name', nest: 'DIOs');
            for (final dio in dios) {
              _addDIOPlacemark(builder, dio);
            }
          });
        }

        // Pasta Cabos
        if (cabos.isNotEmpty) {
          builder.element('Folder', nest: () {
            builder.element('name', nest: 'Cabos');
            for (final cabo in cabos) {
              _addCaboPlacemark(builder, cabo);
            }
          });
        }
      });
    });

    return builder.buildDocument().toXmlString(pretty: true, indent: '  ');
  }

  /// Exporta para arquivo KMZ (compactado)
  static Future<List<int>> generateKMZ({
    required List<CTOModel> ctos,
    required List<CaboModel> cabos,
    required List<OLTModel> olts,
    required List<CEOModel> ceos,
    required List<DIOModel> dios,
  }) async {
    final kmlContent = generateKML(
      ctos: ctos,
      cabos: cabos,
      olts: olts,
      ceos: ceos,
      dios: dios,
    );

    final archive = Archive();
    final kmlBytes = utf8.encode(kmlContent);
    final kmlFile = ArchiveFile('doc.kml', kmlBytes.length, kmlBytes);
    archive.addFile(kmlFile);

    return ZipEncoder().encode(archive)!;
  }

  static void _addStyles(XmlBuilder builder) {
    // Estilo para CTOs
    builder.element('Style', nest: () {
      builder.attribute('id', 'cto');
      builder.element('IconStyle', nest: () {
        builder.element('color', nest: 'ff00ff00'); // Verde
        builder.element('scale', nest: '1.2');
      });
    });

    // Estilo para OLTs
    builder.element('Style', nest: () {
      builder.attribute('id', 'olt');
      builder.element('IconStyle', nest: () {
        builder.element('color', nest: 'ff0000ff'); // Vermelho
        builder.element('scale', nest: '1.5');
      });
    });

    // Estilo para CEOs
    builder.element('Style', nest: () {
      builder.attribute('id', 'ceo');
      builder.element('IconStyle', nest: () {
        builder.element('color', nest: 'ffffff00'); // Amarelo
        builder.element('scale', nest: '1.0');
      });
    });

    // Estilo para DIOs
    builder.element('Style', nest: () {
      builder.attribute('id', 'dio');
      builder.element('IconStyle', nest: () {
        builder.element('color', nest: 'ffff00ff'); // Magenta
        builder.element('scale', nest: '1.0');
      });
    });

    // Estilo para cabos
    builder.element('Style', nest: () {
      builder.attribute('id', 'cabo');
      builder.element('LineStyle', nest: () {
        builder.element('color', nest: 'ff00ffff'); // Ciano
        builder.element('width', nest: '3');
      });
    });
  }

  static void _addCTOPlacemark(XmlBuilder builder, CTOModel cto) {
    builder.element('Placemark', nest: () {
      builder.element('name', nest: cto.nome);
      builder.element('description', nest: cto.gerarDescricaoComKeys());
      builder.element('styleUrl', nest: '#cto');
      builder.element('Point', nest: () {
        builder.element('coordinates',
            nest: '${cto.posicao.longitude},${cto.posicao.latitude},0');
      });
    });
  }

  static void _addOLTPlacemark(XmlBuilder builder, OLTModel olt) {
    builder.element('Placemark', nest: () {
      builder.element('name', nest: olt.nome);
      builder.element('description', nest: olt.gerarDescricaoComKeys());
      builder.element('styleUrl', nest: '#olt');
      builder.element('Point', nest: () {
        builder.element('coordinates',
            nest: '${olt.posicao.longitude},${olt.posicao.latitude},0');
      });
    });
  }

  static void _addCEOPlacemark(XmlBuilder builder, CEOModel ceo) {
    builder.element('Placemark', nest: () {
      builder.element('name', nest: ceo.nome);
      builder.element('description', nest: ceo.gerarDescricaoComKeys());
      builder.element('styleUrl', nest: '#ceo');
      builder.element('Point', nest: () {
        builder.element('coordinates',
            nest: '${ceo.posicao.longitude},${ceo.posicao.latitude},0');
      });
    });
  }

  static void _addDIOPlacemark(XmlBuilder builder, DIOModel dio) {
    builder.element('Placemark', nest: () {
      builder.element('name', nest: dio.nome);
      builder.element('description', nest: dio.gerarDescricaoComKeys());
      builder.element('styleUrl', nest: '#dio');
      builder.element('Point', nest: () {
        builder.element('coordinates',
            nest: '${dio.posicao.longitude},${dio.posicao.latitude},0');
      });
    });
  }

  static void _addCaboPlacemark(XmlBuilder builder, CaboModel cabo) {
    builder.element('Placemark', nest: () {
      builder.element('name', nest: cabo.nome);
      builder.element('description', nest: cabo.gerarDescricaoComKeys());
      builder.element('styleUrl', nest: '#cabo');
      builder.element('LineString', nest: () {
        builder.element('tessellate', nest: '1');
        final coords = cabo.rota
            .map((p) => '${p.longitude},${p.latitude},0')
            .join('\n');
        builder.element('coordinates', nest: coords);
      });
    });
  }
}
