/// Constantes para categorias pré-definidas de gastos
class GastosCategories {
  static const List<String> categorias = [
    'Combustível',
    'Manutenção',
    'Multas/IPVA',
    'Alimentação',
    'Equipamentos',
    'Documentação',
    'Pedágio',
    'Estacionamento',
    'Lavagem',
    'Outros',
  ];

  static const Map<String, String> icons = {
    'Combustível': '⛽',
    'Manutenção': '🔧',
    'Multas/IPVA': '📋',
    'Alimentação': '🍕',
    'Equipamentos': '📱',
    'Documentação': '📄',
    'Pedágio': '🛣️',
    'Estacionamento': '🅿️',
    'Lavagem': '🧽',
    'Outros': '📦',
  };

  static String getIcon(String categoria) {
    return icons[categoria] ?? '📦';
  }
}