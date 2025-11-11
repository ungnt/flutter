import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/theme_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_card.dart';

class ConfiguracoesScreen extends StatefulWidget {
  const ConfiguracoesScreen({super.key});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Map<String, dynamic>> _categoriasGastos = [];
  List<Map<String, dynamic>> _tiposManutencao = [];
  List<Map<String, dynamic>> _intervalosManutencao = [];
  final _novaCategoria = TextEditingController();
  final _novoTipo = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadConfiguracoes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _novaCategoria.dispose();
    _novoTipo.dispose();
    super.dispose();
  }

  Future<void> _loadConfiguracoes() async {
    final categoriasResp = await ApiService.getCategorias();
    if (categoriasResp.success && categoriasResp.data != null) {
      _categoriasGastos = List<Map<String, dynamic>>.from(categoriasResp.data!['categorias'] ?? []);
    }

    final tiposResp = await ApiService.getTiposManutencao();
    if (tiposResp.success && tiposResp.data != null) {
      _tiposManutencao = List<Map<String, dynamic>>.from(tiposResp.data!['tipos'] ?? []);
    }

    final intervalosResp = await ApiService.getIntervalosManutencao();
    if (intervalosResp.success && intervalosResp.data != null) {
      _intervalosManutencao = List<Map<String, dynamic>>.from(intervalosResp.data!['intervalos'] ?? []);
    }

    setState(() {});
  }

  Future<void> _adicionarCategoria() async {
    if (_novaCategoria.text.isNotEmpty) {
      final response = await ApiService.createCategoria(_novaCategoria.text);
      if (response.success) {
        _novaCategoria.clear();
        await _loadConfiguracoes();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Categoria adicionada com sucesso!')),
        );
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message)),
        );
      }
    }
  }

  Future<void> _removerCategoria(String id) async {
    final response = await ApiService.deleteCategoria(id);
    if (response.success) {
      await _loadConfiguracoes();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Categoria removida com sucesso!')),
      );
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message)),
      );
    }
  }

  Future<void> _adicionarTipo() async {
    if (_novoTipo.text.isNotEmpty) {
      final response = await ApiService.createTipoManutencao(_novoTipo.text);
      if (response.success) {
        await ApiService.updateIntervaloManutencao(_novoTipo.text, 5000);
        _novoTipo.clear();
        await _loadConfiguracoes();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tipo de manutenção adicionado com sucesso!')),
        );
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message)),
        );
      }
    }
  }

  Future<void> _removerTipo(String id) async {
    final response = await ApiService.deleteTipoManutencao(id);
    if (response.success) {
      await _loadConfiguracoes();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tipo removido com sucesso!')),
      );
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message)),
      );
    }
  }

  Future<void> _editarIntervaloManutencao(String tipo, int intervaloAtual) async {
    final TextEditingController controller = TextEditingController(text: intervaloAtual.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar Intervalo - $tipo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Defina o intervalo em quilômetros para $tipo:'),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Intervalo (km)',
                border: OutlineInputBorder(),
                suffixText: 'km',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final novoIntervalo = int.tryParse(controller.text);
              if (novoIntervalo != null && novoIntervalo > 0) {
                final response = await ApiService.updateIntervaloManutencao(tipo, novoIntervalo);
                if (response.success) {
                  await _loadConfiguracoes();
                  Navigator.pop(context);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Intervalo de $tipo atualizado para $novoIntervalo km')),
                  );
                } else {
                  Navigator.pop(context);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(response.message)),
                  );
                }
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  // Função _exportarDados removida - não utilizada
  // Função _shareModernBackup removida - não utilizada
  // Função _restoreBackup removida - não utilizada

  void _showTechInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🚀 Tecnologia'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Framework: Flutter 3.24+'),
            Text('Linguagem: Dart'),
            Text('Banco: SQLite local'),
            Text('Gráficos: FL Chart'),
            Text('Estilo: Material Design 3'),
            Text('Tema: Grau 244 - Visual jovem motociclista'),
            SizedBox(height: 16),
            Text('Características:'),
            Text('• 100% offline'),
            Text('• Dados locais seguros'),
            Text('• Interface nativa'),
            Text('• Performance otimizada'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshData() async {
    try {
      await _loadConfiguracoes();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🔄 Dados atualizados com sucesso!')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Erro ao atualizar dados: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚙️ Configurações'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Geral'),
            Tab(text: 'Categorias'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGeralTab(),
          _buildCategoriasTab(),
        ],
      ),
    );
  }

  Widget _buildGeralTab() {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Seção Aparência
              const Text(
                '🎨 Aparência',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              ModernCard(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        themeService.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                        color: AppTheme.primaryColor,
                      ),
                      title: const Text('Modo Escuro'),
                      subtitle: Text(
                        themeService.themeMode == ThemeMode.system
                            ? 'Automático (segue o sistema)'
                            : themeService.isDarkMode
                                ? 'Ativado'
                                : 'Desativado',
                      ),
                      trailing: Switch.adaptive(
                        value: themeService.themeMode == ThemeMode.dark ||
                            (themeService.themeMode == ThemeMode.system &&
                                MediaQuery.of(context).platformBrightness ==
                                    Brightness.dark),
                        onChanged: (value) {
                          themeService.setThemeMode(
                            value ? ThemeMode.dark : ThemeMode.light,
                          );
                        },
                        activeColor: AppTheme.primaryColor,
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(
                        Icons.auto_mode,
                        color: AppTheme.secondaryColor,
                      ),
                      title: const Text('Modo Automático'),
                      subtitle: const Text('Segue as configurações do sistema'),
                      trailing: Switch.adaptive(
                        value: themeService.themeMode == ThemeMode.system,
                        onChanged: (value) {
                          themeService.setThemeMode(
                            value ? ThemeMode.system : ThemeMode.light,
                          );
                        },
                        activeColor: AppTheme.secondaryColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Seção App Info
              const Text(
                'ℹ️ Informações do App',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              ModernCard(
                child: Column(
                  children: [
                    const ListTile(
                      leading: Icon(Icons.info, color: AppTheme.primaryColor),
                      title: Text('Versão'),
                      subtitle: Text('2.0.0 - Estética Grau 244'),
                    ),
                    const Divider(height: 1),
                    const ListTile(
                      leading: Icon(Icons.motorcycle, color: AppTheme.accentColor),
                      title: Text('Motouber'),
                      subtitle: Text('Controle financeiro para motociclistas'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.code, color: AppTheme.secondaryColor),
                      title: const Text('Tecnologia'),
                      subtitle: const Text('Flutter/Dart + SQLite'),
                      onTap: () => _showTechInfo(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Seção Performance
              const Text(
                '⚡ Performance',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              ModernCard(
                child: ListTile(
                  leading: const Icon(Icons.refresh, color: AppTheme.primaryColor),
                  title: const Text('Recarregar Dados'),
                  subtitle: const Text('Atualiza informações do banco'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _refreshData(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoriasTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Categorias de Gastos
          const Text(
            'Categorias de Gastos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _novaCategoria,
                  decoration: const InputDecoration(
                    labelText: 'Nova categoria',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _adicionarCategoria,
                child: const Text('Adicionar'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categoriasGastos.map((categoria) {
              return Chip(
                label: Text(categoria['nome'] ?? ''),
                onDeleted: () => _removerCategoria(categoria['id'].toString()),
                backgroundColor: AppTheme.primaryColor.withAlpha((255 * 0.1).toInt()),
              );
            }).toList(),
          ),

          const SizedBox(height: 32),

          // Tipos de Manutenção
          const Text(
            'Tipos de Manutenção',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _novoTipo,
                  decoration: const InputDecoration(
                    labelText: 'Novo tipo',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _adicionarTipo,
                child: const Text('Adicionar'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tiposManutencao.map((tipo) {
              return Chip(
                label: Text(tipo['nome'] ?? ''),
                onDeleted: () => _removerTipo(tipo['id'].toString()),
                backgroundColor: AppTheme.warningColor.withAlpha((255 * 0.1).toInt()),
              );
            }).toList(),
          ),

          const SizedBox(height: 32),

          // Intervalos de Manutenção Personalizáveis
          const Text(
            'Intervalos de Manutenção (km)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          if (_intervalosManutencao.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Carregando intervalos de manutenção...',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            Column(
              children: _intervalosManutencao.map((intervalo) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.settings, color: AppTheme.primaryColor),
                    title: Text(intervalo['tipo'] ?? ''),
                    subtitle: Text('Intervalo: ${intervalo['intervalo']} km'),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: AppTheme.secondaryColor),
                      onPressed: () => _editarIntervaloManutencao(
                        intervalo['tipo'] ?? '',
                        intervalo['intervalo'] ?? 5000,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildBackupTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⚙️ Gerenciamento de Dados',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Limpar Dados',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Atenção: Esta ação removerá todos os dados permanentemente!',
                    style: TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showClearDataDialog,
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('Limpar Todos os Dados'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Função _buildSobreTab removida - não utilizada

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text('ATENÇÃO'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Esta ação irá:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Apagar TODOS os dados locais (trabalhos, gastos, manutenções)'),
            Text('• Fazer logout da sua conta'),
            Text('• Retornar à tela de login'),
            SizedBox(height: 16),
            Text(
              'Esta ação NÃO pode ser desfeita!',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Deseja realmente continuar?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _clearAllData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('SIM, LIMPAR TUDO'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllData() async {
    try {
      await AuthService.logout();
      
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Todos os dados foram removidos!'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erro ao limpar dados: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}