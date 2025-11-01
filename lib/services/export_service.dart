import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';
import '../models/cto_model.dart';
import '../models/cabo_model.dart';
import '../models/olt_model.dart';
import '../models/ceo_model.dart';
import '../models/dio_model.dart';

/// Serviço centralizado para exportação de arquivos KML/KMZ
class ExportService {
  /// Exporta elementos para arquivo KML e salva em um caminho especificado
  static Future<void> exportToKMLFile(
    String filePath, {
    required List<CTOModel> ctos,
    required List<CaboModel> cabos,
    required List<OLTModel> olts,
    required List<CEOModel> ceos,
    required List<DIOModel> dios,
  }) async {
    try {
      final kmlContent = _generateKML(
        ctos: ctos,
        cabos: cabos,
        olts: olts,
        ceos: ceos,
        dios: dios,
      );

      // Adicionar extensão .kml se não tiver
      String finalPath = filePath;
      if (!finalPath.endsWith('.kml')) {
        finalPath = '$filePath.kml';
      }

      final file = File(finalPath);
      
      // Criar diretório se não existir
      final directory = file.parent;
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      await file.writeAsString(kmlContent, flush: true);
      
      // Validar que o arquivo foi criado
      if (!await file.exists()) {
        throw Exception('Falha ao criar arquivo KML');
      }
      
      final size = await file.length();
      if (size == 0) {
        throw Exception('Arquivo KML vazio após exportação');
      }
    } catch (e) {
      throw Exception('Erro ao exportar KML: $e');
    }
  }

  /// Exporta elementos para arquivo KMZ compactado e salva em um caminho especificado
  static Future<void> exportToKMZFile(
    String filePath, {
    required List<CTOModel> ctos,
    required List<CaboModel> cabos,
    required List<OLTModel> olts,
    required List<CEOModel> ceos,
    required List<DIOModel> dios,
  }) async {
    try {
      final kmlContent = _generateKML(
        ctos: ctos,
        cabos: cabos,
        olts: olts,
        ceos: ceos,
        dios: dios,
      );

      // Criar arquivo KMZ (ZIP com KML dentro)
      final archive = Archive();
      final kmlBytes = utf8.encode(kmlContent);
      final kmlFile = ArchiveFile('doc.kml', kmlBytes.length, kmlBytes);
      archive.addFile(kmlFile);

      // Codificar como ZIP
      final kmzBytes = ZipEncoder().encode(archive);
      if (kmzBytes == null) {
        throw Exception('Falha ao codificar arquivo KMZ');
      }

      // Adicionar extensão .kmz se não tiver
      String finalPath = filePath;
      if (!finalPath.endsWith('.kmz')) {
        finalPath = '$filePath.kmz';
      }

      final file = File(finalPath);
      
      // Criar diretório se não existir
      final directory = file.parent;
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Escrever bytes no arquivo
      await file.writeAsBytes(kmzBytes, flush: true);
      
      // Validar que o arquivo foi criado
      if (!await file.exists()) {
        throw Exception('Falha ao criar arquivo KMZ');
      }
      
      final size = await file.length();
      if (size == 0) {
        throw Exception('Arquivo KMZ vazio após exportação');
      }
    } catch (e) {
      throw Exception('Erro ao exportar KMZ: $e');
    }
  }

  /// Gera conteúdo KML com os elementos especificados
  static String _generateKML({
    required List<CTOModel> ctos,
    required List<CaboModel> cabos,
    required List<OLTModel> olts,
    required List<CEOModel> ceos,
    required List<DIOModel> dios,
  }) {
    final buffer = StringBuffer();
    
    // UTF-8 encoding with BOM is handled by writeAsString
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<kml xmlns="http://www.opengis.net/kml/2.2">');
    buffer.writeln('  <Document>');
    buffer.writeln('    <name>Infraestrutura de Rede</name>');
    
    // Adicionar estilos
    _addStyles(buffer);
    
    // Adicionar pastas com elementos
    if (ctos.isNotEmpty) {
      buffer.writeln('    <Folder>');
      buffer.writeln('      <name>CTOs</name>');
      for (final cto in ctos) {
        _addCTOPlacemark(buffer, cto);
      }
      buffer.writeln('    </Folder>');
    }
    
    if (olts.isNotEmpty) {
      buffer.writeln('    <Folder>');
      buffer.writeln('      <name>OLTs</name>');
      for (final olt in olts) {
        _addOLTPlacemark(buffer, olt);
      }
      buffer.writeln('    </Folder>');
    }
    
    if (ceos.isNotEmpty) {
      buffer.writeln('    <Folder>');
      buffer.writeln('      <name>CEOs</name>');
      for (final ceo in ceos) {
        _addCEOPlacemark(buffer, ceo);
      }
      buffer.writeln('    </Folder>');
    }
    
    if (dios.isNotEmpty) {
      buffer.writeln('    <Folder>');
      buffer.writeln('      <name>DIOs</name>');
      for (final dio in dios) {
        _addDIOPlacemark(buffer, dio);
      }
      buffer.writeln('    </Folder>');
    }
    
    if (cabos.isNotEmpty) {
      buffer.writeln('    <Folder>');
      buffer.writeln('      <name>Cabos</name>');
      for (final cabo in cabos) {
        _addCaboPlacemark(buffer, cabo);
      }
      buffer.writeln('    </Folder>');
    }
    
    buffer.writeln('  </Document>');
    buffer.writeln('</kml>');
    
    return buffer.toString();
  }

