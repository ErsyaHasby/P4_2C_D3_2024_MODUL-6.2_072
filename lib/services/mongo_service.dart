import 'package:mongo_dart/mongo_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logbook_app_modul5/helpers/log_helper.dart';
import 'package:logbook_app_modul5/features/logbook/models/log_model.dart';

/// MongoService - Menangani koneksi dan operasi database MongoDB
/// Menerapkan Singleton Pattern dan Single Responsibility Principle (SRP)
class MongoService {
  // Singleton Pattern: Hanya ada 1 instance MongoService di seluruh aplikasi
  static final MongoService _instance = MongoService._internal();

  Db? _db;
  DbCollection? _collection;
  final String _source = "mongo_service.dart";

  factory MongoService() => _instance;
  MongoService._internal();

  /// Fungsi Internal untuk memastikan koleksi siap digunakan
  Future<DbCollection> _getSafeCollection() async {
    if (_db == null || !_db!.isConnected || _collection == null) {
      await LogHelper.writeLog(
        "INFO: Koleksi belum siap, mencoba rekoneksi...",
        source: _source,
        level: 3,
      );
      await connect();
    }
    return _collection!;
  }

  /// Inisialisasi Koneksi ke MongoDB Atlas
  Future<void> connect() async {
    try {
      final dbUri = dotenv.env['MONGODB_URI'];
      if (dbUri == null) {
        throw Exception("MONGODB_URI tidak ditemukan di .env");
      }

      _db = await Db.create(dbUri);

      // Timeout 15 detik agar lebih toleran terhadap jaringan seluler
      await _db!.open().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception(
            "Koneksi Timeout. Cek IP Whitelist (0.0.0.0/0) atau Sinyal HP.",
          );
        },
      );

      _collection = _db!.collection('logs');

      await LogHelper.writeLog(
        "DATABASE: Terhubung & Koleksi Siap",
        source: _source,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "DATABASE: Gagal Koneksi - $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  /// READ: Mengambil data dari Cloud (dengan Team Isolation)
  ///
  /// Parameter:
  /// - teamId: Filter data berdasarkan tim (collaborative isolation)
  ///   Jika null, ambil semua data (untuk admin/debugging)
  Future<List<LogModel>> getLogs({String? teamId}) async {
    try {
      final collection = await _getSafeCollection();

      await LogHelper.writeLog(
        "INFO: Fetching data from Cloud${teamId != null ? ' (Team: $teamId)' : ' (All Teams)'}...",
        source: _source,
        level: 3,
      );

      // Query dengan atau tanpa filter teamId
      final query = teamId != null ? where.eq('teamId', teamId) : where;
      final List<Map<String, dynamic>> data = await collection
          .find(query)
          .toList();

      await LogHelper.writeLog(
        "SUCCESS: Fetched ${data.length} logs from Cloud",
        source: _source,
        level: 2,
      );

      return data.map((json) => LogModel.fromMap(json)).toList();
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Fetch Failed - $e",
        source: _source,
        level: 1,
      );
      return [];
    }
  }

  /// CREATE: Menambahkan data baru
  /// Returns: MongoDB generated ObjectId (untuk update Hive box)
  Future<String?> insertLog(LogModel log) async {
    try {
      final collection = await _getSafeCollection();
      final result = await collection.insertOne(log.toMap());

      // Extract inserted ID dari WriteResult
      final insertedId = result.id?.toHexString();

      await LogHelper.writeLog(
        "SUCCESS: Data '${log.title}' Saved to Cloud (ID: $insertedId)",
        source: _source,
        level: 2,
      );

      return insertedId;
    } catch (e) {
      await LogHelper.writeLog(
        "ERROR: Insert Failed - $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  /// UPDATE: Memperbarui data berdasarkan ID
  Future<void> updateLog(LogModel log) async {
    try {
      final collection = await _getSafeCollection();
      if (log.id == null) {
        throw Exception("ID Log tidak ditemukan untuk update");
      }

      await collection.replaceOne(
        where.id(ObjectId.fromHexString(log.id!)),
        log.toMap(),
      );

      await LogHelper.writeLog(
        "DATABASE: Update '${log.title}' Berhasil",
        source: _source,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "DATABASE: Update Gagal - $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  /// DELETE: Menghapus dokumen
  Future<void> deleteLog(ObjectId id) async {
    try {
      final collection = await _getSafeCollection();
      await collection.remove(where.id(id));

      await LogHelper.writeLog(
        "DATABASE: Hapus ID $id Berhasil",
        source: _source,
        level: 2,
      );
    } catch (e) {
      await LogHelper.writeLog(
        "DATABASE: Hapus Gagal - $e",
        source: _source,
        level: 1,
      );
      rethrow;
    }
  }

  /// Method untuk menutup koneksi database
  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      await LogHelper.writeLog(
        "DATABASE: Koneksi ditutup",
        source: _source,
        level: 2,
      );
    }
  }
}
