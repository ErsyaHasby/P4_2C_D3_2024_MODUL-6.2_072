import 'package:flutter_dotenv/flutter_dotenv.dart';

/// AccessControlService - The Security Gatekeeper (RBAC Implementation)
///
/// Konsep: Centralized Security Policy Manager
/// Logika: Validasi setiap aksi CRUD berdasarkan role dan ownership
/// Tujuan: Scalable & Modular security system
class AccessControlService {
  // Mengambil roles dari .env di root (Dynamic Configuration)
  static List<String> get availableRoles =>
      dotenv.env['APP_ROLES']?.split(',') ?? ['Anggota'];

  // Action Constants (Open-Closed Principle)
  static const String actionCreate = 'create';
  static const String actionRead = 'read';
  static const String actionUpdate = 'update';
  static const String actionDelete = 'delete';

  // Matrix perizinan yang tetap fleksibel (Easy to Extend)
  static final Map<String, List<String>> _rolePermissions = {
    'Ketua': [actionCreate, actionRead, actionUpdate, actionDelete],
    'Anggota': [actionCreate, actionRead],
    'Asisten': [actionRead, actionUpdate],
  };

  /// Core Security Function - The Gatekeeper Logic
  ///
  /// Parameters:
  /// - role: User's role (Ketua/Anggota/Asisten)
  /// - action: What action user wants to perform
  /// - isOwner: Whether user is the data owner (for ownership-based access)
  ///
  /// Returns: true if allowed, false if denied
  static bool canPerform(String role, String action, {bool isOwner = false}) {
    final permissions = _rolePermissions[role] ?? [];
    bool hasBasicPermission = permissions.contains(action);

    // Logic khusus kepemilikan data (Owner-based RBAC)
    // Anggota hanya bisa edit/delete data miliknya sendiri
    if (role == 'Anggota' &&
        (action == actionUpdate || action == actionDelete)) {
      return isOwner;
    }

    return hasBasicPermission;
  }

  /// Helper: Check if user has full access (for debugging)
  static bool isAdmin(String role) {
    return role == 'Ketua';
  }

  /// Helper: Get all permissions for a role (for UI hints)
  static List<String> getPermissions(String role) {
    final actions = _rolePermissions[role] ?? [];
    return actions.map((action) {
      switch (action) {
        case actionCreate:
          return 'Membuat data baru';
        case actionRead:
          return 'Melihat data';
        case actionUpdate:
          return 'Mengubah data';
        case actionDelete:
          return 'Menghapus data';
        default:
          return action;
      }
    }).toList();
  }
}