  static void _addStyles(StringBuffer buffer) {
    // Estilos para CTOs
    buffer.writeln('    <Style id="cto">');
    buffer.writeln('      <IconStyle>');
    buffer.writeln('        <color>ff0000ff</color>');
    buffer.writeln('        <scale>1.2</scale>');
    buffer.writeln('      </IconStyle>');
    buffer.writeln('    </Style>');
    
    // Estilos para OLTs
    buffer.writeln('    <Style id="olt">');
    buffer.writeln('      <IconStyle>');
    buffer.writeln('        <color>ff00ff00</color>');
    buffer.writeln('        <scale>1.2</scale>');
    buffer.writeln('      </IconStyle>');
    buffer.writeln('    </Style>');
    
    // Estilos para CEOs
    buffer.writeln('    <Style id="ceo">');
    buffer.writeln('      <IconStyle>');
    buffer.writeln('        <color>ffffff00</color>');
    buffer.writeln('        <scale>1.2</scale>');
    buffer.writeln('      </IconStyle>');
    buffer.writeln('    </Style>');
    
    // Estilos para DIOs
    buffer.writeln('    <Style id="dio">');
    buffer.writeln('      <IconStyle>');
    buffer.writeln('        <color>ffff00ff</color>');
    buffer.writeln('        <scale>1.2</scale>');
    buffer.writeln('      </IconStyle>');
    buffer.writeln('    </Style>');
    
    // Estilos para cabos
    buffer.writeln('    <Style id="cabo">');
    buffer.writeln('      <LineStyle>');
    buffer.writeln('        <color>ff00ffff</color>');
    buffer.writeln('        <width>3</width>');
    buffer.writeln('      </LineStyle>');
    buffer.writeln('    </Style>');
  }

  static void _addCTOPlacemark(StringBuffer buffer, CTOModel cto) {
    buffer.writeln('      <Placemark>');
    buffer.writeln('        <name>${_escapeXml(cto.nome)}</name>');
    buffer.writeln('        <description>${_escapeXml(cto.gerarDescricaoComKeys())}</description>');
    buffer.writeln('        <styleUrl>#cto</styleUrl>');
    buffer.writeln('        <Point>');
    buffer.writeln('          <coordinates>${cto.posicao.longitude},${cto.posicao.latitude},0</coordinates>');
    buffer.writeln('        </Point>');
    buffer.writeln('      </Placemark>');
  }

  static void _addOLTPlacemark(StringBuffer buffer, OLTModel olt) {
    buffer.writeln('      <Placemark>');
    buffer.writeln('        <name>${_escapeXml(olt.nome)}</name>');
    buffer.writeln('        <description>${_escapeXml(olt.gerarDescricaoComKeys())}</description>');
    buffer.writeln('        <styleUrl>#olt</styleUrl>');
    buffer.writeln('        <Point>');
    buffer.writeln('          <coordinates>${olt.posicao.longitude},${olt.posicao.latitude},0</coordinates>');
    buffer.writeln('        </Point>');
    buffer.writeln('      </Placemark>');
  }

  static void _addCEOPlacemark(StringBuffer buffer, CEOModel ceo) {
    // Construir descrição com informações básicas e keys
    final descricao = StringBuffer();
    
    // Gerar descrição com keys (as fusões já estão nas keys)
    var descricaoBase = ceo.gerarDescricaoComKeys();
    descricao.writeln(descricaoBase);
    
    buffer.writeln('      <Placemark>');
    buffer.writeln('        <name>${_escapeXml(ceo.nome)}</name>');
    buffer.writeln('        <description>${_escapeXml(descricao.toString())}</description>');
    buffer.writeln('        <styleUrl>#ceo</styleUrl>');
    buffer.writeln('        <Point>');
    buffer.writeln('          <coordinates>${ceo.posicao.longitude},${ceo.posicao.latitude},0</coordinates>');
    buffer.writeln('        </Point>');
    buffer.writeln('      </Placemark>');
  }

  static void _addDIOPlacemark(StringBuffer buffer, DIOModel dio) {
    buffer.writeln('      <Placemark>');
    buffer.writeln('        <name>${_escapeXml(dio.nome)}</name>');
    buffer.writeln('        <description>${_escapeXml(dio.gerarDescricaoComKeys())}</description>');
    buffer.writeln('        <styleUrl>#dio</styleUrl>');
    buffer.writeln('        <Point>');
    buffer.writeln('          <coordinates>${dio.posicao.longitude},${dio.posicao.latitude},0</coordinates>');
    buffer.writeln('        </Point>');
    buffer.writeln('      </Placemark>');
  }

  static void _addCaboPlacemark(StringBuffer buffer, CaboModel cabo) {
    buffer.writeln('      <Placemark>');
    buffer.writeln('        <name>${_escapeXml(cabo.nome)}</name>');
    buffer.writeln('        <description>${_escapeXml(cabo.gerarDescricaoComKeys())}</description>');
    buffer.writeln('        <styleUrl>#cabo</styleUrl>');
    buffer.writeln('        <LineString>');
    buffer.writeln('          <tessellate>1</tessellate>');
    buffer.writeln('          <coordinates>');
    
    for (final ponto in cabo.rota) {
      buffer.writeln('            ${ponto.longitude},${ponto.latitude},0');
    }
    
    buffer.writeln('          </coordinates>');
    buffer.writeln('        </LineString>');
    buffer.writeln('      </Placemark>');
  }

  /// Escapa caracteres especiais XML
  static String _escapeXml(String? text) {
    if (text == null) return '';
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}
