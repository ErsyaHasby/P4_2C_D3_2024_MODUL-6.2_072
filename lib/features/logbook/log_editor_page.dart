import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:logbook_app_modul5/features/logbook/models/log_model.dart';
import 'package:logbook_app_modul5/features/logbook/log_controller.dart';

/// LogEditorPage - Dedicated Markdown Editor dengan Preview
///
/// Konsep: Full-page navigation untuk content-heavy input
/// Logika: Tabbed interface (Editor & Preview) untuk real-time Markdown rendering
/// Tujuan: Professional documentation experience
class LogEditorPage extends StatefulWidget {
  final LogModel? log; // Null jika tambah baru, ada value jika edit
  final int? index; // Index log dalam list (untuk update)
  final LogController controller;
  final Map<String, String> currentUser; // User data dengan role, uid, teamId

  const LogEditorPage({
    super.key,
    this.log,
    this.index,
    required this.controller,
    required this.currentUser,
  });

  @override
  State<LogEditorPage> createState() => _LogEditorPageState();
}

class _LogEditorPageState extends State<LogEditorPage> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  bool _isSaving = false;
  late bool _isPublic; // Task 5: Privacy control state
  late String _selectedCategory; // Homework: Category selection

  @override
  void initState() {
    super.initState();
    // Pre-fill jika mode edit
    _titleController = TextEditingController(text: widget.log?.title ?? '');
    _descController = TextEditingController(
      text: widget.log?.description ?? '',
    );
    // Task 5: Initialize privacy state (default: private)
    _isPublic = widget.log?.isPublic ?? false;
    // Homework: Initialize category (default: Software)
    _selectedCategory = widget.log?.category ?? 'Software';

    // PENTING: Listener agar Pratinjau terupdate otomatis
    _descController.addListener(() {
      setState(() {}); // Trigger rebuild untuk update preview
    });
  }

  /// Save Logic - Hybrid Offline-First
  void _save() async {
    // Validasi input
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Judul tidak boleh kosong!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (widget.log == null) {
        // MODE: Tambah Baru
        await widget.controller.addLog(
          _titleController.text.trim(),
          _descController.text.trim(),
          authorId: widget.currentUser['uid']!,
          teamId: widget.currentUser['teamId']!,
          isPublic: _isPublic, // Task 5: Pass privacy setting
          category: _selectedCategory, // Homework: Pass category
        );
      } else {
        // MODE: Update (dengan SOVEREIGNTY validation)
        await widget.controller.updateLog(
          widget.index!,
          _titleController.text.trim(),
          _descController.text.trim(),
          currentUser: widget.currentUser,
          isPublic: _isPublic, // Task 5: Pass privacy setting
          category: _selectedCategory, // Homework: Pass category
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data tersimpan!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context); // Kembali ke log_view
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    // WAJIB: Bersihkan controller agar tidak memory leak
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.log == null ? "Catatan Baru" : "Edit Catatan"),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.edit), text: "Editor"),
              Tab(icon: Icon(Icons.visibility), text: "Pratinjau"),
            ],
          ),
          actions: [
            // Tombol Save dengan loading indicator
            IconButton(
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save),
              onPressed: _isSaving ? null : _save,
              tooltip: 'Simpan',
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // ========== TAB 1: EDITOR ==========
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Task 5: Public/Private Toggle
                  Card(
                    color: _isPublic
                        ? Colors.green.shade50
                        : Colors.grey.shade50,
                    child: SwitchListTile(
                      title: Text(
                        _isPublic
                            ? '🌍 Publik (Tim bisa lihat)'
                            : '🔒 Privat (Hanya saya)',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        _isPublic
                            ? 'Catatan ini terlihat oleh tim, tapi tidak bisa diedit'
                            : 'Catatan ini hanya terlihat oleh Anda',
                        style: const TextStyle(fontSize: 12),
                      ),
                      value: _isPublic,
                      onChanged: (bool value) {
                        setState(() {
                          _isPublic = value;
                        });
                      },
                      activeColor: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Homework: Category Dropdown
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LogModel.getCategoryIcon(_selectedCategory),
                            color: LogModel.getCategoryColor(_selectedCategory),
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Kategori Proyek',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                DropdownButton<String>(
                                  value: _selectedCategory,
                                  isExpanded: true,
                                  underline: Container(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: LogModel.getCategoryColor(
                                      _selectedCategory,
                                    ),
                                  ),
                                  items:
                                      [
                                        'Mechanical',
                                        'Electronic',
                                        'Software',
                                      ].map((String category) {
                                        return DropdownMenuItem<String>(
                                          value: category,
                                          child: Row(
                                            children: [
                                              Icon(
                                                LogModel.getCategoryIcon(
                                                  category,
                                                ),
                                                size: 20,
                                                color:
                                                    LogModel.getCategoryColor(
                                                      category,
                                                    ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(category),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        _selectedCategory = newValue;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Input Title
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      hintText: "📌 Judul Catatan",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Markdown Hint
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '💡 Tips: Gunakan Markdown - # Heading, **Bold**, *Italic*, `Code`',
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Markdown Editor (Expandable TextField)
                  Expanded(
                    child: TextField(
                      controller: _descController,
                      maxLines: null,
                      expands: true,
                      keyboardType: TextInputType.multiline,
                      textAlignVertical: TextAlignVertical.top,
                      style: const TextStyle(
                        fontFamily: 'Courier', // Monospace untuk code
                        fontSize: 14,
                      ),
                      decoration: const InputDecoration(
                        hintText:
                            "# Laporan Praktikum\n\n## Tujuan\n- Item 1\n- Item 2\n\n**Kesimpulan:** ...",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ========== TAB 2: PREVIEW ==========
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: _descController.text.trim().isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.preview, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'Pratinjau akan muncul di sini',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : Markdown(
                      data: _descController.text,
                      selectable: true, // Bisa copy text
                      styleSheet: MarkdownStyleSheet(
                        h1: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        h2: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        p: const TextStyle(fontSize: 14),
                        code: TextStyle(
                          backgroundColor: Colors.grey.shade200,
                          fontFamily: 'Courier',
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
