import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Gunakan hive_flutter, bukan hive biasa
import 'package:logbook_app_modul5/features/logbook/models/log_model.dart';
import 'package:logbook_app_modul5/features/onboarding/onboarding_view.dart';

void main() async {
  // Wajib untuk operasi asinkron sebelum runApp
  WidgetsFlutterBinding.ensureInitialized();

  try {
    debugPrint('📱 [STARTUP] Initializing app...');

    // Load ENV - Memuat konfigurasi dari file .env
    debugPrint('🔐 [STARTUP] Loading .env file...');
    await dotenv.load(fileName: ".env");
    debugPrint('✅ [STARTUP] .env loaded');

    // INISIALISASI HIVE (Modul 5 - Offline-First Strategy)
    debugPrint('💾 [STARTUP] Initializing Hive...');
    await Hive.initFlutter();
    debugPrint('✅ [STARTUP] Hive initialized');

    debugPrint('🔧 [STARTUP] Registering Hive adapter...');
    Hive.registerAdapter(LogModelAdapter()); // WAJIB: Sesuai nama di .g.dart
    debugPrint('✅ [STARTUP] Adapter registered');

    debugPrint('📦 [STARTUP] Opening Hive box...');
    await Hive.openBox<LogModel>('offline_logs').timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        debugPrint('⚠️ [STARTUP] Hive box timeout, deleting and retrying...');
        Hive.deleteBoxFromDisk('offline_logs');
        return Hive.openBox<LogModel>('offline_logs');
      },
    );
    debugPrint('✅ [STARTUP] Hive box opened successfully');

    debugPrint('🚀 [STARTUP] Starting app...');
    runApp(const MyApp());
  } catch (e, stackTrace) {
    debugPrint('❌ [STARTUP] Fatal error: $e');
    debugPrint('Stack trace: $stackTrace');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Initialization Failed'),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LogBook App - Modul 5',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const OnboardingView(),
    );
  }
}
