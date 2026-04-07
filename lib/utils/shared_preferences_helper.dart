// Contoh implementasi Shared Preferences Helper
// File ini adalah CONTOH untuk dipelajari
// Akan digunakan nanti untuk menyimpan data seperti: sudah onboarding atau belum

import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHelper {
  // Singleton pattern - hanya ada 1 instance
  static final SharedPreferencesHelper _instance =
      SharedPreferencesHelper._internal();
  factory SharedPreferencesHelper() => _instance;
  SharedPreferencesHelper._internal();

  // Keys untuk menyimpan data
  static const String _keyHasSeenOnboarding = 'has_seen_onboarding';
  static const String _keyUsername = 'username';
  static const String _keyCounterValue = 'counter_value';

  // ============================================
  // CONTOH 1: Menyimpan & Membaca Boolean
  // ============================================

  // Simpan status: user sudah lihat onboarding atau belum
  Future<void> setHasSeenOnboarding(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasSeenOnboarding, value);
  }

  // Baca status: sudah pernah lihat onboarding?
  Future<bool> getHasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHasSeenOnboarding) ?? false; // default: false
  }

  // ============================================
  // CONTOH 2: Menyimpan & Membaca String
  // ============================================

  // Simpan username
  Future<void> saveUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsername, username);
  }

  // Baca username
  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername); // bisa null jika belum disimpan
  }

  // ============================================
  // CONTOH 3: Menyimpan & Membaca Integer
  // ============================================

  // Simpan nilai counter
  Future<void> saveCounterValue(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyCounterValue, value);
  }

  // Baca nilai counter
  Future<int> getCounterValue() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyCounterValue) ?? 0; // default: 0
  }

  // ============================================
  // CONTOH 4: Hapus Data
  // ============================================

  // Hapus data tertentu
  Future<void> removeUsername() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUsername);
  }

  // Hapus SEMUA data
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // ============================================
  // CONTOH 5: Cek apakah key ada
  // ============================================

  Future<bool> hasKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(key);
  }
}

// ============================================
// CARA PENGGUNAAN:
// ============================================

/*
// Di dalam fungsi async (misalnya di LoginView):

final helper = SharedPreferencesHelper();

// MENYIMPAN data
await helper.saveUsername('admin');
await helper.setHasSeenOnboarding(true);
await helper.saveCounterValue(100);

// MEMBACA data
String? username = await helper.getUsername();
bool hasSeenOnboarding = await helper.getHasSeenOnboarding();
int counterValue = await helper.getCounterValue();

print('Username: $username');
print('Sudah onboarding: $hasSeenOnboarding');
print('Counter: $counterValue');

// MENGHAPUS data
await helper.removeUsername();
await helper.clearAll(); // hapus semua
*/

// ============================================
// PENJELASAN:
// ============================================

/*
1. Shared Preferences = Key-Value Storage (seperti dictionary/map)
   
2. Tipe data yang bisa disimpan:
   - bool (true/false)
   - int (angka bulat)
   - double (angka desimal)
   - String (teks)
   - List<String> (list berisi string)

3. Kapan pakai Shared Preferences?
   ✅ Data kecil & sederhana (settings, preferences, token)
   ✅ Data yang perlu persisten (tetap ada setelah app ditutup)
   ✅ Tidak butuh query kompleks
   
4. Kapan TIDAK pakai?
   ❌ Data besar (gunakan SQLite/Hive)
   ❌ Data sensitif (perlu enkripsi)
   ❌ Relational data (gunakan database)

5. Future & async/await:
   - SharedPreferences menggunakan async karena akses storage
   - Harus pakai await untuk menunggu hasil
   - Fungsi yang pakai await harus ditandai async

6. ?? operator (null-aware):
   - prefs.getBool(key) ?? false
   - Artinya: jika null, gunakan false sebagai default
*/
