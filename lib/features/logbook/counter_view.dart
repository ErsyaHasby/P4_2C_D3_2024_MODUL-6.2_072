import 'package:flutter/material.dart';
import 'package:logbook_app_modul5/features/logbook/counter_controller.dart';
import 'package:logbook_app_modul5/features/onboarding/onboarding_view.dart';

class CounterView extends StatefulWidget {
  // Tambahkan variabel final untuk menampung username
  final String username;

  // Update Constructor agar mewajibkan (required) kiriman username
  const CounterView({super.key, required this.username});

  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  final CounterController _controller = CounterController();

  // TASK 3: Loading state untuk data persistence
  bool _isLoading = true;

  // TASK 3 & HOMEWORK: Load data saat widget pertama kali dibuat
  @override
  void initState() {
    super.initState();
    // HOMEWORK: Set current user di controller
    _controller.setCurrentUser(widget.username);
    _loadData();
  }

  // TASK 3 & HOMEWORK: Fungsi untuk load data dari SharedPreferences (per-user)
  Future<void> _loadData() async {
    await _controller.loadAllData(widget.username);
    setState(() {
      _isLoading = false; // Selesai loading
    });
  }

  // TASK 3: Fungsi untuk clear saved data (testing purposes)
  void _showClearDataConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Data Tersimpan?'),
          content: const Text(
            'Ini akan menghapus semua data counter dan history yang tersimpan. Aksi ini tidak dapat dibatalkan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _controller.clearAllData(widget.username);
                setState(() {
                  // Refresh UI setelah clear
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Data Anda berhasil dihapus!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // Fungsi untuk menampilkan dialog konfirmasi logout
  void _handleLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Logout'),
          content: const Text(
            'Apakah Anda yakin ingin keluar? Data counter Anda sudah tersimpan otomatis.',
          ),
          actions: [
            // Tombol Batal
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Menutup dialog saja
              },
              child: const Text('Batal'),
            ),
            // Tombol Ya, Logout
            TextButton(
              onPressed: () {
                // Menutup dialog
                Navigator.pop(context);

                // Navigasi kembali ke Onboarding (Membersihkan Stack)
                // pushAndRemoveUntil: Push halaman baru DAN hapus semua halaman sebelumnya
                // (route) => false: Hapus SEMUA halaman dari stack
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OnboardingView(),
                  ),
                  (route) => false, // false = hapus semua route
                );
              },
              child: const Text(
                'Ya, Keluar',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  // Fungsi untuk menampilkan dialog konfirmasi reset
  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Reset'),
          content: const Text(
            'Apakah Anda yakin ingin mereset counter ke 0? Data tidak dapat dikembalikan.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog tanpa reset
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
                setState(() {
                  _controller.reset(); // Lakukan reset
                });
                // Tampilkan SnackBar konfirmasi
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Counter berhasil direset ke 0!'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Ya, Reset'),
            ),
          ],
        );
      },
    );
  }

  // Fungsi untuk mendapatkan warna berdasarkan tipe aktivitas
  Color _getHistoryColor(String type) {
    switch (type) {
      case 'add':
        return Colors.green.shade100;
      case 'subtract':
        return Colors.red.shade100;
      case 'reset':
        return Colors.orange.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  // Fungsi untuk mendapatkan icon berdasarkan tipe aktivitas
  IconData _getHistoryIcon(String type) {
    switch (type) {
      case 'add':
        return Icons.add_circle;
      case 'subtract':
        return Icons.remove_circle;
      case 'reset':
        return Icons.refresh;
      default:
        return Icons.history;
    }
  }

  // Fungsi untuk mendapatkan warna icon berdasarkan tipe aktivitas
  Color _getIconColor(String type) {
    switch (type) {
      case 'add':
        return Colors.green;
      case 'subtract':
        return Colors.red;
      case 'reset':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // TASK 3 (HOMEWORK): Fungsi untuk mendapatkan greeting berdasarkan waktu
  String _getTimeGreeting() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 11) {
      return "Selamat Pagi";
    } else if (hour >= 11 && hour < 15) {
      return "Selamat Siang";
    } else if (hour >= 15 && hour < 18) {
      return "Selamat Sore";
    } else {
      return "Selamat Malam";
    }
  }

  // TASK 3 (HOMEWORK): Fungsi untuk mendapatkan icon berdasarkan waktu
  IconData _getTimeIcon() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 11) {
      return Icons.wb_sunny; // Matahari pagi
    } else if (hour >= 11 && hour < 15) {
      return Icons.wb_sunny_outlined; // Matahari terik
    } else if (hour >= 15 && hour < 18) {
      return Icons.wb_twilight; // Senja
    } else {
      return Icons.nightlight_round; // Malam
    }
  }

  // TASK 3 (HOMEWORK): Fungsi untuk mendapatkan warna banner berdasarkan waktu
  Color _getTimeBannerColor() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 11) {
      return Colors.orange.shade50; // Pagi: Orange lembut
    } else if (hour >= 11 && hour < 15) {
      return Colors.blue.shade50; // Siang: Biru cerah
    } else if (hour >= 15 && hour < 18) {
      return Colors.deepOrange.shade50; // Sore: Orange kemerahan
    } else {
      return Colors.indigo.shade50; // Malam: Indigo gelap
    }
  }

  Color _getTimeIconColor() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 11) {
      return Colors.orange;
    } else if (hour >= 11 && hour < 15) {
      return Colors.blue;
    } else if (hour >= 15 && hour < 18) {
      return Colors.deepOrange;
    } else {
      return Colors.indigo;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Gunakan widget.username untuk menampilkan data dari kelas utama
        title: Text("LogBook: ${widget.username}"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        // Tambahkan tombol logout di AppBar
        actions: [
          // TASK 3: Tombol untuk clear saved data (untuk testing)
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') {
                _showClearDataConfirmation();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Hapus Data Tersimpan'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              // TASK 3: Loading indicator saat data sedang di-load
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text(
                    'Memuat data...',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // TASK 3 (HOMEWORK): Welcome Banner berdasarkan waktu
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getTimeBannerColor(),
                          _getTimeBannerColor().withOpacity(0.5),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Icon waktu
                        Icon(
                          _getTimeIcon(),
                          size: 48,
                          color: _getTimeIconColor(),
                        ),
                        const SizedBox(width: 16),
                        // Greeting text
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getTimeGreeting(),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.username,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // TASK 3: Info bahwa data auto-saved
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_done, size: 16, color: Colors.green),
                        SizedBox(width: 6),
                        Text(
                          'Data tersimpan otomatis',
                          style: TextStyle(fontSize: 12, color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text("Total Hitungan:", style: TextStyle(fontSize: 18)),
                  Text(
                    '${_controller.value}',
                    style: const TextStyle(
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Text("Atur Step:"),
                  Slider(
                    value: _controller.currentStep,
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: _controller.currentStep.round().toString(),
                    onChanged: (double value) {
                      setState(() {
                        _controller.setCurrentStep(value);
                      });
                    },
                  ),
                  Text(
                    'Step saat ini: ${_controller.step}',
                    style: const TextStyle(fontSize: 16),
                  ),

                  const SizedBox(height: 20),

                  // Tombol kontrol
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Tombol Decrement
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                setState(() => _controller.decrement()),
                            icon: const Icon(Icons.remove, size: 18),
                            label: const Text('Kurang'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Tombol Reset
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ElevatedButton.icon(
                            onPressed:
                                _showResetConfirmation, // Panggil dialog konfirmasi
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Reset'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Tombol Increment
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                setState(() => _controller.increment()),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Tambah'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                  const Divider(thickness: 2),

                  // Bagian Riwayat
                  const Text(
                    "Riwayat Aktivitas (5 Terakhir):",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // Tampilkan riwayat menggunakan Expanded dan ListView
                  Expanded(
                    child: _controller.history.isEmpty
                        ? const Center(
                            child: Text(
                              'Belum ada aktivitas',
                              style: TextStyle(
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _controller.history.length,
                            itemBuilder: (context, index) {
                              // Tampilkan dari yang terbaru (index terbalik)
                              final reversedIndex =
                                  _controller.history.length - 1 - index;
                              final historyItem =
                                  _controller.history[reversedIndex];

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                elevation: 2,
                                color: _getHistoryColor(historyItem.type),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: _getIconColor(
                                      historyItem.type,
                                    ),
                                    child: Icon(
                                      _getHistoryIcon(historyItem.type),
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    historyItem.text,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  trailing: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: _getIconColor(historyItem.type),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ), // End of Padding (when not loading)
    );
  }
}
