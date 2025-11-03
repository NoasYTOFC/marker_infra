import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/infrastructure_provider.dart';
import 'screens/home_screen.dart';
import 'services/file_intent_service.dart';
import 'services/connectivity_service.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  // ⚠️ CRÍTICO: Inicializar sqflite FFI ANTES de tudo para Windows/Linux/macOS
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  // Iniciar monitoramento de conectividade
  ConnectivityService().startMonitoring();
  
  // Filtrar logs chatos do sistema
  _setupLogFiltering();
  runApp(const MainApp());
}

/// Filtra logs indesejados do Android (gralloc, etc)
void _setupLogFiltering() {
  // Redirecionar stderr para filtrar logs específicos
  if (Platform.isAndroid) {
    final originalDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      // Ignorar logs de gralloc e outros logs de sistema
      if (message != null && !message.contains('gralloc') && !message.contains('SMPTE')) {
        originalDebugPrint(message, wrapWidth: wrapWidth);
      }
    };
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  File? _sharedFile;
  bool _hasCheckedForFile = false;

  @override
  void initState() {
    super.initState();
    // Verificar arquivo DEPOIS que o primeiro frame for renderizado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForSharedFile();
    });
  }

  Future<void> _checkForSharedFile() async {
    if (_hasCheckedForFile) return;
    _hasCheckedForFile = true;
    
    print('🔍 Verificando arquivo compartilhado...');
    final file = await FileIntentService.getSharedFile();
    print('📁 Arquivo recebido: ${file?.path ?? "null"}');
    
    if (file != null && mounted) {
      print('✅ Arquivo detectado! Atualizando HomeScreen...');
      setState(() {
        _sharedFile = file;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final provider = InfrastructureProvider();
        provider.loadData(); // Carregar dados salvos
        return provider;
      },
      child: MaterialApp(
        title: 'InfraPlan',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 2,
          ),
          cardTheme: const CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
            surface: const Color(0xFF1E1E1E),
            onSurface: Colors.white,
            onPrimary: Colors.white,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 2,
            backgroundColor: Color(0xFF1E1E1E),
            foregroundColor: Colors.white,
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            color: const Color(0xFF2A2A2A),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
          scaffoldBackgroundColor: const Color(0xFF1E1E1E),
          dialogBackgroundColor: const Color(0xFF2A2A2A),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF2A2A2A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF404040)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF404040)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            labelStyle: const TextStyle(color: Colors.white70),
            hintStyle: const TextStyle(color: Colors.white54),
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.white),
            bodyMedium: TextStyle(color: Colors.white70),
            bodySmall: TextStyle(color: Colors.white70),
            titleLarge: TextStyle(color: Colors.white),
            titleMedium: TextStyle(color: Colors.white70),
            labelLarge: TextStyle(color: Colors.white),
          ),
          tabBarTheme: const TabBarThemeData(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorSize: TabBarIndicatorSize.label,
          ),
        ),
        themeMode: ThemeMode.system,
        home: HomeScreen(sharedFile: _sharedFile),
      ),
    );
  }
}
