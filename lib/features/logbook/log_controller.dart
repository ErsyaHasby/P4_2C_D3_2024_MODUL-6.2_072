import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;
import 'package:hive_flutter/hive_flutter.dart';
import 'models/log_model.dart';
import 'package:logbook_app_modul5/services/mongo_service.dart';
import 'package:logbook_app_modul5/helpers/log_helper.dart';

class LogController {
  final ValueNotifier<List<LogModel>> logsNotifier =
      ValueNotifier<List<LogModel>>([]);
  final ValueNotifier<List<LogModel>> filteredLogsNotifier =
      ValueNotifier<List<LogModel>>([]);

  // Task 4: Sync Status Notifier untuk track proses sinkronisasi
  final ValueNotifier<SyncStatus> syncStatusNotifier = ValueNotifier(
    SyncStatus.idle,
  );

  // Hive Box untuk Offline-First Storage
  Box<LogModel>? _offlineBox; // Changed to nullable
  bool _isInitialized = false; // Track initialization status

  // Getter untuk mempermudah akses list data saat ini
  List<LogModel> get logs => logsNotifier.value;

  // Getter untuk check initialization
  bool get isInitialized => _isInitialized;

  // --- KONSTRUKTOR ---
  // Inisialisasi Hive Box dan load data
  LogController() {
    _initOfflineStorage();
  }

  /// Initialize Hive Box untuk Offline-First
  Future<void> _initOfflineStorage() async {
    try {
      _offlineBox = await Hive.openBox<LogModel>('offline_logs');
      _isInitialized = true; // Mark as initialized
      await LogHelper.writeLog(
        "Controller: Hive Box initialized (${_offlineBox!.length} local logs)",
        source: "log_controller.dart",
        level: 3,
      );
      // Load from Hive immediately (Offline-First principe)
      _loadFromHive();
    } catch (e) {
      await LogHelper.writeLog(
        "Controller: Error initializing Hive - $e",
        source: "log_controller.dart",
        level: 1,
      );
      _isInitialized = false;
    }
  }

  /// Load data dari Hive (Local-First)
  void _loadFromHive() {
    if (_offlineBox == null) return; // Safety check
    final localLogs = _offlineBox!.values.toList();
    logsNotifier.value = localLogs;
    filteredLogsNotifier.value = localLogs;
  }

  // HOMEWORK: Search feature untuk filter logs secara real-time
  void searchLog(String query) {
    if (query.isEmpty) {
      filteredLogsNotifier.value = logsNotifier.value;
    } else {
      filteredLogsNotifier.value = logsNotifier.value
          .where(
            (log) =>
                log.title.toLowerCase().contains(query.toLowerCase()) ||
                log.description.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    }
  }

  // 1. Menambah data (Offline-First: Hive → MongoDB)
  Future<void> addLog(
    String title,
    String desc, {
    required String authorId,
    required String teamId,
    bool isPublic = false, // Task 5: Privacy control
    String category = 'Software', // Homework: Categorization
  }) async {
    if (_offlineBox == null) {
      throw Exception('Hive not initialized yet. Please wait...');
    }

    final newLog = LogModel(
      id: null, // Akan di-generate oleh MongoDB
      title: title,
      description: desc,
      date: DateTime.now().toString(),
      authorId: authorId,
      teamId: teamId,
      isPublic: isPublic, // Task 5: Set visibility
      category: category, // Homework: Set category
    );

    try {
      // STEP 1: Write to Hive FIRST (Instant response, no network wait)
      await _offlineBox!.add(newLog);
      _loadFromHive(); // Update UI immediately

      await LogHelper.writeLog(
        "OFFLINE-FIRST: Data '${newLog.title}' saved to Hive",
        source: "log_controller.dart",
        level: 2,
      );

      // STEP 2: Background sync to MongoDB (try-catch for offline tolerance)
      try {
        final insertedId = await MongoService().insertLog(newLog);

        if (insertedId != null) {
          // PENTING: Update Hive box dengan ID dari MongoDB
          // Ini membuat icon berubah dari orange (id==null) ke green (id!=null)
          final updatedLog = LogModel(
            id: insertedId,
            title: newLog.title,
            description: newLog.description,
            date: newLog.date,
            authorId: newLog.authorId,
            teamId: newLog.teamId,
            isPublic: newLog.isPublic, // Task 5: Preserve privacy setting
            category: newLog.category, // Homework: Preserve category
          );

          // Find index in Hive box dan update
          final hiveIndex = _offlineBox!.values.toList().indexWhere(
            (log) => log.title == newLog.title && log.date == newLog.date,
          );

          if (hiveIndex != -1) {
            await _offlineBox!.putAt(hiveIndex, updatedLog);
            _loadFromHive(); // Refresh UI (icon berubah green)
          }

          await LogHelper.writeLog(
            "SYNC: Data '${newLog.title}' synced to Cloud (ID: $insertedId)",
            source: "log_controller.dart",
            level: 2,
          );
        }
      } catch (e) {
        // Tetap sukses karena sudah tersimpan di Hive
        await LogHelper.writeLog(
          "SYNC: Background sync failed (data safe in Hive) - $e",
          source: "log_controller.dart",
          level: 1,
        );
      }
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Gagal menyimpan ke Hive - $e",
        source: "log_controller.dart",
        level: 1,
      );
      rethrow;
    }
  }

