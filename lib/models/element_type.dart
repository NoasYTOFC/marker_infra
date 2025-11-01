/// Tipos de elementos de infraestrutura de rede
enum ElementType {
  cto('CTO', 'Caixa de Terminação Óptica'),
  olt('OLT', 'Optical Line Terminal'),
  ceo('CEO', 'Caixa de Emenda Óptica'),
  dio('DIO', 'Distribuidor Interno Óptico'),
  cabo('CABO', 'Cabo de Fibra Óptica'),
  fusao('FUSAO', 'Ponto de Fusão'),
  poste('POSTE', 'Poste'),
  cliente('CLIENTE', 'Cliente/Assinante');

  final String key;
  final String description;

  const ElementType(this.key, this.description);

  static ElementType? fromKey(String key) {
    try {
      return ElementType.values.firstWhere(
        (e) => e.key.toLowerCase() == key.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }
}
