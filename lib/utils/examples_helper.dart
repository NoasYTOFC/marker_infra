import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../models/cto_model.dart';
import '../models/cabo_model.dart';
import '../models/olt_model.dart';
import '../models/ceo_model.dart';
import '../models/dio_model.dart';
import '../providers/infrastructure_provider.dart';

/// Exemplos de como criar elementos programaticamente
class ExamplesHelper {
  static const uuid = Uuid();

  /// Cria uma CTO de exemplo
  static CTOModel createExampleCTO() {
    return CTOModel(
      id: uuid.v4(),
      nome: 'CTO-001',
      posicao: LatLng(-23.5505, -46.6333),
      descricao: 'CTO principal próxima ao poste 123',
      numeroPortas: 16,
      tipoSplitter: '1:16',
      numeroCTO: 'CTO-001',
      portas: List.generate(
        16,
        (i) => PortaCTO(
          numero: i + 1,
        ),
      ),
    );
  }

  /// Cria um cabo de exemplo
  static CaboModel createExampleCabo() {
    return CaboModel(
      id: uuid.v4(),
      nome: 'CABO-FO-24F-001',
      rota: [
        LatLng(-23.5505, -46.6333),
        LatLng(-23.5515, -46.6343),
        LatLng(-23.5525, -46.6353),
      ],
      descricao: 'Cabo principal da rua A',
      configuracao: ConfiguracaoCabo.fo24,
      tipoInstalacao: 'Aéreo',
      metragem: 150.0,
    );
  }

  /// Cria uma OLT de exemplo
  static OLTModel createExampleOLT() {
    return OLTModel(
      id: uuid.v4(),
      nome: 'OLT-CENTRAL-01',
      posicao: LatLng(-23.5500, -46.6320),
      descricao: 'OLT principal - Central',
      ipAddress: '192.168.1.1',
      numeroSlots: 4,
      fabricante: 'ZTE',
      modelo: 'C300',
      slots: List.generate(
        4,
        (i) => SlotOLT(
          numero: i + 1,
          numeroPONs: 16,
          modelo: 'GTGH',
          ativo: true,
        ),
      ),
    );
  }

  /// Cria uma CEO de exemplo
  static CEOModel createExampleCEO() {
    return CEOModel(
      id: uuid.v4(),
      nome: 'CEO-01',
      posicao: LatLng(-23.5510, -46.6340),
      descricao: 'CEO de emenda no poste 456',
      capacidadeFusoes: 24,
      tipo: 'Aérea',
      numeroCEO: 'CEO-01',
    );
  }

  /// Cria um DIO de exemplo
  static DIOModel createExampleDIO() {
    return DIOModel(
      id: uuid.v4(),
      nome: 'DIO-POP-01',
      posicao: LatLng(-23.5495, -46.6315),
      descricao: 'DIO principal no POP',
      numeroPortas: 48,
      tipo: 'Rack',
      numeroDIO: 'DIO-POP-01',
    );
  }

  /// Adiciona dados de exemplo ao provider
  static void addExampleData(InfrastructureProvider provider) {
    // Adiciona OLT
    final olt = createExampleOLT();
    provider.addOLT(olt);

    // Adiciona DIO
    final dio = createExampleDIO();
    provider.addDIO(dio);

    // Adiciona CEO
    final ceo = createExampleCEO();
    provider.addCEO(ceo);

    // Adiciona cabo principal
    final caboMain = createExampleCabo();
    provider.addCabo(caboMain);

    // Adiciona várias CTOs ao longo da rota
    for (int i = 0; i < 5; i++) {
      final cto = CTOModel(
        id: uuid.v4(),
        nome: 'CTO-${(i + 1).toString().padLeft(3, '0')}',
        posicao: LatLng(-23.5505 + (i * 0.001), -46.6333 + (i * 0.001)),
        descricao: 'CTO ${i + 1} da rede',
        numeroPortas: 16,
        tipoSplitter: '1:16',
        numeroCTO: 'CTO-${(i + 1).toString().padLeft(3, '0')}',
      );
      provider.addCTO(cto);
    }

    // Adiciona cabos secundários
    for (int i = 0; i < 3; i++) {
      final cabo = CaboModel(
        id: uuid.v4(),
        nome: 'CABO-SEC-${i + 1}',
        rota: [
          LatLng(-23.5505 + (i * 0.001), -46.6333 + (i * 0.001)),
          LatLng(-23.5505 + (i * 0.001) + 0.002, -46.6333 + (i * 0.001) + 0.002),
        ],
        configuracao: ConfiguracaoCabo.fo12,
        tipoInstalacao: 'Aéreo',
      );
      provider.addCabo(cabo);
    }
  }

  /// Demonstra como fazer fusões em uma CEO
  static void demonstrateFusion(CEOModel ceo, CaboModel caboEntrada, CaboModel caboSaida) {
    final fusao = FusaoCEO(
      id: uuid.v4(),
      caboEntradaId: caboEntrada.id,
      fibraEntradaNumero: 1,
      caboSaidaId: caboSaida.id,
      fibraSaidaNumero: 1,
      atenuacao: 0.05, // 0.05 dB
      tecnico: 'João Silva',
      observacao: 'Fusão realizada com sucesso',
    );

    // Adicionar fusão à CEO
    final ceoAtualizada = ceo.copyWith(
      fusoes: [...ceo.fusoes, fusao],
    );

    debugPrint('Fusão criada: ${fusao.id}');
    debugPrint('Atenuação: ${fusao.atenuacao} dB');
    debugPrint('CEO atualizada: ${ceoAtualizada.nome}');
  }

  /// Demonstra como conectar uma fibra a um cliente
  static void connectClientToCTO(CTOModel cto, int portaNumero, String clienteId) {
    final portas = List<PortaCTO>.from(cto.portas);
    final portaIndex = portas.indexWhere((p) => p.numero == portaNumero);

    if (portaIndex != -1) {
      portas[portaIndex] = PortaCTO(
        numero: portaNumero,
        observacao: 'Cliente conectado em ${DateTime.now()}',
      );

      final ctoAtualizada = cto.copyWith(portas: portas);
      debugPrint('Cliente $clienteId conectado na porta $portaNumero da CTO ${ctoAtualizada.nome}');
    }
  }

  /// Demonstra como configurar um PON na OLT
  static void configurePON(OLTModel olt, int slotNumero, int ponNumero, String ctoId, int vlan) {
    final slots = List<SlotOLT>.from(olt.slots);
    final slotIndex = slots.indexWhere((s) => s.numero == slotNumero);

    if (slotIndex != -1) {
      final slot = slots[slotIndex];
      final pons = List<PONOLT>.from(slot.pons);
      final ponIndex = pons.indexWhere((p) => p.numero == ponNumero);

      if (ponIndex != -1) {
        pons[ponIndex] = pons[ponIndex].copyWith(
          emUso: true,
          ctoId: ctoId,
          vlan: vlan,
          potenciaRx: '-22.5 dBm',
        );

        slots[slotIndex] = SlotOLT(
          numero: slot.numero,
          numeroPONs: slot.numeroPONs,
          pons: pons,
          modelo: slot.modelo,
          ativo: slot.ativo,
        );

        debugPrint('PON configurado: Slot $slotNumero, PON $ponNumero, VLAN $vlan');
      }
    }
  }
}