  // 2. Memperbarui data (Offline-First: Hive → MongoDB)
  Future<void> updateLog(
    int index,
    String newTitle,
    String newDesc, {
    Map<String, String>? currentUser, // Optional for backward compatibility
    bool? isPublic, // Task 5: Optional privacy update
    String? category, // Homework: Optional category update
  }) async {
    if (_offlineBox == null) {
      throw Exception('Hive not initialized yet. Please wait...');
    }

    final currentLogs = List<LogModel>.from(logsNotifier.value);
    final oldLog = currentLogs[index];

    // Task 5: SOVEREIGNTY - Only owner can edit (ignore role)
    if (currentUser != null) {
      final bool isOwner = oldLog.authorId == currentUser['uid'];
      if (!isOwner) {
        throw Exception(
          'SOVEREIGNTY: Hanya pemilik catatan yang boleh mengedit!',
        );
      }
    }

    final updatedLog = LogModel(
      id: oldLog.id, // ID harus tetap sama
      title: newTitle,
      description: newDesc,
      date: DateTime.now().toString(),
      authorId: oldLog.authorId, // Tetap sama
      teamId: oldLog.teamId, // Tetap sama
      isPublic: isPublic ?? oldLog.isPublic, // Task 5: Update or preserve
      category: category ?? oldLog.category, // Homework: Update or preserve
    );

    try {
      // STEP 1: Update Hive FIRST
      await _offlineBox!.putAt(index, updatedLog);
      _loadFromHive(); // Update UI immediately

      await LogHelper.writeLog(
        "OFFLINE-FIRST: Data '${oldLog.title}' updated in Hive",
        source: "log_controller.dart",
        level: 2,
      );

      // STEP 2: Background sync to MongoDB
      try {
        // Jika data belum ter-sync (id==null), gunakan insert instead of update
        if (oldLog.id == null) {
          await LogHelper.writeLog(
            "SYNC: Data belum ter-sync, melakukan insert...",
            source: "log_controller.dart",
            level: 3,
          );

          final insertedId = await MongoService().insertLog(updatedLog);

          if (insertedId != null) {
            // Update Hive dengan ID baru
            final logWithId = LogModel(
              id: insertedId,
              title: updatedLog.title,
              description: updatedLog.description,
              date: updatedLog.date,
              authorId: updatedLog.authorId,
              teamId: updatedLog.teamId,
              isPublic: updatedLog.isPublic, // Task 5: Preserve privacy
              category: updatedLog.category, // Homework: Preserve category
            );
            await _offlineBox!.putAt(index, logWithId);
            _loadFromHive();

            await LogHelper.writeLog(
              "SYNC: Data '${updatedLog.title}' inserted to Cloud (ID: $insertedId)",
              source: "log_controller.dart",
              level: 2,
            );
          }
        } else {
          // Data sudah ter-sync, lakukan update normal
          await MongoService().updateLog(updatedLog);
          await LogHelper.writeLog(
            "SYNC: Update '${oldLog.title}' synced to Cloud",
            source: "log_controller.dart",
            level: 2,
          );
        }
      } catch (e) {
        await LogHelper.writeLog(
          "SYNC: Background sync failed (data safe in Hive) - $e",
          source: "log_controller.dart",
          level: 1,
        );
      }
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Gagal update di Hive - $e",
        source: "log_controller.dart",
        level: 1,
      );
      rethrow;
    }
  }

  // 3. Menghapus data (Offline-First: Hive → MongoDB)
  Future<void> removeLog(
    int index, {
    Map<String, String>? currentUser, // Optional for backward compatibility
  }) async {
    if (_offlineBox == null) {
      throw Exception('Hive not initialized yet. Please wait...');
    }

    final currentLogs = List<LogModel>.from(logsNotifier.value);
    final targetLog = currentLogs[index];

    // Task 5: SOVEREIGNTY - Only owner can delete (ignore role)
    if (currentUser != null) {
      final bool isOwner = targetLog.authorId == currentUser['uid'];
      if (!isOwner) {
        throw Exception(
          'SOVEREIGNTY: Hanya pemilik catatan yang boleh menghapus!',
        );
      }
    }

    try {
      // STEP 1: Delete from Hive FIRST
      await _offlineBox!.deleteAt(index);
      _loadFromHive(); // Update UI immediately

      await LogHelper.writeLog(
        "OFFLINE-FIRST: Data '${targetLog.title}' deleted from Hive",
        source: "log_controller.dart",
        level: 2,
      );

      // STEP 2: Background sync to MongoDB
      if (targetLog.id != null) {
        try {
          await MongoService().deleteLog(ObjectId.fromHexString(targetLog.id!));
          await LogHelper.writeLog(
            "SYNC: Delete '${targetLog.title}' synced to Cloud",
            source: "log_controller.dart",
            level: 2,
          );
        } catch (e) {
          await LogHelper.writeLog(
            "SYNC: Background sync failed (data deleted locally) - $e",
            source: "log_controller.dart",
            level: 1,
          );
        }
      }
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Gagal hapus dari Hive - $e",
        source: "log_controller.dart",
        level: 1,
      );
      rethrow;
    }
  }

  // 4. Load data dengan Hybrid Strategy (Hive First + Cloud Sync)
  // Modul 5: Offline-First dengan Team Isolation
  Future<void> loadFromDisk({String? teamId}) async {
    try {
      await LogHelper.writeLog(
        "Controller: Loading data (Hybrid Strategy)${teamId != null ? ' for Team: $teamId' : ''}...",
        source: "log_controller.dart",
        level: 3,
      );

      // STEP 1: Load from Hive FIRST (Instant, no network wait)
      _loadFromHive();
      await LogHelper.writeLog(
        "Controller: Loaded ${_offlineBox?.length ?? 0} logs from Hive",
        source: "log_controller.dart",
        level: 3,
      );

      // STEP 2: Background sync from Cloud (non-blocking)
      try {
        final cloudData = await MongoService().getLogs(teamId: teamId);

        // STEP 3: Smart Merge Strategy - Preserve unsynced local data
        // Jangan hapus semua! Data dengan id==null (unsynced) harus dipertahankan

        // 3a. Identifikasi data lokal yang belum ter-sync (id == null)
        final unsyncedLocalData = _offlineBox!.values
            .where((log) => log.id == null)
            .toList();

        await LogHelper.writeLog(
          "SYNC: Found ${unsyncedLocalData.length} unsynced local items",
          source: "log_controller.dart",
          level: 3,
        );

        // 3b. Clear Hive (akan diisi ulang dengan merged data)
        await _offlineBox!.clear();

        // 3c. Tambahkan data dari cloud terlebih dahulu
        await _offlineBox!.addAll(cloudData);

        // 3d. Re-add unsynced local data (PENTING: ini yang membuat data offline tidak hilang!)
        for (var unsyncedLog in unsyncedLocalData) {
          // Try sync to cloud first
          try {
            await MongoService().insertLog(unsyncedLog);
            await LogHelper.writeLog(
              "SYNC: Unsynced data '${unsyncedLog.title}' successfully synced to Cloud",
              source: "log_controller.dart",
              level: 2,
            );
            // Setelah berhasil sync, reload dari cloud untuk dapat ID
            final updatedCloudData = await MongoService().getLogs(
              teamId: teamId,
            );
            await _offlineBox!.clear();
            await _offlineBox!.addAll(updatedCloudData);
          } catch (e) {
            // Jika masih gagal sync, keep di Hive dengan id==null
            await _offlineBox!.add(unsyncedLog);
            await LogHelper.writeLog(
              "SYNC: Unsynced data '${unsyncedLog.title}' kept in Hive (sync failed) - $e",
              source: "log_controller.dart",
              level: 1,
            );
          }
        }

        _loadFromHive(); // Refresh UI dengan merged data

        await LogHelper.writeLog(
          "SYNC: Merge complete (${_offlineBox?.length ?? 0} total logs)",
          source: "log_controller.dart",
          level: 2,
        );
      } catch (e) {
        // Gagal sync dari Cloud? No problem, pakai data lokal
        await LogHelper.writeLog(
          "SYNC: Cloud sync failed, using local data - $e",
          source: "log_controller.dart",
          level: 1,
        );
      }
    } catch (e) {
      await LogHelper.writeLog(
        "Controller: Error loading data - $e",
        source: "log_controller.dart",
        level: 1,
      );
      // Set ke empty list jika semua gagal
      logsNotifier.value = [];
      filteredLogsNotifier.value = [];
    }
  }

  // ========== TASK 4: SYNC MANAGER ==========

  /// Task 4: Batch sync all pending (unsynced) logs to cloud
  /// Returns: (successCount, failCount)
  Future<(int, int)> syncPendingLogs({String? teamId}) async {
    syncStatusNotifier.value = SyncStatus.syncing;

    await LogHelper.writeLog(
      "SYNC MANAGER: Starting batch sync for pending logs...",
      source: "log_controller.dart",
      level: 2,
    );

    // Find all logs with id==null (unsynced)
    final unsyncedLogs = _offlineBox!.values
        .where((log) => log.id == null)
        .toList();

    if (unsyncedLogs.isEmpty) {
      await LogHelper.writeLog(
        "SYNC MANAGER: No pending logs to sync",
        source: "log_controller.dart",
        level: 3,
      );
      syncStatusNotifier.value = SyncStatus.idle;
      return (0, 0);
    }

    await LogHelper.writeLog(
      "SYNC MANAGER: Found ${unsyncedLogs.length} pending logs",
      source: "log_controller.dart",
      level: 2,
    );

    int successCount = 0;
    int failCount = 0;

    for (var unsyncedLog in unsyncedLogs) {
      try {
        // Insert to MongoDB
        final insertedId = await MongoService().insertLog(unsyncedLog);

        if (insertedId != null) {
          // Update Hive with MongoDB ID
          final logWithId = LogModel(
            id: insertedId,
            title: unsyncedLog.title,
            description: unsyncedLog.description,
            date: unsyncedLog.date,
            authorId: unsyncedLog.authorId,
            teamId: unsyncedLog.teamId,
          );

          // Find and update in Hive
          final hiveIndex = _offlineBox!.values.toList().indexWhere(
            (log) =>
                log.title == unsyncedLog.title &&
                log.date == unsyncedLog.date &&
                log.id == null,
          );

          if (hiveIndex != -1) {
            await _offlineBox!.putAt(hiveIndex, logWithId);
          }

          successCount++;

          await LogHelper.writeLog(
            "SYNC MANAGER: ✅ '${unsyncedLog.title}' synced (ID: $insertedId)",
            source: "log_controller.dart",
            level: 2,
          );
        }
      } catch (e) {
        failCount++;
        await LogHelper.writeLog(
          "SYNC MANAGER: ❌ '${unsyncedLog.title}' failed - $e",
          source: "log_controller.dart",
          level: 1,
        );
      }
    }

    // Refresh UI
    _loadFromHive();

    await LogHelper.writeLog(
      "SYNC MANAGER: Complete - $successCount synced, $failCount failed",
      source: "log_controller.dart",
      level: 2,
    );

    syncStatusNotifier.value = successCount > 0
        ? SyncStatus.success
        : SyncStatus.failed;

    // Reset to idle after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      syncStatusNotifier.value = SyncStatus.idle;
    });

    return (successCount, failCount);
  }

  /// Task 4: Get count of unsynced logs (for UI indicator)
  int get unsyncedCount =>
      _offlineBox?.values.where((log) => log.id == null).length ?? 0;

  /// Task 4: Check if there are pending logs to sync
  bool get hasPendingSync => unsyncedCount > 0;
}

// ========== TASK 4: SYNC STATUS ENUM ==========

/// Task 4: Enum untuk tracking status sinkronisasi
enum SyncStatus {
  idle, // Tidak ada proses sync
  syncing, // Sedang sync
  success, // Sync berhasil
  failed, // Sync gagal
}
