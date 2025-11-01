import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart';
import '../models/cto_model.dart';
import '../models/olt_model.dart';
import '../models/ceo_model.dart';
import '../models/dio_model.dart';
import '../models/cabo_model.dart';

/// Resultado da comparação entre elementos
class ComparisonResult {
  final bool isDuplicate;
  final bool needsUpdate;
  final String reason;

  ComparisonResult({
    required this.isDuplicate,
    required this.needsUpdate,
    required this.reason,
  });
}

/// Serviço para importação inteligente com detecção de duplicados
class SmartImportService {
  /// Threshold em metros para considerar mesma localização
  static const double locationThreshold = 5.0;

  /// Compara dois pontos de localização
  static double getDistanceInMeters(LatLng p1, LatLng p2) {
    final distance = Distance();
    return distance.as(LengthUnit.Meter, p1, p2);
  }

  /// Verifica se duas CTOs são iguais ou precisam atualizar
  static ComparisonResult compareCTOs(CTOModel existing, CTOModel newItem) {
    final locationDist = getDistanceInMeters(existing.posicao, newItem.posicao);
    
    // Mesma localização e tipo (CTO)
    if (locationDist <= locationThreshold) {
      // Verificar se tem dados iguais
      if (existing.nome == newItem.nome &&
          existing.numeroPortas == newItem.numeroPortas &&
          existing.tipoSplitter == newItem.tipoSplitter) {
        
        // Mesma CTO: comparar timestamp
        final existingTimestamp = existing.dataAtualizacao ?? existing.dataCriacao;
        final newTimestamp = newItem.dataAtualizacao ?? newItem.dataCriacao;
        
        if (newTimestamp.isAfter(existingTimestamp)) {
          return ComparisonResult(
            isDuplicate: false,
            needsUpdate: true,
            reason: 'CTO importada é mais recente (${newTimestamp.toIso8601String()})',
          );
        }
        
        return ComparisonResult(
          isDuplicate: true,
          needsUpdate: false,
          reason: 'CTO local é mais recente (${existingTimestamp.toIso8601String()})',
        );
      } else {
        // Dados diferentes = atualização
        return ComparisonResult(
          isDuplicate: false,
          needsUpdate: true,
          reason: 'CTO na mesma localização com informações diferentes',
        );
      }
    }
    
    // Se está longe mas tem o mesmo nome: NÃO é duplicata, é uma CTO diferente
    // (permite múltiplas CTOs com mesmo nome em locais diferentes)
    
    return ComparisonResult(
      isDuplicate: false,
      needsUpdate: false,
      reason: 'CTO é nova',
    );
  }

  /// Verifica se duas OLTs são iguais ou precisam atualizar
  static ComparisonResult compareOLTs(OLTModel existing, OLTModel newItem) {
    final locationDist = getDistanceInMeters(existing.posicao, newItem.posicao);
    
    // Mesma localização E mesmo nome = possível duplicata
    if (locationDist <= locationThreshold && existing.nome == newItem.nome) {
      if (existing.numeroSlots == newItem.numeroSlots) {
        
        // Mesma OLT: comparar timestamp
        final existingTimestamp = existing.dataAtualizacao ?? existing.dataCriacao;
        final newTimestamp = newItem.dataAtualizacao ?? newItem.dataCriacao;
        
        if (newTimestamp.isAfter(existingTimestamp)) {
          return ComparisonResult(
            isDuplicate: false,
            needsUpdate: true,
            reason: 'OLT importada é mais recente (${newTimestamp.toIso8601String()})',
          );
        }
        
        return ComparisonResult(
          isDuplicate: true,
          needsUpdate: false,
          reason: 'OLT local é mais recente (${existingTimestamp.toIso8601String()})',
        );
      } else {
        return ComparisonResult(
          isDuplicate: false,
          needsUpdate: true,
          reason: 'OLT na mesma localização com informações diferentes',
        );
      }
    }
    
    // Se está longe mas tem o mesmo nome: NÃO é duplicata, é uma OLT diferente
    
    return ComparisonResult(
      isDuplicate: false,
      needsUpdate: false,
      reason: 'OLT é nova',
    );
  }

