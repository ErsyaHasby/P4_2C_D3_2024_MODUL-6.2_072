import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logbook_app_modul5/helpers/log_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

void main() {
  setUpAll(() async {
    // Load .env file untuk LOG_LEVEL configuration
    TestWidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: ".env");
  });

  group('Task 4: Professional Audit Logging Tests', () {
    test('Test 1: Verify LOG_LEVEL dari .env', () async {
      print("=== TEST 1: LOG_LEVEL Configuration ===");

      final logLevel = dotenv.env['LOG_LEVEL'];
      print("LOG_LEVEL from .env: $logLevel");

      expect(logLevel, isNotNull, reason: "LOG_LEVEL harus ada di .env");
      expect(logLevel, equals('3'), reason: "LOG_LEVEL harus 3 untuk Task 4");

      print("✓ LOG_LEVEL configured correctly\n");
    });

    test('Test 2: Verify LOG_MUTE dari .env', () async {
      print("=== TEST 2: LOG_MUTE Configuration ===");

      final logMute = dotenv.env['LOG_MUTE'];
      print("LOG_MUTE from .env: '$logMute'");

      expect(logMute, isNotNull, reason: "LOG_MUTE harus ada di .env");
      expect(logMute, equals(''), reason: "LOG_MUTE default harus kosong");

      print("✓ LOG_MUTE configured correctly\n");
    });

    test('Test 3: Write logs dengan berbagai level', () async {
      print("=== TEST 3: Multi-Level Logging ===");

      await LogHelper.writeLog(
        "Test ERROR message",
        source: "log_helper_test.dart",
        level: 1,
      );
      print("✓ ERROR log written");

      await LogHelper.writeLog(
        "Test INFO message",
        source: "log_helper_test.dart",
        level: 2,
      );
      print("✓ INFO log written");

      await LogHelper.writeLog(
        "Test VERBOSE message",
        source: "log_helper_test.dart",
        level: 3,
      );
      print("✓ VERBOSE log written");

      print("✓ All log levels written successfully\n");
    });

    test('Test 4: Verify file log terbentuk di /logs folder', () async {
      print("=== TEST 4: File Logging Verification ===");

      // Write test log
      await LogHelper.writeLog(
        "Task 4: Testing file logging functionality",
        source: "log_helper_test.dart",
        level: 2,
      );

      // Get app directory
      final directory = await getApplicationDocumentsDirectory();
      final logsDir = Directory('${directory.path}/logs');

      print("Logs directory: ${logsDir.path}");

      // Verify /logs folder exists
      expect(
        await logsDir.exists(),
        isTrue,
        reason: "Folder /logs harus terbentuk otomatis",
      );
      print("✓ /logs folder exists");

      // Verify log file dengan nama dd-mm-yyyy.log exists
      final dateStr = DateFormat('dd-MM-yyyy').format(DateTime.now());
      final logFile = File('${logsDir.path}/$dateStr.log');

      print("Expected log file: $dateStr.log");

      expect(
        await logFile.exists(),
        isTrue,
        reason: "File log dengan format dd-MM-yyyy.log harus terbentuk",
      );
      print("✓ Log file $dateStr.log exists");

      // Read and verify log content
      final content = await logFile.readAsString();

      expect(
        content.contains('Task 4: Testing file logging functionality'),
        isTrue,
        reason: "Log content harus tersimpan di file",
      );
      print("✓ Log content verified");

      expect(
        content.contains('[INFO]'),
        isTrue,
        reason: "Log file harus contain level label",
      );
      print("✓ Log format verified");

      expect(
        content.contains('[log_helper_test.dart]'),
        isTrue,
        reason: "Log file harus contain source file",
      );
      print("✓ Source tracking verified");

      print("\n📄 Log file location: ${logFile.path}");
      print("📝 Log file size: ${await logFile.length()} bytes");
      print("✓ File logging working correctly\n");
    });

    test('Test 5: Verify LOG_LEVEL filtering', () async {
      print("=== TEST 5: LOG_LEVEL Filtering Test ===");

      // Get initial file size
      final directory = await getApplicationDocumentsDirectory();
      final logsDir = Directory('${directory.path}/logs');
      final dateStr = DateFormat('dd-MM-yyyy').format(DateTime.now());
      final logFile = File('${logsDir.path}/$dateStr.log');

      final initialSize = await logFile.length();
      print("Initial log file size: $initialSize bytes");

      // Write log with level 3 (VERBOSE) - should appear
      await LogHelper.writeLog(
        "This is VERBOSE and should appear (level 3)",
        source: "log_helper_test.dart",
        level: 3,
      );

      // Verify file size increased
      final afterSize = await logFile.length();
      expect(
        afterSize,
        greaterThan(initialSize),
        reason: "VERBOSE log (level 3) harus tersimpan karena LOG_LEVEL=3",
      );

      print("After VERBOSE log: $afterSize bytes");
      print("✓ LOG_LEVEL=3 allows VERBOSE logs\n");
    });

    test('Test 6: Verify multiple log entries dengan timestamp', () async {
      print("=== TEST 6: Multiple Entries Test ===");

      // Write 5 log entries
      for (int i = 1; i <= 5; i++) {
        await LogHelper.writeLog(
          "Task 4 Test Entry #$i",
          source: "log_helper_test.dart",
          level: 2,
        );
        await Future.delayed(Duration(milliseconds: 100));
      }

      // Read log file
      final directory = await getApplicationDocumentsDirectory();
      final logsDir = Directory('${directory.path}/logs');
      final dateStr = DateFormat('dd-MM-yyyy').format(DateTime.now());
      final logFile = File('${logsDir.path}/$dateStr.log');

      final content = await logFile.readAsString();
      final lines = content
          .split('\n')
          .where((line) => line.isNotEmpty)
          .toList();

      print("Total log entries in file: ${lines.length}");

      // Verify all 5 entries exist
      for (int i = 1; i <= 5; i++) {
        expect(
          content.contains("Task 4 Test Entry #$i"),
          isTrue,
          reason: "Entry #$i harus tersimpan di file",
        );
      }

      print("✓ All entries saved correctly");
      print("✓ Sequential logging working\n");
    });
  });
}
