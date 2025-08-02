import 'package:flutter/material.dart';
import '../screens/backend_config_screen.dart';

class SecretGestureDetector extends StatefulWidget {
  final Widget child;
  final int requiredTaps;
  final Duration tapTimeout;

  const SecretGestureDetector({
    Key? key,
    required this.child,
    this.requiredTaps = 5,
    this.tapTimeout = const Duration(seconds: 2),
  }) : super(key: key);

  @override
  State<SecretGestureDetector> createState() => _SecretGestureDetectorState();
}

class _SecretGestureDetectorState extends State<SecretGestureDetector> {
  int _tapCount = 0;
  DateTime? _lastTapTime;

  void _onTap() {
    final now = DateTime.now();
    
    // Reset counter if too much time has passed
    if (_lastTapTime != null && 
        now.difference(_lastTapTime!) > widget.tapTimeout) {
      _tapCount = 0;
    }
    
    _tapCount++;
    _lastTapTime = now;
    
    // Show feedback for progress
    if (_tapCount > 1 && _tapCount < widget.requiredTaps) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.requiredTaps - _tapCount} toques restantes...'),
          duration: const Duration(milliseconds: 500),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    
    // Trigger secret action
    if (_tapCount >= widget.requiredTaps) {
      _tapCount = 0;
      _lastTapTime = null;
      _openBackendConfig();
    }
  }

  void _openBackendConfig() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔧 Configuração de Desenvolvedor'),
        content: const Text(
          'Você ativou o modo desenvolvedor!\n\n'
          'Deseja abrir as configurações do backend?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const BackendConfigScreen(),
                ),
              );
            },
            child: const Text('Abrir Configurações'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: widget.child,
    );
  }
}