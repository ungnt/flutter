import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/gasto_model.dart';
import '../theme/app_theme.dart';
import '../constants/categories.dart';

class GastosScreen extends StatefulWidget {
  const GastosScreen({super.key});

  @override
  State<GastosScreen> createState() => _GastosScreenState();
}

class _GastosScreenState extends State<GastosScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  
  final _valorController = TextEditingController();
  final _descricaoController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  String _selectedCategoria = '';
  List<String> _categorias = [];
  List<GastoModel> _gastos = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCategorias();
    _loadGastos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _valorController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _loadCategorias() async {
    _categorias = GastosCategories.categorias;
    if (_categorias.isNotEmpty) {
      _selectedCategoria = _categorias.first;
    }
    setState(() {});
  }

  Future<void> _loadGastos() async {
    setState(() => _isLoading = true);
    final response = await ApiService.getGastos();
    if (response.success && response.data != null) {
      final gastosList = response.data!['gastos'] as List<dynamic>;
      _gastos = gastosList.map((g) => GastoModel.fromMap(g)).toList();
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveGasto() async {
    if (_formKey.currentState!.validate()) {
      final gastoData = {
        'data': _selectedDate.toIso8601String(),
        'categoria': _selectedCategoria,
        'valor': double.parse(_valorController.text),
        'descricao': _descricaoController.text,
        'data_registro': DateTime.now().toIso8601String(),
      };

      final response = await ApiService.createGasto(gastoData);
      
      if (response.success) {
        _clearForm();
        await _loadGastos();
        
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gasto salvo com sucesso!')),
        );
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message)),
        );
      }
    }
  }

  void _clearForm() {
    _valorController.clear();
    _descricaoController.clear();
    _selectedDate = DateTime.now();
    if (_categorias.isNotEmpty) {
      _selectedCategoria = _categorias.first;
    }
  }

  Future<void> _deleteGasto(String id) async {
    final response = await ApiService.deleteGasto(id);
    if (response.success) {
      await _loadGastos();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gasto excluído com sucesso!')),
      );
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Controle de Gastos'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Novo Gasto'),
            Tab(text: 'Histórico'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNovoGastoTab(),
          _buildHistoricoTab(),
        ],
      ),
    );
  }

  Widget _buildNovoGastoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Adicionar Novo Gasto',
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
            
            // Categoria
            DropdownButtonFormField<String>(
              value: _selectedCategoria.isEmpty ? null : _selectedCategoria,
              decoration: const InputDecoration(
                labelText: 'Categoria',
                prefixIcon: Icon(Icons.category),
              ),
              items: _categorias.map((categoria) {
                return DropdownMenuItem(
                  value: categoria,
                  child: Row(
                    children: [
                      Text(GastosCategories.getIcon(categoria)),
                      const SizedBox(width: 8),
                      Text(categoria),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCategoria = value);
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Selecione uma categoria';
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
            
            // Descrição
            TextFormField(
              controller: _descricaoController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveGasto,
                child: const Text('Salvar Gasto'),
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

    if (_gastos.isEmpty) {
      return const Center(child: Text('Nenhum gasto registrado'));
    }

    // Agrupar gastos por categoria para resumo
    final gastosPorCategoria = <String, double>{};
    for (final gasto in _gastos) {
      gastosPorCategoria[gasto.categoria] = 
          (gastosPorCategoria[gasto.categoria] ?? 0) + gasto.valor;
    }

    final totalGastos = _gastos.fold(0.0, (sum, g) => sum + g.valor);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumo por categoria
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resumo por Categoria',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...gastosPorCategoria.entries.map((entry) {
                    final porcentagem = (entry.value / totalGastos * 100);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.key),
                          Text(
                            'R\$ ${entry.value.toStringAsFixed(2)} (${porcentagem.toStringAsFixed(1)}%)',
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
                        'R\$ ${totalGastos.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.errorColor,
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
          
          // Lista de gastos
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _gastos.length,
            itemBuilder: (context, index) {
              final gasto = _gastos[index];
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getCategoryColor(gasto.categoria),
                    child: Icon(
                      _getCategoryIcon(gasto.categoria),
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    gasto.categoria,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(DateFormat('dd/MM/yyyy').format(gasto.data)),
                      if (gasto.descricao.isNotEmpty)
                        Text(gasto.descricao, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'R\$ ${gasto.valor.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.errorColor,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _showDeleteConfirmation(gasto),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String categoria) {
    switch (categoria) {
      case 'Combustível':
        return Colors.orange;
      case 'Alimentação':
        return Colors.green;
      case 'Pedágio':
        return Colors.blue;
      case 'Estacionamento':
        return Colors.purple;
      case 'Limpeza':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String categoria) {
    switch (categoria) {
      case 'Combustível':
        return Icons.local_gas_station;
      case 'Alimentação':
        return Icons.restaurant;
      case 'Pedágio':
        return Icons.toll;
      case 'Estacionamento':
        return Icons.local_parking;
      case 'Limpeza':
        return Icons.cleaning_services;
      default:
        return Icons.category;
    }
  }

  void _showDeleteConfirmation(GastoModel gasto) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Deseja excluir o gasto "${gasto.categoria}" de R\$ ${gasto.valor.toStringAsFixed(2)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteGasto(gasto.id.toString());
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}