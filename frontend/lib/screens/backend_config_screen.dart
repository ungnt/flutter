import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/backend_config.dart';
import '../services/backend_config_service.dart';

class BackendConfigScreen extends StatefulWidget {
  final bool isFirstSetup;
  
  const BackendConfigScreen({
    Key? key,
    this.isFirstSetup = false,
  }) : super(key: key);

  @override
  State<BackendConfigScreen> createState() => _BackendConfigScreenState();
}

class _BackendConfigScreenState extends State<BackendConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _baseUrlController = TextEditingController();
  final _hostController = TextEditingController();
  final _portController = TextEditingController();
  final _apiPathController = TextEditingController();
  final _timeoutController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedProtocol = 'https';
  bool _useHttps = true;
  bool _isLoading = false;
  bool _isTestingConnection = false;
  String? _connectionResult;
  BackendConfig? _selectedPreset;

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  void _loadCurrentConfig() async {
    final config = await BackendConfigService.instance.loadConfig();
    if (config != null) {
      setState(() {
        _baseUrlController.text = config.baseUrl;
        _hostController.text = config.host;
        _portController.text = config.port.toString();
        _apiPathController.text = config.apiPath;
        _timeoutController.text = config.timeoutSeconds.toString();
        _descriptionController.text = config.description;
        _selectedProtocol = config.protocol;
        _useHttps = config.useHttps;
      });
    }
  }

  void _loadPresetConfig(BackendConfig preset) {
    setState(() {
      _selectedPreset = preset;
      _baseUrlController.text = preset.baseUrl;
      _hostController.text = preset.host;
      _portController.text = preset.port.toString();
      _apiPathController.text = preset.apiPath;
      _timeoutController.text = preset.timeoutSeconds.toString();
      _descriptionController.text = preset.description;
      _selectedProtocol = preset.protocol;
      _useHttps = preset.useHttps;
    });
  }

  BackendConfig _buildConfigFromForm() {
    return BackendConfig(
      baseUrl: _baseUrlController.text.trim(),
      protocol: _selectedProtocol,
      host: _hostController.text.trim(),
      port: int.tryParse(_portController.text) ?? 5000,
      apiPath: _apiPathController.text.trim(),
      timeoutSeconds: int.tryParse(_timeoutController.text) ?? 30,
      useHttps: _useHttps,
      description: _descriptionController.text.trim(),
    );
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isTestingConnection = true;
      _connectionResult = null;
    });

    try {
      final config = _buildConfigFromForm();
      final healthUrl = '${config.fullBaseUrl}/health';
      
      final response = await http.get(
        Uri.parse(healthUrl),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: config.timeoutSeconds));

      if (response.statusCode == 200) {
        setState(() {
          _connectionResult = '✅ Conexão bem-sucedida! Backend respondeu corretamente.';
        });
      } else {
        setState(() {
          _connectionResult = '⚠️ Backend respondeu mas com status: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _connectionResult = '❌ Erro de conexão: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isTestingConnection = false;
      });
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final config = _buildConfigFromForm();
      final success = await BackendConfigService.instance.saveConfig(config);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Configuração salva com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        
        if (widget.isFirstSetup) {
          Navigator.of(context).pushReplacementNamed('/');
        } else {
          Navigator.of(context).pop(true);
        }
      } else {
        throw Exception('Falha ao salvar configuração');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erro ao salvar: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isFirstSetup ? 'Configuração Inicial' : 'Configurar Backend'),
        automaticallyImplyLeading: !widget.isFirstSetup,
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.isFirstSetup) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(Icons.settings, size: 48, color: Colors.blue[700]),
                        const SizedBox(height: 8),
                        const Text(
                          'Primeira configuração',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Configure o backend que o app irá usar para sincronizar seus dados.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Configurações pré-definidas
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Configurações Pré-definidas',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...BackendConfigService.instance.getPresetConfigs().map((preset) =>
                        ListTile(
                          title: Text(preset.description),
                          subtitle: Text(preset.fullBaseUrl),
                          trailing: _selectedPreset == preset
                              ? Icon(Icons.check_circle, color: Colors.green)
                              : Icon(Icons.radio_button_unchecked),
                          onTap: () => _loadPresetConfig(preset),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Configuração manual
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Configuração Manual',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      // URL Base
                      TextFormField(
                        controller: _baseUrlController,
                        decoration: const InputDecoration(
                          labelText: 'URL Base Completa',
                          hintText: 'https://exemplo.com:5000',
                          border: OutlineInputBorder(),
                          helperText: 'URL completa do backend (opcional se preencher campos abaixo)',
                        ),
                        validator: (value) {
                          if (value?.isNotEmpty == true) {
                            final uri = Uri.tryParse(value!);
                            if (uri == null || !uri.hasScheme) {
                              return 'URL inválida';
                            }
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),

                      // Protocolo
                      DropdownButtonFormField<String>(
                        value: _selectedProtocol,
                        decoration: const InputDecoration(
                          labelText: 'Protocolo',
                          border: OutlineInputBorder(),
                        ),
                        items: ['http', 'https'].map((protocol) =>
                          DropdownMenuItem(
                            value: protocol,
                            child: Text(protocol.toUpperCase()),
                          ),
                        ).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedProtocol = value!;
                            _useHttps = value == 'https';
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      // Host
                      TextFormField(
                        controller: _hostController,
                        decoration: const InputDecoration(
                          labelText: 'Host',
                          hintText: 'localhost ou meu-site.com',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value?.isEmpty == true && _baseUrlController.text.isEmpty) {
                            return 'Host é obrigatório';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Porta
                      TextFormField(
                        controller: _portController,
                        decoration: const InputDecoration(
                          labelText: 'Porta',
                          hintText: '5000',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.isNotEmpty == true) {
                            final port = int.tryParse(value!);
                            if (port == null || port < 1 || port > 65535) {
                              return 'Porta inválida (1-65535)';
                            }
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Caminho da API
                      TextFormField(
                        controller: _apiPathController,
                        decoration: const InputDecoration(
                          labelText: 'Caminho da API',
                          hintText: '/api',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value?.isNotEmpty == true && !value!.startsWith('/')) {
                            return 'Caminho deve começar com /';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Timeout
                      TextFormField(
                        controller: _timeoutController,
                        decoration: const InputDecoration(
                          labelText: 'Timeout (segundos)',
                          hintText: '30',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.isNotEmpty == true) {
                            final timeout = int.tryParse(value!);
                            if (timeout == null || timeout < 5 || timeout > 300) {
                              return 'Timeout inválido (5-300 segundos)';
                            }
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Descrição
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Descrição (opcional)',
                          hintText: 'Backend de desenvolvimento',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Teste de conexão
              if (_connectionResult != null) ...[
                Card(
                  color: _connectionResult!.startsWith('✅') ? Colors.green[50] : Colors.red[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _connectionResult!,
                      style: TextStyle(
                        color: _connectionResult!.startsWith('✅') ? Colors.green[700] : Colors.red[700],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Botões
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isTestingConnection ? null : _testConnection,
                      icon: _isTestingConnection
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.wifi_find),
                      label: Text(_isTestingConnection ? 'Testando...' : 'Testar Conexão'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _saveConfig,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: Text(_isLoading ? 'Salvando...' : 'Salvar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _apiPathController.dispose();
    _timeoutController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}