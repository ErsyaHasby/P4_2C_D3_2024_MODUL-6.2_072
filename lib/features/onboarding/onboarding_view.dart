import 'package:flutter/material.dart';
import 'package:logbook_app_modul5/features/auth/login_view.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  // State management sederhana - hanya menggunakan int untuk tracking step
  int step = 1;

  // Fungsi untuk handle tombol Next
  void _handleNext() {
    setState(() {
      step++; // Increment step

      // Jika step > 3, pindah ke LoginView
      if (step > 3) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginView()),
        );
      }
    });
  }

  // Fungsi untuk mendapatkan teks sesuai step
  String _getStepTitle() {
    switch (step) {
      case 1:
        return "Selamat Datang! 👋";
      case 2:
        return "Kelola Counter Cerdas 📊";
      case 3:
        return "Siap Memulai Perjalanan? 🚀";
      default:
        return "";
    }
  }

  // Fungsi untuk mendapatkan deskripsi sesuai step
  String _getStepDescription() {
    switch (step) {
      case 1:
        return "LogBook App membantu Anda mencatat dan mengelola hitungan dengan riwayat lengkap yang tersimpan otomatis. Data Anda aman dan tidak akan hilang!";
      case 2:
        return "Tambah, kurangi, atau reset counter dengan mudah. Atur step counter sesuai kebutuhan dan lihat riwayat aktivitas Anda secara real-time!";
      case 3:
        return "Mulai petualangan Anda! Login sekarang dan rasakan kemudahan mengelola counter dengan fitur-fitur canggih yang kami sediakan.";
      default:
        return "";
    }
  }

  // Fungsi untuk mendapatkan icon sesuai step
  IconData _getStepIcon() {
    switch (step) {
      case 1:
        return Icons.book;
      case 2:
        return Icons.assignment;
      case 3:
        return Icons.login;
      default:
        return Icons.help;
    }
  }

  // Fungsi untuk mendapatkan path gambar sesuai step
  String _getStepImage() {
    switch (step) {
      case 1:
        return 'assets/images/onboarding1.png';
      case 2:
        return 'assets/images/onboarding2.png';
      case 3:
        return 'assets/images/onboarding3.png';
      default:
        return '';
    }
  }

  // Widget untuk menampilkan gambar atau icon sebagai fallback
  Widget _buildStepImage() {
    // Coba tampilkan gambar, jika error gunakan icon
    return Image.asset(
      _getStepImage(),
      width: 250,
      height: 250,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Jika gambar tidak ditemukan, tampilkan icon
        return Icon(_getStepIcon(), size: 120, color: Colors.indigo);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Gambar atau Icon sebagai fallback
              _buildStepImage(),
              const SizedBox(height: 40),

              // Title
              Text(
                _getStepTitle(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(height: 20),

              // Description
              Text(
                _getStepDescription(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 60),

              // Step indicator (dots)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDot(1),
                  const SizedBox(width: 10),
                  _buildDot(2),
                  const SizedBox(width: 10),
                  _buildDot(3),
                ],
              ),
              const SizedBox(height: 40),

              // Tombol Next
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _handleNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    step == 3 ? "Mulai" : "Lanjut",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Step counter text
              Text(
                "Step $step dari 3",
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget helper untuk membuat dot indicator
  Widget _buildDot(int dotStep) {
    return Container(
      width: step == dotStep ? 24 : 12,
      height: 12,
      decoration: BoxDecoration(
        color: step == dotStep ? Colors.indigo : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
