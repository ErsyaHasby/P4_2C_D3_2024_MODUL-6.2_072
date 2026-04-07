// LoginController - Bertanggung jawab HANYA untuk logic validasi
// Prinsip Single Responsibility: Tidak ada UI code di sini!

class LoginController {
  // TASK 2: Database Multiple Users menggunakan Map
  // Key: username, Value: User Data (password, role, teamId)
  // Modul 5: Extended with RBAC data
  final Map<String, Map<String, String>> _users = {
    'admin': {
      'password': '123',
      'role': 'Ketua', // Full access
      'uid': 'uid_admin',
      'teamId': 'MEKTRA_KLP_01',
    },
    'user': {
      'password': 'user123',
      'role': 'Anggota',
      'uid': 'uid_user',
      'teamId': 'MEKTRA_KLP_01',
    },
    'guest': {
      'password': 'guest',
      'role': 'Anggota',
      'uid': 'uid_guest',
      'teamId': 'GUEST_TEAM',
    },
    'dosen': {
      'password': 'polban2024',
      'role': 'Asisten', // Read & Update only
      'uid': 'uid_dosen',
      'teamId': 'DOSEN_TEAM',
    },
  };

  // Fungsi untuk mendapatkan list username yang tersedia
  List<String> getAvailableUsers() {
    return _users.keys.toList();
  }

  // Fungsi pengecekan (Logic-Only) - UPDATED untuk RBAC
  // Output: Map user data jika berhasil, null jika gagal
  Map<String, String>? login(String username, String password) {
    // Validasi menggunakan Map
    if (_users.containsKey(username) &&
        _users[username]!['password'] == password) {
      // Return user data lengkap untuk RBAC
      return {
        'username': username,
        'role': _users[username]!['role']!,
        'uid': _users[username]!['uid']!,
        'teamId': _users[username]!['teamId']!,
      };
    }
    return null; // Login gagal
  }

  // BONUS: Fungsi untuk cek apakah username exist
  bool isUsernameExist(String username) {
    return _users.containsKey(username);
  }

  // Helper: Get role for specific user (for debugging)
  String? getUserRole(String username) {
    return _users[username]?['role'];
  }
}
