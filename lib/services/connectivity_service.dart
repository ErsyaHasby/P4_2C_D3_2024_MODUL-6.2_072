import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logbook_app_modul5/helpers/log_helper.dart';

/// ConnectivityService - Network State Monitor & Auto-Sync Trigger
///
/// Konsep: Reactive Network Monitoring untuk Offline-First Architecture
/// Logika: Listen connectivity changes → Trigger sync when online
/// Tujuan: Seamless background synchronization without user intervention
class ConnectivityService {
  // Singleton Pattern
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _wasOffline =
      false; // Track previous offline state untuk detect recovery

  /// Initialize connectivity monitoring
  /// onConnectivityRestored: Callback saat network kembali online
  void startMonitoring({required Function() onConnectivityRestored}) async {
    // Check initial status
    final initialResult = await _connectivity.checkConnectivity();
    _wasOffline = _isOffline(initialResult);

    await LogHelper.writeLog(
      "ConnectivityService: Monitoring started (Initial: ${_wasOffline ? 'OFFLINE' : 'ONLINE'})",
      source: "connectivity_service.dart",
      level: 3,
    );

    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      results,
    ) async {
      final isCurrentlyOffline = _isOffline(results);

      // Detect OFFLINE → ONLINE transition
      if (_wasOffline && !isCurrentlyOffline) {
        await LogHelper.writeLog(
          "ConnectivityService: Network RESTORED (${results.join(', ')})",
          source: "connectivity_service.dart",
          level: 2,
        );

        // Trigger auto-sync callback
        onConnectivityRestored();
      }

      // Detect ONLINE → OFFLINE transition
      if (!_wasOffline && isCurrentlyOffline) {
        await LogHelper.writeLog(
          "ConnectivityService: Network LOST (Entering offline mode)",
          source: "connectivity_service.dart",
          level: 1,
        );
      }

      // Update state
      _wasOffline = isCurrentlyOffline;
    });
  }

  /// Helper: Check if connectivity result indicates offline
  bool _isOffline(List<ConnectivityResult> results) {
    return results.isEmpty ||
        results.every((r) => r == ConnectivityResult.none);
  }

  /// Check current connectivity status (instant check, no listening)
  Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return !_isOffline(result);
  }

  /// Stop monitoring (cleanup on app dispose)
  void stopMonitoring() {
    _connectivitySubscription?.cancel();
    LogHelper.writeLog(
      "ConnectivityService: Monitoring stopped",
      source: "connectivity_service.dart",
      level: 3,
    );
  }

  /// Get current connectivity type (for debugging/UI display)
  Future<String> getConnectionType() async {
    final result = await _connectivity.checkConnectivity();
    if (result.isEmpty) return 'None';
    return result.map((r) => r.name).join(', ');
  }
}
