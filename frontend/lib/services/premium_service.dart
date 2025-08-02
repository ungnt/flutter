import 'package:flutter/foundation.dart';
import 'api_service.dart';

/// Serviço para gerenciar funcionalidades Premium
/// Controla assinatura, status e funcionalidades exclusivas
class PremiumService extends ChangeNotifier {
  static final PremiumService instance = PremiumService._internal();
  PremiumService._internal();

  bool _isPremium = true; // TEMPORÁRIO: Premium gratuito para testes
  DateTime? _premiumUntil;
  bool _isCheckingStatus = false;

  // Getters
  bool get isPremium => _isPremium;
  DateTime? get premiumUntil => _premiumUntil;
  bool get isCheckingStatus => _isCheckingStatus;
  
  /// Verificar status premium no servidor
  Future<bool> checkPremiumStatus() async {
    _isCheckingStatus = true;
    notifyListeners();

    try {
      final result = await ApiService.checkPremiumStatus();
      
      if (result.success && result.data != null) {
        _isPremium = result.data!['is_premium'] ?? false;
        
        if (result.data!['premium_until'] != null) {
          _premiumUntil = DateTime.parse(result.data!['premium_until']);
        } else {
          _premiumUntil = null;
        }
        
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      print('Erro ao verificar status premium: $e');
      return false;
    } finally {
      _isCheckingStatus = false;
      notifyListeners();
    }
  }

  /// Criar assinatura premium
  Future<PremiumResult> subscribeToPremium() async {
    try {
      final result = await ApiService.createPremiumSubscription();
      
      if (result.success) {
        // Atualizar status local
        await checkPremiumStatus();
        
        return PremiumResult(
          success: true,
          message: 'Assinatura Premium ativada com sucesso!',
        );
      } else {
        return PremiumResult(
          success: false,
          message: result.message,
        );
      }
    } catch (e) {
      return PremiumResult(
        success: false,
        message: 'Erro ao ativar Premium: $e',
      );
    }
  }

  /// Cancelar assinatura premium
  Future<PremiumResult> cancelPremiumSubscription() async {
    try {
      final result = await ApiService.cancelPremiumSubscription();
      
      if (result.success) {
        // Atualizar status local
        await checkPremiumStatus();
        
        return PremiumResult(
          success: true,
          message: 'Assinatura Premium cancelada',
        );
      } else {
        return PremiumResult(
          success: false,
          message: result.message,
        );
      }
    } catch (e) {
      return PremiumResult(
        success: false,
        message: 'Erro ao cancelar Premium: $e',
      );
    }
  }

  /// Verificar se uma funcionalidade específica está disponível
  bool hasFeature(PremiumFeature feature) {
    // Se não está logado, apenas funcionalidades gratuitas
    if (!_isPremium) {
      return _freeFeatures.contains(feature);
    }

    // Se é premium, todas as funcionalidades
    return true;
  }

  /// Funcionalidades gratuitas sempre disponíveis
  static const List<PremiumFeature> _freeFeatures = [
    PremiumFeature.basicDashboard,
    PremiumFeature.localData,
    PremiumFeature.basicReports,
    PremiumFeature.localBackup,
  ];

  /// Verificar quantos dias restam da assinatura
  int? getDaysRemaining() {
    if (!_isPremium || _premiumUntil == null) return null;
    
    final now = DateTime.now();
    final difference = _premiumUntil!.difference(now);
    
    return difference.inDays;
  }

  /// Verificar se a assinatura está próxima do vencimento (menos de 7 dias)
  bool isExpiringsoon() {
    final days = getDaysRemaining();
    return days != null && days <= 7;
  }

  /// Reset do estado (usado no logout)
  void reset() {
    _isPremium = false;
    _premiumUntil = null;
    _isCheckingStatus = false;
    notifyListeners();
  }
}

enum PremiumFeature {
  // Funcionalidades gratuitas
  basicDashboard,
  localData,
  basicReports,
  localBackup,
  
  // Funcionalidades premium
  cloudSync,
  multiDevice,
  advancedReports,
  pdfExport,
  autoBackup,
  prioritySupport,
  unlimitedData,
  advancedAnalytics,
}

class PremiumResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  PremiumResult({
    required this.success,
    required this.message,
    this.data,
  });

  @override
  String toString() {
    return 'PremiumResult(success: $success, message: $message)';
  }
}