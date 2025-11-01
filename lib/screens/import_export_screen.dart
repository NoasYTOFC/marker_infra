import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/infrastructure_provider.dart';
import '../services/kml_service.dart';
import '../services/export_service.dart';
import '../services/smart_import_service.dart';
import '../services/permission_service.dart';
import '../models/element_type.dart';
import '../models/conexao_model.dart';
import 'package:uuid/uuid.dart';
import '../models/cto_model.dart';
import '../models/cabo_model.dart';
import '../models/olt_model.dart';
import '../models/ceo_model.dart';
import '../models/dio_model.dart';
import '../widgets/import_progress_dialog.dart';

class ImportExportScreen extends StatefulWidget {
  final File? sharedFile;
  
  const ImportExportScreen({super.key, this.sharedFile});

  @override
  State<ImportExportScreen> createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends State<ImportExportScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Se recebeu um arquivo compartilhado, processar automaticamente
    if (widget.sharedFile != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _importKML(widget.sharedFile);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Importar/Exportar'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildImportCard(),
                const SizedBox(height: 16),
                _buildExportCard(),
              ],
            ),
    );
  }

  Widget _buildImportCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.file_download, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Importar',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Importe arquivos KML ou KMZ com sua infraestrutura de rede.',
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _importKML,
              icon: const Icon(Icons.upload_file),
              label: const Text('Importar KML/KMZ'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.file_upload, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Exportar',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Exporte sua infraestrutura com KEYS automáticas para facilitar futuras importações. Escolha o local para salvar.',
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _exportKML,
              icon: const Icon(Icons.save),
              label: const Text('Salvar como KML'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _exportKMZ,
              icon: const Icon(Icons.save),
              label: const Text('Salvar como KMZ (Compactado)'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importKML([File? sharedFile]) async {
    try {
      File file;
      
      if (sharedFile != null) {
        // Arquivo foi compartilhado/aberto com o app
        file = sharedFile;
      } else {
        // Selecionar arquivo manualmente
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['kml', 'kmz'],
        );

        if (result == null || result.files.isEmpty) return;
        file = File(result.files.single.path!);
      }

      final isKMZ = file.path.toLowerCase().endsWith('.kmz');

      // Mostrar diálogo de análise
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final analysis = isKMZ
          ? await KMLParser.analyzeKMZ(file)
          : await KMLParser.analyzeKML(await file.readAsString());

      if (!mounted) return;
      Navigator.pop(context); // Fechar diálogo de análise

      if (analysis.hasKeys && analysis.detectedTypes.isNotEmpty) {
        // Importação automática com KEYS e progresso
        if (!mounted) return;
        
        // Usar Navigator.push em vez de showDialog para evitar travamento
        if (!mounted) return;
        Navigator.push(
          context,
          _ImportProgressRoute(
            importProgressDialog: ImportProgressDialog(
              title: 'Importando elementos...',
              importFunction: (callback) => _importWithKeysProgressive(analysis, callback),
              onComplete: () {
                if (mounted) {
                  setState(() => _isLoading = false);
                }
              },
            ),
          ),
        );
      } else {
        // Mostrar diálogo para mapear pastas
        await _showMappingDialog(analysis);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao importar: $e')),
      );
    }
  }

  Future<void> _importWithKeysProgressive(
    KMLAnalysisResult analysis,
    ImportProgressCallback callback,
  ) async {
    final provider = context.read<InfrastructureProvider>();
    final uuid = const Uuid();

    int imported = 0;
    int skipped = 0;
    int updated = 0;

    // 🎯 MAPA DE REMAPEAMENTO DE IDs
    // Quando importamos um cabo, o ID antigo (do arquivo) → novo ID (gerado)
    final Map<String, String> caboIdMap = {}; // oldId → newId

    // Coletar todos os placemarks primeiro
    final allPlacemarks = <KMLPlacemark>[];
    for (final folder in analysis.folders) {
      for (final placemark in folder.placemarks) {
        if (placemark.detectedType != null) {
          allPlacemarks.add(placemark);
        }
      }
    }

    final totalItems = allPlacemarks.length;
    const chunkSize = 30; // Processar 30 itens por vez (reduzido de 50)

    // ═══════════════════════════════════════════════════════════════════
    // 🔶 PRIMEIRA PASSAGEM: Importar TODOS os CABOS primeiro
    // ═══════════════════════════════════════════════════════════════════
    print('🔶 PRIMEIRA PASSAGEM: Importando TODOS os cabos primeiro...');
    
    // Criar índice de cabos por nome para evitar duplicatas
    final cabosByName = <String, CaboModel>{};
    for (final cabo in provider.cabos) {
      cabosByName[cabo.nome] = cabo;
    }
    
    for (final placemark in allPlacemarks) {
      if (placemark.detectedType == ElementType.cabo) {
        if (placemark.lineString != null && placemark.lineString!.isNotEmpty) {
          final descricaoLimpa = GerenciadorConexoes.removerSecaoCompleteKeys(
            SmartImportService.limparKeysDuplicadas(placemark.description),
          );
          final timestampImportacao =
              SmartImportService.extractTimestampFromKeys(placemark.keys);

          // Identificar configuração do cabo pelo TIPO_FO (primeiro tenta)
          ConfiguracaoCabo configuracao = ConfiguracaoCabo.fo24; // padrão
          var tipoFO = placemark.keys['TIPO_FO'] ?? '';
          
          // Se TIPO_FO não existir, tentar FIBRAS
          if (tipoFO.isEmpty) {
            final fibras = int.tryParse(placemark.keys['FIBRAS'] ?? '24');
            if (fibras != null) {
              final config = ConfiguracaoCabo.fromTotalFibras(fibras);
              if (config != null) configuracao = config;
            }
          } else {
            // TIPO_FO vem como "24FO", "12FO", etc
            if (tipoFO.contains('144FO')) configuracao = ConfiguracaoCabo.fo144;
            else if (tipoFO.contains('96FO')) configuracao = ConfiguracaoCabo.fo96;
            else if (tipoFO.contains('72FO')) configuracao = ConfiguracaoCabo.fo72;
            else if (tipoFO.contains('48FO')) configuracao = ConfiguracaoCabo.fo48;
            else if (tipoFO.contains('36FO')) configuracao = ConfiguracaoCabo.fo36;
            else if (tipoFO.contains('24FO')) configuracao = ConfiguracaoCabo.fo24;
            else if (tipoFO.contains('12FO')) configuracao = ConfiguracaoCabo.fo12;
            else if (tipoFO.contains('6FO')) configuracao = ConfiguracaoCabo.fo6;
            else if (tipoFO.contains('4FO')) configuracao = ConfiguracaoCabo.fo4;
            else if (tipoFO.contains('2FO')) configuracao = ConfiguracaoCabo.fo2;
          }

          final oldCaboId = placemark.keys['ID'] ?? placemark.name; // Tentar usar ID do arquivo
          final caboBuscado = cabosByName[placemark.name];
          
          // 🔧 DEBUG: mostrar se encontrou cabo existente
          if (caboBuscado != null) {
            print('   🔍 Cabo "${placemark.name}" encontrado no banco (comparando...)');
          } else {
            print('   ✨ Novo cabo: "${placemark.name}"');
          }
          
          // ⚡ Verificar se cabo já existe
          if (caboBuscado != null) {
            // Criar cabo temporário para comparação
            final caboTemp = CaboModel(
              id: uuid.v4(),
              nome: placemark.name,
              rota: placemark.lineString!,
              descricao: descricaoLimpa,
              configuracao: configuracao,
              dataAtualizacao: timestampImportacao,
            );
            
            final comparison = SmartImportService.compareCabos(caboBuscado, caboTemp);
            if (comparison.isDuplicate) {
              print('       ⏭️ DUPLICADO: ${comparison.reason}');
              // Mapear usando ID existente
              caboIdMap[oldCaboId] = caboBuscado.id;
              continue;
            } else if (comparison.needsUpdate) {
              print('       🔄 ATUALIZAR: ${comparison.reason}');
              // Mapear usando ID existente
              caboIdMap[oldCaboId] = caboBuscado.id;
              // Atualizar cabo existente
              final caboAtualizado = CaboModel(
                id: caboBuscado.id,
                nome: caboBuscado.nome,
                rota: caboBuscado.rota,
                descricao: descricaoLimpa,
                configuracao: configuracao,
                dataCriacao: caboBuscado.dataCriacao,
                dataAtualizacao: timestampImportacao,
              );
              provider.updateCabo(caboAtualizado);
              continue;
            } else {
              print('       ⚠️ DIFERENTE: ${comparison.reason}');
            }
          }
          
          // Novo cabo: gerar novo ID
          final newCaboId = uuid.v4();
          caboIdMap[oldCaboId] = newCaboId;
          print('   ✅ Novo cabo: "$oldCaboId" → "$newCaboId"');

          final cabo = CaboModel(
            id: newCaboId,
            nome: placemark.name,
            rota: placemark.lineString!,
            descricao: descricaoLimpa,
            configuracao: configuracao,
            dataAtualizacao: timestampImportacao,
          );

          provider.addCabo(cabo);
          cabosByName[placemark.name] = cabo;
          imported++;
        }
      }
    }
    print('🔶 PRIMEIRA PASSAGEM CONCLUÍDA: ${caboIdMap.length} cabos mapeados (${imported} novos)\n');

    // Reset counters
    imported = 0;
    skipped = 0;
    updated = 0;

    // ⚡ PRÉ-PROCESSAR: Criar mapas de índices para evitar loops O(n²)
    final ctosByName = <String, CTOModel>{};
    final oltsByName = <String, OLTModel>{};
    final ceosByName = <String, CEOModel>{};
    final diosByName = <String, DIOModel>{};
    
    for (final cto in provider.ctos) {
      ctosByName['${cto.nome}_${cto.posicao.latitude}_${cto.posicao.longitude}'] = cto;
    }
    for (final olt in provider.olts) {
      oltsByName['${olt.nome}_${olt.posicao.latitude}_${olt.posicao.longitude}'] = olt;
    }
    for (final ceo in provider.ceos) {
      ceosByName['${ceo.nome}_${ceo.posicao.latitude}_${ceo.posicao.longitude}'] = ceo;
    }
    for (final dio in provider.dios) {
      diosByName['${dio.nome}_${dio.posicao.latitude}_${dio.posicao.longitude}'] = dio;
    }
    print('✅ Índices criados: ${ctosByName.length} CTOs, ${oltsByName.length} OLTs, ${ceosByName.length} CEOs, ${diosByName.length} DIOs\n');

    // ═══════════════════════════════════════════════════════════════════
    // 🔷 SEGUNDA PASSAGEM: Importar CEOs/CTOs/OLTs/DIOs com mapa pronto
    // ═══════════════════════════════════════════════════════════════════
    print('🔷 SEGUNDA PASSAGEM: Importando outros elementos...');
    
    // Processar em chunks para não travar
    for (int i = 0; i < allPlacemarks.length; i += chunkSize) {
      final end = (i + chunkSize).clamp(0, allPlacemarks.length);
      final chunk = allPlacemarks.sublist(i, end);

      for (final placemark in chunk) {
        // Delay para evitar travamento - aumentado para elementos pesados
        if (placemark.detectedType == ElementType.cabo) {
          await Future.delayed(const Duration(milliseconds: 25));
        } else if (placemark.detectedType == ElementType.ceo) {
          // CEO é pesado (processa fusões), delay maior
          await Future.delayed(const Duration(milliseconds: 40));
        } else {
          await Future.delayed(const Duration(milliseconds: 20));
        }
        try {
          switch (placemark.detectedType!) {
            case ElementType.cto:
              if (placemark.point != null) {
                final descricaoLimpa = GerenciadorConexoes.removerSecaoCompleteKeys(
                  SmartImportService.limparKeysDuplicadas(placemark.description),
                );
                final timestampImportacao =
                    SmartImportService.extractTimestampFromKeys(placemark.keys);

                final cto = CTOModel(
                  id: uuid.v4(),
                  nome: placemark.name,
                  posicao: placemark.point!,
                  descricao: descricaoLimpa,
                  numeroPortas: int.tryParse(placemark.keys['PORTAS'] ?? '8') ?? 8,
                  tipoSplitter: placemark.keys['SPLITTER'] ?? '1:8',
                  numeroCTO: placemark.keys['NUMERO'],
                  dataAtualizacao: timestampImportacao,
                );

                // ⚡ Usar índice ao invés de loop
                final indexKey = '${cto.nome}_${cto.posicao.latitude}_${cto.posicao.longitude}';
                final existing = ctosByName[indexKey];
                
                if (existing != null) {
                  final comparison = SmartImportService.compareCTOs(existing, cto);
                  if (comparison.isDuplicate) {
                    skipped++;
                    callback.report('⏭️ CTO "${cto.nome}" já existe', i + imported + skipped + updated, totalItems);
                  } else if (comparison.needsUpdate) {
                    final ctoAtualizado = CTOModel(
                      id: existing.id,
                      nome: cto.nome,
                      posicao: cto.posicao,
                      descricao: cto.descricao,
                      numeroPortas: cto.numeroPortas,
                      tipoSplitter: cto.tipoSplitter,
                      numeroCTO: cto.numeroCTO,
                      dataAtualizacao: timestampImportacao,
                    );
                    provider.updateCTO(ctoAtualizado);
                    updated++;
                    callback.report('🔄 CTO "${cto.nome}" atualizada', i + imported + skipped + updated, totalItems);
                  }
                } else {
                  provider.addCTO(cto);
                  imported++;
                  callback.report('✅ CTO "${cto.nome}" importada', i + imported + skipped + updated, totalItems);
                }
              }
              break;

            case ElementType.olt:
              if (placemark.point != null) {
                final descricaoLimpa = GerenciadorConexoes.removerSecaoCompleteKeys(
                  SmartImportService.limparKeysDuplicadas(placemark.description),
                );
                final timestampImportacao =
                    SmartImportService.extractTimestampFromKeys(placemark.keys);

                final olt = OLTModel(
                  id: uuid.v4(),
                  nome: placemark.name,
                  posicao: placemark.point!,
                  descricao: descricaoLimpa,
                  ipAddress: placemark.keys['IP'],
                  numeroSlots: int.tryParse(placemark.keys['SLOTS'] ?? '4') ?? 4,
                  fabricante: placemark.keys['FABRICANTE'],
                  modelo: placemark.keys['MODELO'],
                  dataAtualizacao: timestampImportacao,
                );

                // ⚡ Usar índice ao invés de loop
                final indexKey = '${olt.nome}_${olt.posicao.latitude}_${olt.posicao.longitude}';
                final existing = oltsByName[indexKey];
                
                if (existing != null) {
                  final comparison = SmartImportService.compareOLTs(existing, olt);
                  if (comparison.isDuplicate) {
                    skipped++;
                    callback.report('⏭️ OLT "${olt.nome}" já existe', i + imported + skipped + updated, totalItems);
                  } else if (comparison.needsUpdate) {
                    final oltAtualizado = OLTModel(
                      id: existing.id,
                      nome: olt.nome,
                      posicao: olt.posicao,
                      descricao: olt.descricao,
                      ipAddress: olt.ipAddress,
                      numeroSlots: olt.numeroSlots,
                      fabricante: olt.fabricante,
                      modelo: olt.modelo,
                      dataAtualizacao: timestampImportacao,
                    );
                    provider.updateOLT(oltAtualizado);
                    updated++;
                    callback.report('🔄 OLT "${olt.nome}" atualizada', i + imported + skipped + updated, totalItems);
                  }
                } else {
                  provider.addOLT(olt);
                  imported++;
                  callback.report('✅ OLT "${olt.nome}" importada', i + imported + skipped + updated, totalItems);
                }
              }
              break;

            case ElementType.ceo:
              if (placemark.point != null) {
                final descricaoOriginal = placemark.description ?? '';
                final descricaoLimpa = GerenciadorConexoes.removerSecaoCompleteKeys(
                  SmartImportService.limparKeysDuplicadas(descricaoOriginal),
                );

                print('🔍 CEO: ${placemark.name}');
                print('🔑 Keys disponíveis: ${placemark.keys.keys.join(", ")}');
                
                // Debug: mostrar cada KEY com seu valor
                for (var key in placemark.keys.keys) {
                  if (key.startsWith('FUSAO_')) {
                    print('   📍 $key = ${placemark.keys[key]}');
                  }
                }
                
                // ⚡ Chamar apenas UMA VEZ e reutilizar o resultado
                var fusoesParsadas = SmartImportService.parseusoesDasKeys(placemark.keys);
                if (fusoesParsadas.isEmpty) {
                  fusoesParsadas = SmartImportService.parseusoesDaDescricao(descricaoOriginal);
                }

                print('✅ Fusões encontradas: ${fusoesParsadas.length}');
                for (var f in fusoesParsadas) {
                  print('   📌 ${f.caboEntradaId}:${f.fibraEntradaNumero} → ${f.caboSaidaId}:${f.fibraSaidaNumero}');
                }

                // 🔗 REMAP ear IDs das fusões usando o mapa criado na importação de cabos
                print('🔗 Remapeando IDs das fusões...');
                fusoesParsadas = fusoesParsadas.map((f) {
                  final newCaboEntrada = caboIdMap[f.caboEntradaId] ?? f.caboEntradaId;
                  final newCaboSaida = caboIdMap[f.caboSaidaId] ?? f.caboSaidaId;
                  
                  print('   🔗 Fusão: ${f.caboEntradaId} → $newCaboEntrada (entrada)');
                  print('   🔗 Fusão: ${f.caboSaidaId} → $newCaboSaida (saída)');
                  
                  if (f.id.isEmpty) {
                    return FusaoCEO(
                      id: uuid.v4(),
                      caboEntradaId: newCaboEntrada,
                      fibraEntradaNumero: f.fibraEntradaNumero,
                      caboSaidaId: newCaboSaida,
                      fibraSaidaNumero: f.fibraSaidaNumero,
                      atenuacao: f.atenuacao,
                      dataFusao: f.dataFusao,
                      tecnico: f.tecnico,
                      observacao: f.observacao,
                    );
                  }
                  return FusaoCEO(
                    id: f.id,
                    caboEntradaId: newCaboEntrada,
                    fibraEntradaNumero: f.fibraEntradaNumero,
                    caboSaidaId: newCaboSaida,
                    fibraSaidaNumero: f.fibraSaidaNumero,
                    atenuacao: f.atenuacao,
                    dataFusao: f.dataFusao,
                    tecnico: f.tecnico,
                    observacao: f.observacao,
                  );
                }).toList();

                final timestampImportacao =
                    SmartImportService.extractTimestampFromKeys(placemark.keys);

                final ceo = CEOModel(
                  id: uuid.v4(),
                  nome: placemark.name,
                  posicao: placemark.point!,
                  descricao: descricaoLimpa,
                  capacidadeFusoes:
                      int.tryParse(placemark.keys['CAPACIDADE'] ?? '24') ?? 24,
                  tipo: _normalizeTipoInstalacao(placemark.keys['TIPO']),
                  numeroCEO: placemark.keys['NUMERO'],
                  fusoes: fusoesParsadas,
                  dataAtualizacao: timestampImportacao,
                );

                // ⚡ Usar índice ao invés de loop O(n²)
                final indexKey = '${ceo.nome}_${ceo.posicao.latitude}_${ceo.posicao.longitude}';
                final existing = ceosByName[indexKey];
                
                if (existing != null) {
                  final comparison = SmartImportService.compareCEOs(existing, ceo);
                  if (comparison.isDuplicate) {
                    skipped++;
                    callback.report('⏭️ CEO "${ceo.nome}" já existe', i + imported + skipped + updated, totalItems);
                  } else if (comparison.needsUpdate) {
                    final fusoesExistentes = existing.fusoes;
                    final fusoesNovas = ceo.fusoes;
                    final fusoesMerged = <FusaoCEO>[...fusoesExistentes];

                    for (final fusaoNova in fusoesNovas) {
                      FusaoCEO? fusaoExistenteMesma;
                      try {
                        fusaoExistenteMesma = fusoesExistentes.firstWhere(
                          (f) =>
                              f.caboEntradaId == fusaoNova.caboEntradaId &&
                              f.fibraEntradaNumero ==
                                  fusaoNova.fibraEntradaNumero &&
                              f.caboSaidaId == fusaoNova.caboSaidaId &&
                              f.fibraSaidaNumero ==
                                  fusaoNova.fibraSaidaNumero,
                        );
                      } catch (e) {
                        fusaoExistenteMesma = null;
                      }

                      if (fusaoExistenteMesma != null) {
                        fusoesMerged.remove(fusaoExistenteMesma);
                        fusoesMerged.add(
                          FusaoCEO(
                            id: fusaoExistenteMesma.id,
                            caboEntradaId: fusaoExistenteMesma.caboEntradaId,
                            fibraEntradaNumero:
                                fusaoExistenteMesma.fibraEntradaNumero,
                            caboSaidaId: fusaoExistenteMesma.caboSaidaId,
                            fibraSaidaNumero:
                                fusaoExistenteMesma.fibraSaidaNumero,
                            atenuacao: fusaoNova.atenuacao ??
                                fusaoExistenteMesma.atenuacao,
                            dataFusao: fusaoExistenteMesma.dataFusao,
                            tecnico: fusaoExistenteMesma.tecnico,
                            observacao: fusaoExistenteMesma.observacao,
                          ),
                        );
                      } else {
                        fusoesMerged.add(fusaoNova);
                      }
                    }

                    final ceoAtualizado = CEOModel(
                      id: existing.id,
                      nome: ceo.nome,
                      posicao: ceo.posicao,
                      descricao: ceo.descricao,
                      capacidadeFusoes: ceo.capacidadeFusoes,
                      tipo: ceo.tipo,
                      numeroCEO: ceo.numeroCEO,
                      fusoes: fusoesMerged,
                      cabosConectadosIds: existing.cabosConectadosIds,
                      dataAtualizacao: timestampImportacao,
                    );
                    provider.updateCEO(ceoAtualizado);
                    updated++;
                    callback.report('🔄 CEO "${ceo.nome}" atualizada', i + imported + skipped + updated, totalItems);
                  }
                } else {
                  provider.addCEO(ceo);
                  imported++;
                  callback.report('✅ CEO "${ceo.nome}" importada', i + imported + skipped + updated, totalItems);
                }
              }
              break;

            case ElementType.dio:
              if (placemark.point != null) {
                final descricaoLimpa = GerenciadorConexoes.removerSecaoCompleteKeys(
                  SmartImportService.limparKeysDuplicadas(placemark.description),
                );
                final timestampImportacao =
                    SmartImportService.extractTimestampFromKeys(placemark.keys);

                final dio = DIOModel(
                  id: uuid.v4(),
                  nome: placemark.name,
                  posicao: placemark.point!,
                  descricao: descricaoLimpa,
                  numeroPortas: int.tryParse(placemark.keys['PORTAS'] ?? '8') ?? 8,
                  dataAtualizacao: timestampImportacao,
                );

                // ⚡ Usar índice ao invés de loop
                final indexKey = '${dio.nome}_${dio.posicao.latitude}_${dio.posicao.longitude}';
                final existing = diosByName[indexKey];
                
                if (existing != null) {
                  skipped++;
                  callback.report('⏭️ DIO "${dio.nome}" já existe', i + imported + skipped + updated, totalItems);
                } else {
                  provider.addDIO(dio);
                  imported++;
                  callback.report('✅ DIO "${dio.nome}" importada', i + imported + skipped + updated, totalItems);
                }
              }
              break;

            case ElementType.cabo:
              // 🔷 CABOS JÁ FORAM IMPORTADOS NA PRIMEIRA PASSAGEM
              // Pular nesta segunda passagem
              break;

            default:
              break;
          }
        } catch (e) {
          debugPrint('Erro processando ${placemark.name}: $e');
          callback.report('❌ Erro: ${placemark.name}', i + imported + skipped + updated, totalItems);
        }
      }

      // Dar tempo da UI atualizar entre chunks
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (!mounted) return;

    final summary = '''✅ Importados: $imported
🔄 Atualizados: $updated
⏭️ Ignorados: $skipped''';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(summary),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _showMappingDialog(KMLAnalysisResult analysis) async {
    final mappings = <String, ElementType?>{};

    for (final folder in analysis.folders) {
      if (folder.placemarks.isNotEmpty) {
        mappings[folder.name] = null;
      }
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mapear Pastas'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: mappings.keys.map((folderName) {
                  return ListTile(
                    title: Text(folderName),
                    trailing: DropdownButton<ElementType>(
                      hint: const Text('Selecione'),
                      value: mappings[folderName],
                      items: ElementType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.description),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          mappings[folderName] = value;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _importWithMappings(analysis, mappings);
            },
            child: const Text('Importar'),
          ),
        ],
      ),
    );
  }

  Future<void> _importWithMappings(
    KMLAnalysisResult analysis,
    Map<String, ElementType?> mappings,
  ) async {
    // Similar ao _importWithKeys mas usa os mapeamentos manuais
    final provider = context.read<InfrastructureProvider>();
    final uuid = const Uuid();
    int imported = 0;

    for (final folder in analysis.folders) {
      final type = mappings[folder.name];
      if (type == null) continue;

      for (final placemark in folder.placemarks) {
        try {
          switch (type) {
            case ElementType.cto:
              if (placemark.point != null) {
                final cto = CTOModel(
                  id: uuid.v4(),
                  nome: placemark.name,
                  posicao: placemark.point!,
                  numeroPortas: 8,
                  tipoSplitter: '1:8',
                );
                provider.addCTO(cto);
                imported++;
              }
              break;
            // ... outros tipos similar ao _importWithKeys
            default:
              break;
          }
        } catch (e) {
          debugPrint('Erro: $e');
        }
      }
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$imported elementos importados!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _exportKML() async {
    try {
      setState(() => _isLoading = true);

      final provider = context.read<InfrastructureProvider>();
      
      String filePath;
      String defaultFileName = 'infraestrutura_${DateTime.now().millisecondsSinceEpoch}';
      
      // No Android/iOS, solicitar nome customizado
      if (Theme.of(context).platform == TargetPlatform.android ||
          Theme.of(context).platform == TargetPlatform.iOS) {
        
        setState(() => _isLoading = false);
        
        final customName = await showDialog<String?>(
          context: context,
          builder: (ctx) => _ExportFileNameDialog(
            defaultFileName: defaultFileName,
          ),
        );
        
        if (customName == null) {
          // Cancelado
          return;
        }
        
        defaultFileName = customName;
        setState(() => _isLoading = true);
      }
      
      // No Android, solicitar permissão e salvar em /storage/emulated/0/INFRA_EXPORT
      if (Theme.of(context).platform == TargetPlatform.android) {
        // Solicitar permissão de storage
        final hasPermission = await PermissionService.requestStoragePermission();
        if (!hasPermission) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Permissão de armazenamento negada'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        
        final exportDir = Directory('/storage/emulated/0/INFRA_EXPORT');
        
        // Criar pasta se não existir
        if (!await exportDir.exists()) {
          await exportDir.create(recursive: true);
        }
        
        filePath = '${exportDir.path}/$defaultFileName.kml';
      } else if (Theme.of(context).platform == TargetPlatform.iOS) {
        // iOS usar Documents da app
        final directory = await getApplicationDocumentsDirectory();
        filePath = '${directory.path}/$defaultFileName.kml';
      } else {
        // Desktop, permitir que o usuário escolha
        final result = await FilePicker.platform.saveFile(
          fileName: '$defaultFileName.kml',
          type: FileType.custom,
          allowedExtensions: ['kml'],
        );

        if (result == null) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Exportação cancelada'),
              duration: Duration(seconds: 1),
            ),
          );
          return;
        }
        filePath = result;
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      setState(() => _isLoading = true);
      
      try {
        await ExportService.exportToKMLFile(
          filePath,
          ctos: provider.ctos,
          cabos: provider.cabos,
          olts: provider.olts,
          ceos: provider.ceos,
          dios: provider.dios,
        );
        
        if (!mounted) return;
        setState(() => _isLoading = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Arquivo KML exportado!\nLocal: $filePath'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } catch (exportError) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro: $exportError'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    }
  }

  Future<void> _exportKMZ() async {
    try {
      setState(() => _isLoading = true);

      final provider = context.read<InfrastructureProvider>();
      
      String filePath;
      String defaultFileName = 'infraestrutura_${DateTime.now().millisecondsSinceEpoch}';
      
      // Em todas as plataformas, solicitar nome customizado
      setState(() => _isLoading = false);
      
      final customName = await showDialog<String?>(
        context: context,
        builder: (ctx) => _ExportFileNameDialog(
          defaultFileName: defaultFileName,
        ),
      );
      
      if (customName == null) {
        // Cancelado
        return;
      }
      
      defaultFileName = customName;
      setState(() => _isLoading = true);
      
      // No Android, solicitar permissão e salvar em /storage/emulated/0/INFRA_EXPORT
      if (Theme.of(context).platform == TargetPlatform.android) {
        // Solicitar permissão de storage
        final hasPermission = await PermissionService.requestStoragePermission();
        if (!hasPermission) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Permissão de armazenamento negada'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        
        final exportDir = Directory('/storage/emulated/0/INFRA_EXPORT');
        
        // Criar pasta se não existir
        if (!await exportDir.exists()) {
          await exportDir.create(recursive: true);
        }
        
        filePath = '${exportDir.path}/$defaultFileName.kmz';
      } else if (Theme.of(context).platform == TargetPlatform.iOS) {
        // iOS usar Documents da app
        final directory = await getApplicationDocumentsDirectory();
        filePath = '${directory.path}/$defaultFileName.kmz';
      } else {
        // Desktop, permitir que o usuário escolha com FilePicker
        final result = await FilePicker.platform.saveFile(
          fileName: '$defaultFileName.kmz',
          type: FileType.custom,
          allowedExtensions: ['kmz'],
        );

        if (result == null) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Exportação cancelada'),
              duration: Duration(seconds: 1),
            ),
          );
          return;
        }
        filePath = result;
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      setState(() => _isLoading = true);
      
      try {
        await ExportService.exportToKMZFile(
          filePath,
          ctos: provider.ctos,
          cabos: provider.cabos,
          olts: provider.olts,
          ceos: provider.ceos,
          dios: provider.dios,
        );
        
        if (!mounted) return;
        setState(() => _isLoading = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Arquivo KMZ exportado!\nLocal: $filePath'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } catch (exportError) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro: $exportError'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        
        debugPrint('Erro ao exportar KMZ: $exportError');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      
      debugPrint('Erro ao exportar KMZ: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    }
  }

  /// Normaliza o tipo de instalação do CEO para um dos valores aceitos
  /// Maps 'Standard' e outras variações para 'Aérea'
  String _normalizeTipoInstalacao(String? tipoRaw) {
    if (tipoRaw == null || tipoRaw.isEmpty) return 'Aérea';
    
    final tipo = tipoRaw.toLowerCase().trim();
    
    // Map de valores do KML para valores aceitos pelo formulário
    const tipoMap = {
      'standard': 'Aérea',
      'padrão': 'Aérea',
      'aerea': 'Aérea',
      'aérea': 'Aérea',
      'subterranea': 'Subterrânea',
      'subterrânea': 'Subterrânea',
      'poste': 'Poste',
      'parede': 'Parede',
    };
    
    return tipoMap[tipo] ?? 'Aérea'; // Default para Aérea se não encontrar
  }
}

// Widget de diálogo para escolher nome do arquivo na exportação
class _ExportFileNameDialog extends StatefulWidget {
  final String defaultFileName;

  const _ExportFileNameDialog({
    required this.defaultFileName,
  });

  @override
  State<_ExportFileNameDialog> createState() => _ExportFileNameDialogState();
}

class _ExportFileNameDialogState extends State<_ExportFileNameDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.defaultFileName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nome do Arquivo'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'Nome do arquivo',
          hintText: 'Ex: infraestrutura_backup',
          border: OutlineInputBorder(),
          suffixText: '.kml',
          helperText: 'A extensão .kml será adicionada automaticamente',
        ),
        onSubmitted: (value) {
          Navigator.of(context).pop(value.isEmpty ? widget.defaultFileName : value);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(), // Cancelar
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final name = _controller.text.trim().isEmpty 
              ? widget.defaultFileName 
              : _controller.text.trim();
            // Remover .kml se o usuário digitou (será adicionado depois)
            final cleanName = name.replaceAll(RegExp(r'\.kml$', caseSensitive: false), '');
            Navigator.of(context).pop(cleanName);
          },
          child: const Text('Exportar'),
        ),
      ],
    );
  }
}

// Route customizada para mostrar o ImportProgressDialog sem travamento
class _ImportProgressRoute extends PageRoute<void> {
  final Widget importProgressDialog;

  _ImportProgressRoute({
    required this.importProgressDialog,
  }) : super(
    settings: const RouteSettings(name: '_ImportProgressRoute'),
  );

  @override
  Color? get barrierColor => Colors.black.withOpacity(0.3);

  @override
  bool get barrierDismissible => false;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  bool get opaque => false;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return Center(
      child: ScaleTransition(
        scale: animation.drive(Tween<double>(begin: 0.8, end: 1.0)),
        child: importProgressDialog,
      ),
    );
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }
}
