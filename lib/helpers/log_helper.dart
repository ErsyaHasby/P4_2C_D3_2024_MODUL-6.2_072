import 'dart:developer' as dev;
import 'dart:io'; // Task 4: File operations
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart'; // Task 4: App directory

class LogHelper {
  static Future<void> writeLog(
    String message, {
    String source = "Unknown", // Menandakan file/proses asal
    int level = 2,
  }) async {
    // 1. Filter Konfigurasi (ENV)
    final int configLevel = int.tryParse(dotenv.env['LOG_LEVEL'] ?? '2') ?? 2;
    final String muteList = dotenv.env['LOG_MUTE'] ?? '';

    if (level > configLevel) return;
    if (muteList.split(',').contains(source)) return;

    try {
      // 2. Format Waktu untuk Konsol
      String timestamp = DateFormat('HH:mm:ss').format(DateTime.now());
      String label = _getLabel(level);
      String color = _getColor(level);

      // 3. Output ke VS Code Debug Console (Non-blocking)
      dev.log(message, name: source, time: DateTime.now(), level: level * 100);

      // 4. Output ke Terminal (Agar Bapak bisa lihat di PC saat flutter run)
      // Format: [14:30:05] [INFO] [log_view.dart] -> Database Terhubung
      print('$color[$timestamp][$label][$source] -> $message\x1B[0m');

      // Task 4: 5. Output ke File Log (dd-mm-yyyy.log)
      await _writeToFile(timestamp, label, source, message, level);
    } catch (e) {
      dev.log("Logging failed: $e", name: "SYSTEM", level: 1000);
    }
  }

  // Task 4: Write log to file in /logs folder
  static Future<void> _writeToFile(
    String timestamp,
    String label,
    String source,
    String message,
    int level,
  ) async {
    try {
      // 1. Get app directory (works on Android, iOS, Windows, etc.)
      final directory = await getApplicationDocumentsDirectory();
      final logsDir = Directory('${directory.path}/logs');

      // 2. Create /logs folder if not exists
      if (!await logsDir.exists()) {
        await logsDir.create(recursive: true);
      }

      // 3. Format filename: dd-mm-yyyy.log (Task 4 requirement)
      final dateStr = DateFormat('dd-MM-yyyy').format(DateTime.now());
      final logFile = File('${logsDir.path}/$dateStr.log');

      // 4. Format log entry (without color codes for file)
      final logEntry = '[$timestamp][$label][$source] -> $message\n';

      // 5. Append to file (creates if not exists)
      await logFile.writeAsString(logEntry, mode: FileMode.append, flush: true);
    } catch (e) {
      // Fallback: jika file write gagal, hanya log ke dev console
      dev.log("File logging failed: $e", name: "LogHelper", level: 1000);
    }
  }

  static String _getLabel(int level) {
    switch (level) {
      case 1:
        return "ERROR";
      case 2:
        return "INFO";
      case 3:
        return "VERBOSE";
      default:
        return "LOG";
    }
  }

  static String _getColor(int level) {
    switch (level) {
      case 1:
        return '\x1B[31m'; // Merah
      case 2:
        return '\x1B[32m'; // Hijau
      case 3:
        return '\x1B[34m'; // Biru
      default:
        return '\x1B[0m';
    }
  }
}
