import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/trabalho_model.dart';
import '../theme/app_theme.dart';

class TrabalhoScreen extends StatefulWidget {
  const TrabalhoScreen({super.key});

  @override
  State<TrabalhoScreen> createState() => _TrabalhoScreenState();
}

class _TrabalhoScreenState extends State<TrabalhoScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseService _db = DatabaseService.instance;
  final _formKey = GlobalKey<FormState>();
  
  final _ganhosController = TextEditingController();
  final _kmController = TextEditingController();
  final _horasController = TextEditingController();
  final _observacoesController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  List<TrabalhoModel> _trabalhos = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTrabalhos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ganhosController.dispose();
    _kmController.dispose();
    _horasController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  Future<void> _loadTrabalhos() async {
    setState(() => _isLoading = true);
    _trabalhos = await _db.getTrabalhos();
    setState(() => _isLoading = false);
  }

  Future<void> _saveTrabalho() async {
    if (_formKey.currentState!.validate()) {
      final trabalho = TrabalhoModel(
        data: _selectedDate,
        ganhos: double.parse(_ganhosController.text),
        km: double.parse(_kmController.text),
        horas: double.parse(_horasController.text),
        observacoes: _observacoesController.text,
        dataRegistro: DateTime.now(),
      );

      await _db.insertTrabalho(trabalho);
      
      _clearForm();
      _loadTrabalhos();
      
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro salvo com sucesso!')),
      );
    }
  }

  void _clearForm() {
    _ganhosController.clear();
    _kmController.clear();
    _horasController.clear();
    _observacoesController.clear();
    _selectedDate = DateTime.now();
  }

  Future<void> _deleteTrabalho(int id) async {
    await _db.deleteTrabalho(id);
    _loadTrabalhos();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registro excluído com sucesso!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro Diário'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Novo Registro'),
            Tab(text: 'Histórico'),
            Tab(text: 'Resumo'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNovoRegistroTab(),
          _buildHistoricoTab(),
          _buildResumoTab(),
        ],
      ),
    );
  }

  Widget _buildNovoRegistroTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Adicionar Novo Registro',
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
            
            // Ganhos
            TextFormField(
              controller: _ganhosController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Ganhos (R\$)',
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
            
            // KM
            TextFormField(
              controller: _kmController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quilometragem',
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
            

            
            // Horas
            TextFormField(
              controller: _horasController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Horas trabalhadas',
                prefixIcon: Icon(Icons.access_time),
                suffixText: 'h',
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
            
            // Observações
            TextFormField(
              controller: _observacoesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Observações',
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveTrabalho,
                child: const Text('Salvar Registro'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoricoTab() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _trabalhos.isEmpty
            ? const Center(child: Text('Nenhum registro encontrado'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _trabalhos.length,
                itemBuilder: (context, index) {
                  final trabalho = _trabalhos[index];
                  final lucro = trabalho.ganhos;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ExpansionTile(
                      title: Text(
                        DateFormat('dd/MM/yyyy').format(trabalho.data),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Ganhos: R\$ ${trabalho.ganhos.toStringAsFixed(2)} | Líquido: R\$ ${lucro.toStringAsFixed(2)}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _showDeleteConfirmation(trabalho),
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
                                      'Ganhos',
                                      'R\$ ${trabalho.ganhos.toStringAsFixed(2)}',
                                      AppTheme.successColor,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildInfoCard(
                                      'Líquido',
                                      'R\$ ${trabalho.ganhos.toStringAsFixed(2)}',
                                      AppTheme.successColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInfoCard(
                                      'KM',
                                      '${trabalho.km.toStringAsFixed(1)} km',
                                      AppTheme.primaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildInfoCard(
                                      'Horas',
                                      '${trabalho.horas.toStringAsFixed(1)}h',
                                      AppTheme.secondaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              if (trabalho.observacoes.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Observações: ${trabalho.observacoes}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
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

  Widget _buildResumoTab() {
    if (_trabalhos.isEmpty) {
      return const Center(child: Text('Nenhum registro encontrado'));
    }

    final totalGanhos = _trabalhos.fold(0.0, (sum, t) => sum + t.ganhos);
    final totalKm = _trabalhos.fold(0.0, (sum, t) => sum + t.km);
    final totalHoras = _trabalhos.fold(0.0, (sum, t) => sum + t.horas);
    final totalLiquido = totalGanhos;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumo Geral',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildResumoItem('Total de Ganhos', totalGanhos, AppTheme.successColor),
                  _buildResumoItem('Total Líquido', totalLiquido, AppTheme.primaryColor),
                  _buildResumoItem('Total de KM', totalKm, AppTheme.secondaryColor, suffixText: ' km'),
                  _buildResumoItem('Total de Horas', totalHoras, AppTheme.warningColor, suffixText: ' h'),
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
                    'Médias',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Ganhos por dia: R\$ ${(totalGanhos / _trabalhos.length).toStringAsFixed(2)}'),
                  Text('KM por dia: ${(totalKm / _trabalhos.length).toStringAsFixed(1)} km'),
                  Text('Horas por dia: ${(totalHoras / _trabalhos.length).toStringAsFixed(1)} h'),
                  Text('Ganhos por KM: R\$ ${totalKm > 0 ? (totalGanhos / totalKm).toStringAsFixed(2) : '0.00'}'),
                  Text('Ganhos por hora: R\$ ${totalHoras > 0 ? (totalGanhos / totalHoras).toStringAsFixed(2) : '0.00'}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoItem(String title, double value, Color color, {String suffixText = ''}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(
            suffixText.isEmpty 
                ? 'R\$ ${value.toStringAsFixed(2)}'
                : '${value.toStringAsFixed(suffixText.contains('h') ? 1 : 0)}$suffixText',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(TrabalhoModel trabalho) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Deseja excluir o registro de ${DateFormat('dd/MM/yyyy').format(trabalho.data)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTrabalho(trabalho.id!);
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}