  /// Verifica se duas CEOs são iguais ou precisam atualizar
  /// Usa timestamp para decidir qual versão manter em caso de conflito
  static ComparisonResult compareCEOs(CEOModel existing, CEOModel newItem) {
    final locationDist = getDistanceInMeters(existing.posicao, newItem.posicao);
    
    // Apenas duplicata se: mesma localização E mesmo nome
    if (locationDist <= locationThreshold && existing.nome == newItem.nome) {
      if (existing.capacidadeFusoes == newItem.capacidadeFusoes) {
        
        // Mesma CEO: comparar timestamp
        final existingTimestamp = existing.dataAtualizacao ?? existing.dataCriacao;
        final newTimestamp = newItem.dataAtualizacao ?? newItem.dataCriacao;
        
        if (newTimestamp.isAfter(existingTimestamp)) {
          return ComparisonResult(
            isDuplicate: false,
            needsUpdate: true,
            reason: 'CEO importada é mais recente (${newTimestamp.toIso8601String()})',
          );
        } else {
          return ComparisonResult(
            isDuplicate: true,
            needsUpdate: false,
            reason: 'CEO local é mais recente (${existingTimestamp.toIso8601String()})',
          );
        }
      } else {
        // Mesma localização e nome, mas capacidade diferente: atualizar
        return ComparisonResult(
          isDuplicate: false,
          needsUpdate: true,
          reason: 'CEO na mesma localização com capacidade diferente',
        );
      }
    }
    
    // Se está longe mas tem o mesmo nome: NÃO é duplicata, é uma CEO diferente
    // (permite múltiplas CEOs com mesmo nome em locais diferentes)
    
    return ComparisonResult(
      isDuplicate: false,
      needsUpdate: false,
      reason: 'CEO é nova',
    );
  }

  /// Verifica se duas DIOs são iguais ou precisam atualizar
  static ComparisonResult compareDIOs(DIOModel existing, DIOModel newItem) {
    final locationDist = getDistanceInMeters(existing.posicao, newItem.posicao);
    
    // Mesma localização E mesmo nome = possível duplicata
    if (locationDist <= locationThreshold && existing.nome == newItem.nome) {
      if (existing.numeroPortas == newItem.numeroPortas) {
        
        // Mesma DIO: comparar timestamp
        final existingTimestamp = existing.dataAtualizacao ?? existing.dataCriacao;
        final newTimestamp = newItem.dataAtualizacao ?? newItem.dataCriacao;
        
        if (newTimestamp.isAfter(existingTimestamp)) {
          return ComparisonResult(
            isDuplicate: false,
            needsUpdate: true,
            reason: 'DIO importada é mais recente (${newTimestamp.toIso8601String()})',
          );
        }
        
        return ComparisonResult(
          isDuplicate: true,
          needsUpdate: false,
          reason: 'DIO local é mais recente (${existingTimestamp.toIso8601String()})',
        );
      } else {
        return ComparisonResult(
          isDuplicate: false,
          needsUpdate: true,
          reason: 'DIO na mesma localização com informações diferentes',
        );
      }
    }
    
    // Se está longe mas tem o mesmo nome: NÃO é duplicata, é uma DIO diferente
    
    return ComparisonResult(
      isDuplicate: false,
      needsUpdate: false,
      reason: 'DIO é nova',
    );
  }

  /// Verifica se dois Cabos são iguais ou precisam atualizar
  static ComparisonResult compareCabos(CaboModel existing, CaboModel newItem) {
    // Cabos: comparar nome E rota
    if (existing.nome == newItem.nome) {
      // Verificar se rota é idêntica
      if (existing.rota.length == newItem.rota.length) {
        bool rotaIgual = true;
        for (int i = 0; i < existing.rota.length; i++) {
          if (getDistanceInMeters(existing.rota[i], newItem.rota[i]) > locationThreshold) {
            rotaIgual = false;
            break;
          }
        }
        
        // Mesma rota = mesma localização = verificar atualização
        if (rotaIgual) {
          if (existing.configuracao.totalFibras == newItem.configuracao.totalFibras) {
            // Totalmente idêntico
            final existingTimestamp = existing.dataAtualizacao ?? existing.dataCriacao;
            final newTimestamp = newItem.dataAtualizacao ?? newItem.dataCriacao;
            
            if (newTimestamp.isAfter(existingTimestamp)) {
              return ComparisonResult(
                isDuplicate: false,
                needsUpdate: true,
                reason: 'Cabo importado é mais recente',
              );
            }
            
            return ComparisonResult(
              isDuplicate: true,
              needsUpdate: false,
              reason: 'Cabo idêntico já existe',
            );
          } else {
            // Mesma rota mas fibras diferentes = atualizar
            return ComparisonResult(
              isDuplicate: false,
              needsUpdate: true,
              reason: 'Cabo mesma rota mas configuração diferente',
            );
          }
        }
      }
      
      // Mesmo nome mas rota diferente = diferentes, não é duplicata
      return ComparisonResult(
        isDuplicate: false,
        needsUpdate: false,
        reason: 'Cabo novo (mesmo nome, rota diferente)',
      );
    }
    
    return ComparisonResult(
      isDuplicate: false,
      needsUpdate: false,
      reason: 'Cabo é novo',
    );
  }

