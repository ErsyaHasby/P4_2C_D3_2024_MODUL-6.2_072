import 'package:flutter/material.dart';
import 'package:logbook_app_modul5/features/logbook/log_controller.dart';
import 'package:logbook_app_modul5/features/logbook/models/log_model.dart';
import 'package:logbook_app_modul5/features/logbook/log_editor_page.dart';
import 'package:logbook_app_modul5/features/onboarding/onboarding_view.dart';
import 'package:logbook_app_modul5/services/connectivity_service.dart';
import 'package:logbook_app_modul5/utils/access_policy.dart';

/// LogView - Main Logbook Page (Modul 5: Offline-First & RBAC)
///
/// Konsep: Collaborative Logbook dengan Team Isolation & Role-Based Access
/// Logika: ValueListenable + RBAC Gatekeeper + Navigation to dedicated Editor
/// Tujuan: Production-ready collaborative logging system
class LogView extends StatefulWidget {
  final Map<String, String> currentUser; // {username, role, uid, teamId}

  const LogView({super.key, required this.currentUser});

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  late LogController _controller;
  final ConnectivityService _connectivityService = ConnectivityService();
  late AccessPolicy _accessPolicy; // Task 3: RBAC Policy Manager

  // Homework: Search functionality
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _controller = LogController();

    // Initialize AccessPolicy untuk permission management
    _accessPolicy = AccessPolicy.fromUser(widget.currentUser);

