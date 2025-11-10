import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'screens/registro_integrado_screen.dart';
import 'screens/relatorios_screen.dart';
import 'screens/configuracoes_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/sync_screen.dart';
import 'screens/premium_screen.dart';
import 'screens/backend_config_screen.dart';
import 'services/database_service.dart';
import 'services/theme_service.dart';
import 'services/backend_config_service.dart';
import 'services/connectivity_service.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar serviços de configuração do backend
  await BackendConfigService.instance.initialize();

  // Inicializar banco de dados
  await DatabaseService.instance.initDatabase();

  // Inicializar serviços
  final themeService = ThemeService();
  await themeService.init();

  // Iniciar monitoramento de conectividade
  ConnectivityService.instance.startMonitoring();

  runApp(MyApp(themeService: themeService));
}

class MyApp extends StatelessWidget {
  final ThemeService themeService;

  const MyApp({super.key, required this.themeService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeService),
        ChangeNotifierProvider.value(value: ConnectivityService.instance),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: 'KM\$',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeService.themeMode,
            home: const InitialSetupChecker(),
            routes: {
              '/home': (context) => const HomeScreen(),
              '/registro': (context) => const RegistroIntegradoScreen(),
              '/relatorios': (context) => const RelatoriosScreen(),
              '/configuracoes': (context) => const ConfiguracoesScreen(),
              '/goals': (context) => const GoalsScreen(),
              '/login': (context) => LoginScreen(),
              '/register': (context) => RegisterScreen(),
              '/sync': (context) => SyncScreen(),
              '/premium': (context) => PremiumScreen(),
              '/backend-config': (context) => const BackendConfigScreen(),
            },
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class InitialSetupChecker extends StatefulWidget {
  const InitialSetupChecker({Key? key}) : super(key: key);

  @override
  State<InitialSetupChecker> createState() => _InitialSetupCheckerState();
}

class _InitialSetupCheckerState extends State<InitialSetupChecker> {
  @override
  void initState() {
    super.initState();
    _checkInitialSetup();
  }

  Future<void> _checkInitialSetup() async {
    // Aguardar um frame para garantir que o widget foi construído
    await Future.delayed(const Duration(milliseconds: 100));
    
    // 1. Verificar se backend está configurado
    final isConfigured = await BackendConfigService.instance.isConfigured();
    
    if (!isConfigured) {
      // Primeira configuração necessária
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const BackendConfigScreen(isFirstSetup: true),
          ),
        );
      }
      return;
    }
    
    // 2. Verificar se usuário está autenticado (login obrigatório)
    final isAuthenticated = await AuthService.isAuthenticated();
    
    if (!isAuthenticated) {
      // Não autenticado - redirecionar para login
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => LoginScreen(),
          ),
        );
      }
    } else {
      // Autenticado - ir para home
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Inicializando...'),
          ],
        ),
      ),
    );
  }
}