  /// Remove keys duplicadas da descrição
  /// Se as keys aparecerem múltiplas vezes, mantém apenas a primeira ocorrência
  static String? limparKeysDuplicadas(String? descricao) {
    if (descricao == null || descricao.isEmpty) return descricao;

    final lines = descricao.split('\n');
    final result = <String>[];
    final keysVistos = <String>{};
    bool emSecaoKeys = false;

    for (final line in lines) {
      if (line.trim() == '--- KEYS ---') {
        if (emSecaoKeys) {
          // Já temos uma seção de keys, pula esta duplicada
          continue;
        }
        emSecaoKeys = true;
        result.add(line);
        continue;
      }

      if (emSecaoKeys) {
        // Estamos em seção de keys
        if (line.contains(':') && !line.startsWith(' ') && line.trim().isNotEmpty) {
          // É uma key
          final keyName = line.split(':')[0].trim();
          if (keysVistos.contains(keyName)) {
            // Key duplicada, pula
            continue;
          }
          keysVistos.add(keyName);
        } else if (line.trim().isEmpty || line.startsWith(' ')) {
          // Linha vazia ou indentada, continua
        } else {
          // Fim da seção de keys
          emSecaoKeys = false;
        }
      }

      result.add(line);
    }

    return result.join('\n');
  }

  /// Parseia fusões a partir das KEYS de CEO
  /// Formato esperado:
  /// FUSAO_1: caboEntrada:fibraEntrada:caboSaida:fibraSaida:atenuacao:tecnico:obs
  /// FUSAO_2: ...
  static List<FusaoCEO> parseusoesDasKeys(Map<String, String> keys) {
    final fusoes = <FusaoCEO>[];
    
    try {
      debugPrint('🔎 Buscando FUSAO_1, FUSAO_2, etc nas keys...');
      int fusaoNum = 1;
      while (keys.containsKey('FUSAO_$fusaoNum')) {
        final fusaoStr = keys['FUSAO_$fusaoNum']!;
        debugPrint('✅ Encontrada FUSAO_$fusaoNum: $fusaoStr');
        final partes = fusaoStr.split(':');
        
        if (partes.length >= 4) {
          final caboEntradaId = partes[0];
          final fibraEntradaStr = partes[1];
          final caboSaidaId = partes[2];
          final fibraSaidaStr = partes[3];
          
          final fibraEntrada = int.tryParse(fibraEntradaStr);
          final fibraSaida = int.tryParse(fibraSaidaStr);
          
          if (fibraEntrada != null && fibraSaida != null) {
            final atenuacao = partes.length > 4 && partes[4].isNotEmpty 
              ? double.tryParse(partes[4]) 
              : null;
            
            final tecnico = partes.length > 5 && partes[5].isNotEmpty 
              ? partes[5] 
              : null;
            
            final observacao = partes.length > 6 && partes[6].isNotEmpty 
              ? partes[6] 
              : null;
            
            fusoes.add(FusaoCEO(
              id: '',
              caboEntradaId: caboEntradaId,
              fibraEntradaNumero: fibraEntrada,
              caboSaidaId: caboSaidaId,
              fibraSaidaNumero: fibraSaida,
              atenuacao: atenuacao,
              tecnico: tecnico,
              observacao: observacao,
            ));
            debugPrint('   📌 Fusão adicionada: $caboEntradaId:$fibraEntrada → $caboSaidaId:$fibraSaida');
          }
        }
        
        fusaoNum++;
      }
      debugPrint('🔎 Total de fusões encontradas: ${fusoes.length}');
    } catch (e) {
      debugPrint('❌ Erro ao parsear fusões das keys: $e');
    }
    
    return fusoes;
  }

