import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/manutencao_model.dart';
import '../theme/app_theme.dart';

class ManutencoesScreen extends StatefulWidget {
  const ManutencoesScreen({super.key});

  @override
  State<ManutencoesScreen> createState() => _ManutencoesScreenState();
}

class _ManutencoesScreenState extends State<ManutencoesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseService _db = DatabaseService.instance;
  final _formKey = GlobalKey<FormState>();
  
  final _valorController = TextEditingController();
  final _kmController = TextEditingController();
  final _descricaoController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  String _selectedTipo = '';
  List<String> _tiposManutencao = [];
  List<ManutencaoModel> _manutencoes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTipos();
    _loadManutencoes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _valorController.dispose();
    _kmController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _loadTipos() async {
    _tiposManutencao = await _db.getTiposManutencao();
    if (_tiposManutencao.isNotEmpty) {
      _selectedTipo = _tiposManutencao.first;
    }
    setState(() {});
  }

  Future<void> _loadManutencoes() async {
    setState(() => _isLoading = true);
    _manutencoes = await _db.getManutencoes();
    setState(() => _isLoading = false);
  }

  Future<void> _saveManutencao() async {
    if (_formKey.currentState!.validate()) {
      final manutencao = ManutencaoModel(
        data: _selectedDate,
        tipo: _selectedTipo,
        valor: double.parse(_valorController.text),
        kmAtual: double.parse(_kmController.text),
        descricao: _descricaoController.text,
        dataRegistro: DateTime.now(),
      );

      await _db.insertManutencao(manutencao);
      
      _clearForm();
      _loadManutencoes();
      
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Manutenção salva com sucesso!')),
      );
    }
  }

  void _clearForm() {
    _valorController.clear();
    _kmController.clear();
    _descricaoController.clear();
    _selectedDate = DateTime.now();
    if (_tiposManutencao.isNotEmpty) {
      _selectedTipo = _tiposManutencao.first;
    }
  }

  Future<void> _deleteManutencao(String id) async {
    await _db.deleteManutencao(id);
    _loadManutencoes();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Manutenção excluída com sucesso!')),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Controle de Manutenções'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Nova Manutenção'),
            Tab(text: 'Histórico'),
            Tab(text: 'Alertas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNovaManutencaoTab(),
          _buildHistoricoTab(),
          _buildAlertasTab(),
        ],
      ),
    );
  }

  Widget _buildNovaManutencaoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Registrar Nova Manutenção',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Data
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Data'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                  }
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Tipo
            DropdownButtonFormField<String>(
              value: _selectedTipo.isEmpty ? null : _selectedTipo,
              decoration: const InputDecoration(
                labelText: 'Tipo de Manutenção',
                prefixIcon: Icon(Icons.build),
              ),
              items: _tiposManutencao.map((tipo) {
                return DropdownMenuItem(
                  value: tipo,
                  child: Text(tipo),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedTipo = value);
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Selecione um tipo';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Valor
            TextFormField(
              controller: _valorController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Valor (R\$)',
                prefixIcon: Icon(Icons.attach_money),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Campo obrigatório';
                }
                if (double.tryParse(value) == null) {
                  return 'Valor inválido';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // KM Atual
            TextFormField(
              controller: _kmController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'KM Atual da Moto',
                prefixIcon: Icon(Icons.speed),
                suffixText: 'km',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Campo obrigatório';
                }
                if (double.tryParse(value) == null) {
                  return 'Valor inválido';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Descrição
            TextFormField(
              controller: _descricaoController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descrição da Manutenção',
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveManutencao,
                child: const Text('Salvar Manutenção'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoricoTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_manutencoes.isEmpty) {
      return const Center(child: Text('Nenhuma manutenção registrada'));
    }

    // Agrupar manutenções por tipo para resumo
    final manutencoesPorTipo = <String, double>{};
    for (final manutencao in _manutencoes) {
      manutencoesPorTipo[manutencao.tipo] = 
          (manutencoesPorTipo[manutencao.tipo] ?? 0) + manutencao.valor;
    }

    final totalManutencoes = _manutencoes.fold(0.0, (sum, m) => sum + m.valor);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumo por tipo
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Investimento por Tipo',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...manutencoesPorTipo.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.key),
                          Text(
                            'R\$ ${entry.value.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        'R\$ ${totalManutencoes.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.warningColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          const Text(
            'Histórico Detalhado',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          
          const SizedBox(height: 8),
          
          // Lista de manutenções
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _manutencoes.length,
            itemBuilder: (context, index) {
              final manutencao = _manutencoes[index];
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ExpansionTile(
                  title: Text(
                    manutencao.tipo,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${DateFormat('dd/MM/yyyy').format(manutencao.data)} - R\$ ${manutencao.valor.toStringAsFixed(2)}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _showDeleteConfirmation(manutencao),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoCard(
                                  'Valor',
                                  'R\$ ${manutencao.valor.toStringAsFixed(2)}',
                                  AppTheme.errorColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildInfoCard(
                                  'KM Atual',
                                  '${manutencao.kmAtual.toStringAsFixed(0)} km',
                                  AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          if (manutencao.descricao?.isNotEmpty == true) ...[
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Descrição: ${manutencao.descricao}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.successColor.withAlpha((255 * 0.1).toInt()),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Próxima ${manutencao.tipo} sugerida em breve',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.successColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withAlpha((255 * 0.1).toInt()),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertasTab() {
    if (_manutencoes.isEmpty) {
      return const Center(child: Text('Nenhuma manutenção registrada'));
    }

    // Obter última manutenção de cada tipo
    final ultimasManutencoes = <String, ManutencaoModel>{};
    for (final manutencao in _manutencoes) {
      if (!ultimasManutencoes.containsKey(manutencao.tipo) ||
          manutencao.data.isAfter(ultimasManutencoes[manutencao.tipo]!.data)) {
        ultimasManutencoes[manutencao.tipo] = manutencao;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Próximas Manutenções',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          ...ultimasManutencoes.entries.map((entry) {
            final tipo = entry.key;
            final ultimaManutencao = entry.value;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.build, color: AppTheme.warningColor),
                title: Text(tipo),
                subtitle: Text(
                  'Última: ${DateFormat('dd/MM/yyyy').format(ultimaManutencao.data)} - ${ultimaManutencao.kmAtual.toStringAsFixed(0)} km',
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withAlpha((255 * 0.1).toInt()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Em breve',
                    style: const TextStyle(
                      color: AppTheme.warningColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }),
          
          const SizedBox(height: 16),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Dicas de Manutenção',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('• Mantenha sempre o óleo em dia'),
                  Text('• Verifique os pneus regularmente'),
                  Text('• Não negligencie os freios'),
                  Text('• Faça revisões preventivas'),
                  Text('• Mantenha registros organizados'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(ManutencaoModel manutencao) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Deseja excluir a manutenção "${manutencao.tipo}" de R\$ ${manutencao.valor.toStringAsFixed(2)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (manutencao.id != null) _deleteManutencao(manutencao.id!);
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}