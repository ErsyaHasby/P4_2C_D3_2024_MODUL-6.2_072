// LoginView - Bertanggung jawab HANYA untuk UI/Tampilan
// Prinsip Single Responsibility: Tidak ada logic validasi di sini!

import 'package:flutter/material.dart';
// Import Controller milik sendiri (dari folder auth)
import 'package:logbook_app_modul5/features/auth/login_controller.dart';
// Import View dari fitur lain (Logbook) untuk navigasi
import 'package:logbook_app_modul5/features/logbook/log_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  // Inisialisasi Otak (Controller untuk Logic)
  final LoginController _controller = LoginController();

  // Controller untuk mengambil input dari TextField
  // TextEditingController = Alat untuk mengontrol TextField
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  // State untuk show/hide password
  bool _obscurePassword = true;

  // TASK 2: Security - Tracking login attempts
  int _loginAttempts = 0;
  bool _isButtonDisabled = false;
  int _remainingSeconds = 10;

  // Fungsi untuk handle tombol Login
  void _handleLogin() {
    // TASK 2: Cek apakah tombol sedang disabled
    if (_isButtonDisabled) {
      return; // Jangan lakukan apa-apa jika disabled
    }

    // Ambil nilai dari TextField
    String user = _userController.text;
    String pass = _passController.text;

    // TASK 2: Validasi input kosong - Enhanced
    if (user.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Username dan Password tidak boleh kosong!"),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Panggil fungsi login dari Controller (Logic terpisah!)
    // Modul 5: Mengembalikan Map user data (bukan boolean)
    final userData = _controller.login(user, pass);

    if (userData != null) {
      // TASK 2: Reset login attempts saat berhasil
      setState(() {
        _loginAttempts = 0;
      });

      // Login berhasil - Navigasi ke LogView dengan user data lengkap
      // pushReplacement = Ganti halaman (tidak bisa back)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          // Modul 5: Pass user data untuk RBAC (role, uid, teamId)
          builder: (context) => LogView(currentUser: userData),
        ),
      );
    } else {
      // TASK 2: Increment login attempts
      setState(() {
        _loginAttempts++;
      });

      // TASK 2: Cek apakah sudah 3x gagal
      if (_loginAttempts >= 3) {
        _disableButtonTemporarily();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "🔒 Terlalu banyak percobaan gagal! Tombol login dinonaktifkan selama 10 detik.",
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        // Pesan error dengan informasi sisa percobaan
        int remainingAttempts = 3 - _loginAttempts;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Login Gagal! Sisa percobaan: $remainingAttempts"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // TASK 2: Fungsi untuk disable button selama 10 detik
  void _disableButtonTemporarily() {
    setState(() {
      _isButtonDisabled = true;
      _remainingSeconds = 10;
    });

    // Timer countdown setiap 1 detik
    Future.delayed(const Duration(seconds: 1), _countdown);
  }

  // TASK 2: Fungsi rekursif untuk countdown
  void _countdown() {
    if (_remainingSeconds > 0) {
      setState(() {
        _remainingSeconds--;
      });
      Future.delayed(const Duration(seconds: 1), _countdown);
    } else {
      // Setelah 10 detik, enable button dan reset attempts
      setState(() {
        _isButtonDisabled = false;
        _loginAttempts = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Tombol login sudah aktif kembali!"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Cleanup: Hapus controller saat widget di-dispose
  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  // TASK 2: Helper widget untuk menampilkan credential row
  Widget _buildCredentialRow(String username, String password) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.person, size: 16, color: Colors.indigo),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "$username / $password",
              style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login Gatekeeper"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // Icon Login
              const Icon(Icons.lock_person, size: 100, color: Colors.indigo),
              const SizedBox(height: 20),

              // Judul
              const Text(
                "Selamat Datang!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(height: 10),

              const Text(
                "Silakan login untuk melanjutkan",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),

              // TextField Username
              TextField(
                controller: _userController,
                decoration: InputDecoration(
                  labelText: "Username",
                  hintText: "Masukkan username",
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.indigo,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // TextField Password
              TextField(
                controller: _passController,
                obscureText: _obscurePassword, // Menyembunyikan teks password
                decoration: InputDecoration(
                  labelText: "Password",
                  hintText: "Masukkan password",
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.indigo,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // TASK 2: Tombol Login dengan status disabled
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isButtonDisabled ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isButtonDisabled
                        ? Colors.grey
                        : Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: Colors.grey,
                    disabledForegroundColor: Colors.white70,
                  ),
                  child: Text(
                    _isButtonDisabled
                        ? "Tunggu $_remainingSeconds detik..."
                        : "Masuk",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // TASK 2: Info kredensial - Multiple Users
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.indigo.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.indigo),
                        SizedBox(width: 10),
                        Text(
                          "Akun yang Tersedia:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildCredentialRow("admin", "123"),
                    _buildCredentialRow("user", "user123"),
                    _buildCredentialRow("guest", "guest"),
                    _buildCredentialRow("dosen", "polban2024"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
