import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../services/online_data_service.dart';
import '../services/connectivity_service.dart';
import '../models/trabalho_model.dart';
import '../models/gasto_model.dart';
import '../models/manutencao_model.dart';


class RegistroIntegradoScreen extends StatefulWidget {
  const RegistroIntegradoScreen({super.key});

  @override
  State<RegistroIntegradoScreen> createState() => _RegistroIntegradoScreenState();
}

class _RegistroIntegradoScreenState extends State<RegistroIntegradoScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseService _db = DatabaseService.instance;
  final OnlineDataService _onlineService = OnlineDataService.instance;
  final _formKey = GlobalKey<FormState>();
  
  // Controladores para Trabalho
  final _ganhosController = TextEditingController();
  final _kmController = TextEditingController();
  final _horasController = TextEditingController();
  final _observacoesController = TextEditingController();
  
  // Controladores para Gastos
  final _valorGastoController = TextEditingController();
  final _descricaoGastoController = TextEditingController();
  
  // Controladores para Manutenções
  final _valorManutencaoController = TextEditingController();
  final _kmManutencaoController = TextEditingController();
  final _descricaoManutencaoController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  String _selectedCategoriaGasto = '';
  String _selectedTipoManutencao = '';
  
  List<String> _categoriasGasto = [];
  List<String> _tiposManutencao = [];
  List<TrabalhoModel> _trabalhos = [];
  List<GastoModel> _gastos = [];
  List<ManutencaoModel> _manutencao = [];
  
  bool _isLoading = false;
  bool _showGastoForm = false;
  bool _showManutencaoForm = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ganhosController.dispose();
    _kmController.dispose();
    _horasController.dispose();
    _observacoesController.dispose();
    _valorGastoController.dispose();
    _descricaoGastoController.dispose();
    _valorManutencaoController.dispose();
    _kmManutencaoController.dispose();
    _descricaoManutencaoController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadCategorias(),
      _loadTipos(),
      _loadTrabalhos(),
      _loadGastos(),
      _loadManutencoes(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadCategorias() async {
    _categoriasGasto = await _db.getCategoriasGastos();
    if (_categoriasGasto.isNotEmpty) {
      _selectedCategoriaGasto = _categoriasGasto.first;
    }
  }

  Future<void> _loadTipos() async {
    _tiposManutencao = await _db.getTiposManutencao();
    if (_tiposManutencao.isNotEmpty) {
      _selectedTipoManutencao = _tiposManutencao.first;
    }
  }

  Future<void> _loadTrabalhos() async {
    _trabalhos = await _db.getTrabalhos();
  }

  Future<void> _loadGastos() async {
    _gastos = await _db.getGastos();
  }

  Future<void> _loadManutencoes() async {
    _manutencao = await _db.getManutencoes();
  }

  Future<void> _saveRegistroCompleto() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Salvar trabalho via online service
        final trabalho = TrabalhoModel(
          data: _selectedDate,
          ganhos: double.parse(_ganhosController.text),
          km: double.parse(_kmController.text),
          horas: double.parse(_horasController.text),
          observacoes: _observacoesController.text,
          dataRegistro: DateTime.now(),
        );
        final trabalhoResult = await _onlineService.createTrabalho(trabalho);
        
        if (!trabalhoResult.success) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(trabalhoResult.message)),
          );
          return;
        }

        // Salvar gasto se preenchido
        if (_showGastoForm && _valorGastoController.text.isNotEmpty) {
          final gasto = GastoModel(
            data: _selectedDate,
            categoria: _selectedCategoriaGasto,
            valor: double.parse(_valorGastoController.text),
            descricao: _descricaoGastoController.text,
            dataRegistro: DateTime.now(),
          );
          final gastoResult = await _onlineService.createGasto(gasto);
          
          if (!gastoResult.success) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(gastoResult.message)),
            );
            return;
          }
        }

        // Salvar manutenção se preenchida
        if (_showManutencaoForm && _valorManutencaoController.text.isNotEmpty) {
          final manutencao = ManutencaoModel(
            data: _selectedDate,
            tipo: _selectedTipoManutencao,
            valor: double.parse(_valorManutencaoController.text),
            kmAtual: double.parse(_kmManutencaoController.text),
            descricao: _descricaoManutencaoController.text,
            dataRegistro: DateTime.now(),
          );
          final manutencaoResult = await _onlineService.createManutencao(manutencao);
          
          if (!manutencaoResult.success) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(manutencaoResult.message)),
            );
            return;
          }
        }

        _clearForm();
        _loadData();
        
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registro salvo com sucesso!')),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    }
  }

  void _clearForm() {
    _ganhosController.clear();
    _kmController.clear();
    _horasController.clear();
    _observacoesController.clear();
    _valorGastoController.clear();
    _descricaoGastoController.clear();
    _valorManutencaoController.clear();
    _kmManutencaoController.clear();
    _descricaoManutencaoController.clear();
    _selectedDate = DateTime.now();
    _showGastoForm = false;
    _showManutencaoForm = false;
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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

            // Informações de Trabalho
            const Text(
              'Informações de Trabalho',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            TextFormField(
              controller: _ganhosController,
              decoration: const InputDecoration(
                labelText: 'Ganhos (R\$)',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) => value?.isEmpty == true ? 'Campo obrigatório' : null,
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _kmController,
              decoration: const InputDecoration(
                labelText: 'Quilometragem',
                prefixIcon: Icon(Icons.speed),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) => value?.isEmpty == true ? 'Campo obrigatório' : null,
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _horasController,
              decoration: const InputDecoration(
                labelText: 'Horas trabalhadas',
                prefixIcon: Icon(Icons.access_time),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) => value?.isEmpty == true ? 'Campo obrigatório' : null,
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _observacoesController,
              decoration: const InputDecoration(
                labelText: 'Observações',
                prefixIcon: Icon(Icons.notes),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Seção de Gastos (Opcional)
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.receipt),
                    title: const Text('Adicionar Gasto'),
                    trailing: Switch(
                      value: _showGastoForm,
                      onChanged: (value) => setState(() => _showGastoForm = value),
                    ),
                  ),
                  if (_showGastoForm) ...[
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: _categoriasGasto.contains(_selectedCategoriaGasto) 
                                ? _selectedCategoriaGasto 
                                : null,
                            decoration: const InputDecoration(
                              labelText: 'Categoria',
                              border: OutlineInputBorder(),
                            ),
                            items: _categoriasGasto.map((categoria) {
                              return DropdownMenuItem(
                                value: categoria,
                                child: Text(categoria),
                              );
                            }).toList(),
                            onChanged: (value) => _selectedCategoriaGasto = value!,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _valorGastoController,
                            decoration: const InputDecoration(
                              labelText: 'Valor (R\$)',
                              prefixIcon: Icon(Icons.attach_money),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descricaoGastoController,
                            decoration: const InputDecoration(
                              labelText: 'Descrição',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Seção de Manutenções (Opcional)
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.build),
                    title: const Text('Adicionar Manutenção'),
                    trailing: Switch(
                      value: _showManutencaoForm,
                      onChanged: (value) => setState(() => _showManutencaoForm = value),
                    ),
                  ),
                  if (_showManutencaoForm) ...[
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: _tiposManutencao.contains(_selectedTipoManutencao) 
                                ? _selectedTipoManutencao 
                                : null,
                            decoration: const InputDecoration(
                              labelText: 'Tipo de Manutenção',
                              border: OutlineInputBorder(),
                            ),
                            items: _tiposManutencao.map((tipo) {
                              return DropdownMenuItem(
                                value: tipo,
                                child: Text(tipo),
                              );
                            }).toList(),
                            onChanged: (value) => _selectedTipoManutencao = value!,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _valorManutencaoController,
                            decoration: const InputDecoration(
                              labelText: 'Valor (R\$)',
                              prefixIcon: Icon(Icons.attach_money),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _kmManutencaoController,
                            decoration: const InputDecoration(
                              labelText: 'Quilometragem Atual',
                              prefixIcon: Icon(Icons.speed),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descricaoManutencaoController,
                            decoration: const InputDecoration(
                              labelText: 'Descrição',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _saveRegistroCompleto,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Salvar Registro Completo',
                style: TextStyle(fontSize: 16),
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

    if (_trabalhos.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum registro encontrado',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _trabalhos.length,
      itemBuilder: (context, index) {
        final trabalho = _trabalhos[index];
        final gastosData = _gastos.where((g) => 
          DateFormat('yyyy-MM-dd').format(g.data) == 
          DateFormat('yyyy-MM-dd').format(trabalho.data)
        ).toList();
        final manutencoesData = _manutencao.where((m) => 
          DateFormat('yyyy-MM-dd').format(m.data) == 
          DateFormat('yyyy-MM-dd').format(trabalho.data)
        ).toList();

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            title: Text(
              DateFormat('dd/MM/yyyy').format(trabalho.data),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Ganhos: R\$ ${trabalho.ganhos.toStringAsFixed(2)} • ${trabalho.km.toStringAsFixed(0)} km',
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Horas: ${trabalho.horas.toStringAsFixed(1)}h'),
                    if (trabalho.observacoes.isNotEmpty) 
                      Text('Observações: ${trabalho.observacoes}'),
                    
                    if (gastosData.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text('Gastos:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...gastosData.map((gasto) => Text(
                        '• ${gasto.categoria}: R\$ ${gasto.valor.toStringAsFixed(2)}',
                      )),
                    ],
                    
                    if (manutencoesData.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text('Manutenções:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...manutencoesData.map((manutencao) => Text(
                        '• ${manutencao.tipo}: R\$ ${manutencao.valor.toStringAsFixed(2)}',
                      )),
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

  Widget _buildResumoTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalGanhos = _trabalhos.fold<double>(0, (sum, t) => sum + t.ganhos);
    final totalKm = _trabalhos.fold<double>(0, (sum, t) => sum + t.km);
    final totalHoras = _trabalhos.fold<double>(0, (sum, t) => sum + t.horas);
    final totalGastos = _gastos.fold<double>(0, (sum, g) => sum + g.valor);
    final totalManutencoes = _manutencao.fold<double>(0, (sum, m) => sum + m.valor);
    final liquido = totalGanhos - totalGastos - totalManutencoes;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildResumoItem('Total de Ganhos', 'R\$ ${totalGanhos.toStringAsFixed(2)}', Colors.green),
                  _buildResumoItem('Total de Gastos', 'R\$ ${totalGastos.toStringAsFixed(2)}', Colors.red),
                  _buildResumoItem('Total de Manutenções', 'R\$ ${totalManutencoes.toStringAsFixed(2)}', Colors.orange),
                  const Divider(),
                  _buildResumoItem('Valor Líquido', 'R\$ ${liquido.toStringAsFixed(2)}', 
                    liquido >= 0 ? Colors.green : Colors.red),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildResumoItem('Total de Quilômetros', '${totalKm.toStringAsFixed(0)} km', Colors.blue),
                  _buildResumoItem('Total de Horas', '${totalHoras.toStringAsFixed(1)}h', Colors.purple),
                  if (totalKm > 0)
                    _buildResumoItem('Ganhos por KM', 'R\$ ${(totalGanhos / totalKm).toStringAsFixed(2)}', Colors.teal),
                  if (totalHoras > 0)
                    _buildResumoItem('Ganhos por Hora', 'R\$ ${(totalGanhos / totalHoras).toStringAsFixed(2)}', Colors.indigo),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}