    // Homework: Listen to search input
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });

    // Tunggu Hive initialization selesai sebelum load data
    _waitForHiveInit();

    // Start connectivity monitoring for Auto-Sync
    _connectivityService.startMonitoring(
      onConnectivityRestored: () async {
        // Task 4: Auto-sync pending logs when network restored
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🌐 Koneksi pulih! Mensinkronkan data...'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 1),
            ),
          );
        }

        // Batch sync all pending logs
        final (successCount, failCount) = await _controller.syncPendingLogs(
          teamId: widget.currentUser['teamId'],
        );

        // Show result notification
        if (mounted) {
          if (successCount > 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '✅ $successCount data berhasil disinkronkan ke Cloud!',
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          } else if (failCount > 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⚠️ Beberapa data gagal disinkronkan'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }

        // Refresh data from cloud
        _controller.loadFromDisk(teamId: widget.currentUser['teamId']);
      },
    );
  }

  /// Wait for Hive initialization before loading data
  Future<void> _waitForHiveInit() async {
    // Poll sampai Hive initialized
    while (!_controller.isInitialized) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    // Setelah Hive ready, load data
    if (mounted) {
      _controller.loadFromDisk(teamId: widget.currentUser['teamId']);
    }
  }

  @override
  void dispose() {
    _connectivityService.stopMonitoring();
    super.dispose();
  }

  /// Navigate to LogEditorPage (Full-Page Editor dengan Markdown)
  void _goToEditor({LogModel? log, int? index}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogEditorPage(
          log: log,
          index: index,
          controller: _controller,
          currentUser: widget.currentUser,
        ),
      ),
    );
  }

  /// Delete Log dengan Confirmation Dialog - Task 3: Using AccessPolicy
  Future<void> _deleteLog(int index) async {
    final log = _controller.logs[index];

    // Task 3 GATEKEEPER: Security check menggunakan AccessPolicy
    if (!_accessPolicy.canDelete(log.authorId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_accessPolicy.getDeniedMessage('menghapus')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Confirmation Dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Konfirmasi Hapus'),
        content: Text('Yakin ingin menghapus "${log.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _controller.removeLog(index, currentUser: widget.currentUser);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Data berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Gagal menghapus: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Logbook Digital', style: TextStyle(fontSize: 18)),
            Text(
              '${widget.currentUser['username']} • ${widget.currentUser['role']}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          // Task 4: Sync Status & Manual Sync Button
          ValueListenableBuilder<SyncStatus>(
            valueListenable: _controller.syncStatusNotifier,
            builder: (context, syncStatus, child) {
              // Show pending count if there are unsynced logs
              if (_controller.hasPendingSync && syncStatus == SyncStatus.idle) {
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.sync),
                      tooltip: 'Sinkronkan Data',
                      onPressed: () async {
                        final (success, fail) = await _controller
                            .syncPendingLogs(
                              teamId: widget.currentUser['teamId'],
                            );
                        if (mounted && success > 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '✅ $success data berhasil disinkronkan!',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.orange,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${_controller.unsyncedCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }

              // Show syncing indicator
              if (syncStatus == SyncStatus.syncing) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                );
              }

              // Show success checkmark briefly
              if (syncStatus == SyncStatus.success) {
                return const Icon(
                  Icons.check_circle,
                  color: Colors.greenAccent,
                );
              }

              return const SizedBox.shrink();
            },
          ),

          // Info RBAC - Task 3: Display AccessPolicy information
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('🔐 Hak Akses Anda'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_accessPolicy.accessLevelDescription),
                      const SizedBox(height: 8),
                      Text('Team: ${widget.currentUser['teamId']}'),
                      const SizedBox(height: 12),
                      const Text(
                        'Permissions:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ..._accessPolicy.permissions.map(
                        (perm) => Text('✅ $perm'),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
          // Logout Button
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Konfirmasi Logout'),
                  content: const Text('Yakin ingin keluar?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const OnboardingView(),
                          ),
                          (route) => false,
                        );
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Keluar'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),

      // Body: ValueListenableBuilder untuk Reactive UI
      body: Column(
        children: [
          // Homework: Search TextField
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '🔍 Cari berdasarkan judul atau deskripsi...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
          ),

          // Main content
          Expanded(
            child: ValueListenableBuilder<List<LogModel>>(
              valueListenable: _controller.logsNotifier,
              builder: (context, allLogs, child) {
                // Task 5: PRIVACY FILTER + TEAM ISOLATION (Kriteria UX #2)
                // Show only: (1) logs owned by current user OR
                //            (2) public logs FROM SAME TEAM
                final visibleLogs = allLogs.where((log) {
                  final bool isOwner =
                      log.authorId == widget.currentUser['uid'];
                  final bool isPublicLog = log.isPublic == true;
                  final bool isSameTeam =
                      log.teamId == widget.currentUser['teamId'];

                  // Owner ALWAYS sees their own logs
                  // Public logs ONLY visible to same team
                  return isOwner || (isPublicLog && isSameTeam);
                }).toList();

                // Homework: SEARCH FILTER
                final filteredLogs = _searchQuery.isEmpty
                    ? visibleLogs
                    : visibleLogs.where((log) {
                        return log.title.toLowerCase().contains(_searchQuery) ||
                            log.description.toLowerCase().contains(
                              _searchQuery,
                            );
                      }).toList();

                // Homework: Enhanced Empty State
                if (filteredLogs.isEmpty) {
                  if (_searchQuery.isNotEmpty) {
                    // No search results
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 100,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Tidak ada hasil untuk "$_searchQuery"',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Coba kata kunci lain',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  // No data at all - Enhanced empty state
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.rocket_launch,
                          size: 120,
                          color: Colors.indigo.shade200,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Belum ada aktivitas hari ini?',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Mulai catat kemajuan proyek Anda!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => _goToEditor(),
                          icon: const Icon(Icons.add),
                          label: const Text('Buat Catatan Pertama'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // List of Logs
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredLogs.length,
                  itemBuilder: (context, index) {
                    final log = filteredLogs[index];

                    // Task 5: SOVEREIGNTY - Only owner can edit/delete (ignore role)
                    final bool isOwner =
                        log.authorId == widget.currentUser['uid'];
                    // Task 3 RBAC is overridden by Task 5 sovereignty requirement
                    final canEdit = isOwner; // Hanya pemilik, bukan role-based
                    final canDelete =
                        isOwner; // Hanya pemilik, bukan role-based

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      // Homework: Color coding based on category
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: LogModel.getCategoryColor(log.category),
                          width: 3,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        // Homework: Category icon instead of sync status
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: LogModel.getCategoryColor(
                              log.category,
                            ).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            LogModel.getCategoryIcon(log.category),
                            color: LogModel.getCategoryColor(log.category),
                            size: 28,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                log.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            // Sync status badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: log.id != null
                                    ? Colors.green
                                    : Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    log.id != null
                                        ? Icons.cloud_done
                                        : Icons.cloud_upload,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    log.id != null ? 'Synced' : 'Pending',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              log.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            // Metadata Row
                            Row(
                              children: [
                                // Author Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isOwner ? Colors.blue : Colors.grey,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    log.authorId,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                // Date
                                Text(
                                  log.date.split(' ')[0], // Show date only
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Action Buttons (RBAC Gatekeeper)
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (canEdit)
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () =>
                                    _goToEditor(log: log, index: index),
                                tooltip: 'Edit',
                              ),
                            if (canDelete)
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteLog(index),
                                tooltip: 'Hapus',
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      // Floating Action Button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _goToEditor(),
        icon: const Icon(Icons.add),
        label: const Text('Catatan Baru'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
    );
  }
}
