import 'dart:async';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  static ConnectivityService get instance => _instance;
  ConnectivityService._internal();

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  Timer? _checkTimer;

  void startMonitoring() {
    _checkConnectivity();
    _checkTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkConnectivity();
    });
  }

  void stopMonitoring() {
    _checkTimer?.cancel();
    _checkTimer = null;
  }

  Future<void> _checkConnectivity() async {
    final wasOnline = _isOnline;
    _isOnline = await ApiService.isOnline();
    
    if (wasOnline != _isOnline) {
      notifyListeners();
    }
  }

  Future<bool> checkNow() async {
    await _checkConnectivity();
    return _isOnline;
  }

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}
