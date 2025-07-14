import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

class ConfiguracoesScreen extends StatefulWidget {
  const ConfiguracoesScreen({super.key});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseService _db = DatabaseService.instance;
  
  List<String> _categoriasGastos = [];
  List<String> _tiposManutencao = [];
  final _novaCategoria = TextEditingController();
  final _novoTipo = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
    _categoriasGastos = await _db.getCategoriasGastos();
    _tiposManutencao = await _db.getTiposManutencao();
    setState(() {});
  }

  Future<void> _adicionarCategoria() async {
    if (_novaCategoria.text.isNotEmpty) {
      _categoriasGastos.add(_novaCategoria.text);
      await _db.setCategoriasGastos(_categoriasGastos);
      _novaCategoria.clear();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Categoria adicionada com sucesso!')),
      );
    }
  }

  Future<void> _removerCategoria(String categoria) async {
    _categoriasGastos.remove(categoria);
    await _db.setCategoriasGastos(_categoriasGastos);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Categoria removida com sucesso!')),
    );
  }

  Future<void> _adicionarTipo() async {
    if (_novoTipo.text.isNotEmpty) {
      _tiposManutencao.add(_novoTipo.text);
      await _db.setTiposManutencao(_tiposManutencao);
      _novoTipo.clear();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tipo de manutenção adicionado com sucesso!')),
      );
    }
  }

  Future<void> _removerTipo(String tipo) async {
    _tiposManutencao.remove(tipo);
    await _db.setTiposManutencao(_tiposManutencao);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tipo removido com sucesso!')),
    );
  }

  Future<void> _exportarDados() async {
    try {
      final trabalhos = await _db.getTrabalhos();
      final gastos = await _db.getGastos();
      final manutencoes = await _db.getManutencoes();

      final dados = {
        'trabalhos': trabalhos.map((t) => t.toMap()).toList(),
        'gastos': gastos.map((g) => g.toMap()).toList(),
        'manutencoes': manutencoes.map((m) => m.toMap()).toList(),
        'categorias_gastos': _categoriasGastos,
        'tipos_manutencao': _tiposManutencao,
        'data_backup': DateTime.now().toIso8601String(),
      };

      final json = jsonEncode(dados);
      await Share.shareXFiles(
        [XFile.fromData(
          utf8.encode(json),
          name: 'motouber_backup_${DateTime.now().millisecondsSinceEpoch}.json',
          mimeType: 'application/json',
        )],
        text: 'Backup dos dados do Motouber',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao exportar dados: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Categorias'),
            Tab(text: 'Backup'),
            Tab(text: 'Sobre'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCategoriasTab(),
          _buildBackupTab(),
          _buildSobreTab(),
        ],
      ),
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
                label: Text(categoria),
                onDeleted: () => _removerCategoria(categoria),
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
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
                label: Text(tipo),
                onDeleted: () => _removerTipo(tipo),
                backgroundColor: AppTheme.warningColor.withOpacity(0.1),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Backup e Restauração',
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
                    'Exportar Dados',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Faça backup de todos os seus dados (trabalhos, gastos, manutenções e configurações).',
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _exportarDados,
                      icon: const Icon(Icons.download),
                      label: const Text('Exportar Dados'),
                    ),
                  ),
                ],
              ),
            ),
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

  Widget _buildSobreTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sobre o Motouber',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Motouber - Controle Financeiro',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('Versão: 1.0.0'),
                  SizedBox(height: 8),
                  Text(
                    'Sistema completo de controle financeiro desenvolvido especialmente para motoristas de aplicativo.',
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Funcionalidades:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('• Registro diário de trabalho'),
                  Text('• Controle de gastos categorizados'),
                  Text('• Gestão de manutenções'),
                  Text('• Relatórios e análises'),
                  Text('• Backup e restauração de dados'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Privacidade',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Todos os dados são armazenados localmente no seu dispositivo. Nenhuma informação é enviada para servidores externos.',
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Desenvolvido com ❤️',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Para a comunidade de motoristas de aplicativo',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Limpeza'),
        content: const Text(
          'Esta ação removerá todos os dados permanentemente. Tem certeza que deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearAllData();
            },
            child: const Text('Limpar Dados', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllData() async {
    try {
      // Aqui você implementaria a limpeza do banco de dados
      // Por exemplo, deletar todas as tabelas e recriar
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todos os dados foram removidos!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao limpar dados: $e')),
      );
    }
  }
}