  /// DEPRECADO: Parseia fusões a partir da descrição de CEO
  /// Mantido para compatibilidade com arquivos antigos
  /// Formato esperado:
  /// === FUSÕES (n) ===
  /// Fusão 1:
  ///   Entrada: Fibra X (Cabo: cabo-id)
  ///   Saída: Fibra Y (Cabo: cabo-id)
  ///   Atenuação: XX.XX dB
  ///   Técnico: Nome
  ///   Obs: Observação
  ///   Data: data/hora
  static List<FusaoCEO> parseusoesDaDescricao(String descricao) {
    final fusoes = <FusaoCEO>[];
    
    if (!descricao.contains('=== FUSÕES')) {
      return fusoes;
    }

    try {
      final lines = descricao.split('\n');
      int i = 0;
      
      // Encontrar início da seção de fusões
      while (i < lines.length && !lines[i].contains('=== FUSÕES')) {
        i++;
      }
      
      if (i >= lines.length) {
        return fusoes;
      }
      
      i++; // Pular a linha "=== FUSÕES"
      
      // Parsear cada fusão
      while (i < lines.length) {
        final line = lines[i].trim();
        
        if (line.startsWith('Fusão')) {
          // Início de uma nova fusão
          String? caboEntradaId;
          int? fibraEntradaNumero;
          String? caboSaidaId;
          int? fibraSaidaNumero;
          double? atenuacao;
          String? tecnico;
          String? observacao;
          
          i++;
          
          // Ler propriedades da fusão
          while (i < lines.length) {
            final propLine = lines[i].trim();
            
            if (propLine.isEmpty || propLine.startsWith('Fusão')) {
              // Fim desta fusão
              break;
            }
            
            if (propLine.startsWith('Entrada:')) {
              // Formato: Entrada: Fibra X (Cabo: cabo-id)
              final match = RegExp(r'Entrada: Fibra (\d+) \(Cabo: ([^)]+)\)')
                  .firstMatch(propLine);
              if (match != null) {
                fibraEntradaNumero = int.tryParse(match.group(1) ?? '');
                caboEntradaId = match.group(2);
              }
            } else if (propLine.startsWith('Saída:')) {
              // Formato: Saída: Fibra X (Cabo: cabo-id)
              final match = RegExp(r'Saída: Fibra (\d+) \(Cabo: ([^)]+)\)')
                  .firstMatch(propLine);
              if (match != null) {
                fibraSaidaNumero = int.tryParse(match.group(1) ?? '');
                caboSaidaId = match.group(2);
              }
            } else if (propLine.startsWith('Atenuação:')) {
              // Formato: Atenuação: XX.XX dB
              final match = RegExp(r'Atenuação: ([\d.]+)\s*dB')
                  .firstMatch(propLine);
              if (match != null) {
                atenuacao = double.tryParse(match.group(1) ?? '');
              }
            } else if (propLine.startsWith('Técnico:')) {
              tecnico = propLine.replaceFirst('Técnico:', '').trim();
            } else if (propLine.startsWith('Obs:')) {
              observacao = propLine.replaceFirst('Obs:', '').trim();
            }
            
            i++;
          }
          
          // Criar fusão se tem dados mínimos
          if (caboEntradaId != null &&
              fibraEntradaNumero != null &&
              caboSaidaId != null &&
              fibraSaidaNumero != null) {
            fusoes.add(FusaoCEO(
              id: '', // Será gerado pelo provider
              caboEntradaId: caboEntradaId,
              fibraEntradaNumero: fibraEntradaNumero,
              caboSaidaId: caboSaidaId,
              fibraSaidaNumero: fibraSaidaNumero,
              atenuacao: atenuacao,
              tecnico: tecnico,
              observacao: observacao,
            ));
          }
          
          continue;
        }
        
        i++;
      }
    } catch (e) {
      debugPrint('Erro ao parsear fusões da descrição: $e');
    }
    
    return fusoes;
  }

  /// Extrai o timestamp de exportação das KEYS
  /// Retorna null se não encontrar timestamp válido
  static DateTime? extractTimestampFromKeys(Map<String, String> keys) {
    try {
      final timestampStr = keys['TIMESTAMP'];
      if (timestampStr != null && timestampStr.isNotEmpty) {
        return DateTime.parse(timestampStr);
      }
    } catch (e) {
      debugPrint('❌ Erro ao extrair timestamp das keys: $e');
    }
    return null;
  }
}


