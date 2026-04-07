import 'package:logbook_app_modul5/services/access_control_service.dart';

/// AccessPolicy - Task 3: Collaborative Security & RBAC Policy Manager
///
/// Konsep: High-level policy wrapper untuk aksesibilitas yang mudah dipahami
/// Logika: Abstraksi di atas AccessControlService untuk kontrol granular
/// Tujuan: Simplifikasi permission checking di UI layer dengan readable API
///
/// Modul 5 MOTS Requirement:
/// - Ketua: Full access (Create, Read, Update, Delete semua log tim)
/// - Anggota: Limited access (Create, Read, Update/Delete hanya milik sendiri)
class AccessPolicy {
  final String userRole;
  final String userId;

  AccessPolicy({required this.userRole, required this.userId});

  /// Factory constructor dari currentUser Map
  factory AccessPolicy.fromUser(Map<String, String> currentUser) {
    return AccessPolicy(
      userRole: currentUser['role'] ?? 'Anggota',
      userId: currentUser['uid'] ?? '',
    );
  }

  // ========== ROLE CHECKS ==========

  /// Check apakah user adalah Ketua (Team Leader)
  bool get isLeader => userRole == 'Ketua';

  /// Check apakah user adalah Anggota (Team Member)
  bool get isMember => userRole == 'Anggota';

  /// Check apakah user adalah Asisten (Assistant)
  bool get isAssistant => userRole == 'Asisten';

  // ========== PERMISSION CHECKS ==========

  /// Apakah user bisa membuat log baru?
  bool get canCreate => AccessControlService.canPerform(
    userRole,
    AccessControlService.actionCreate,
  );

  /// Apakah user bisa membaca log?
  bool get canRead => AccessControlService.canPerform(
    userRole,
    AccessControlService.actionRead,
  );

  /// Apakah user bisa UPDATE log tertentu?
  /// - Ketua: Bisa update SEMUA log tim
  /// - Anggota: Hanya bisa update log MILIKNYA SENDIRI
  bool canUpdate(String authorId) {
    final isOwner = authorId == userId;
    return AccessControlService.canPerform(
      userRole,
      AccessControlService.actionUpdate,
      isOwner: isOwner,
    );
  }

  /// Apakah user bisa DELETE log tertentu?
  /// - Ketua: Bisa delete SEMUA log tim
  /// - Anggota: Hanya bisa delete log MILIKNYA SENDIRI
  bool canDelete(String authorId) {
    final isOwner = authorId == userId;
    return AccessControlService.canPerform(
      userRole,
      AccessControlService.actionDelete,
      isOwner: isOwner,
    );
  }

  // ========== UI HELPER METHODS ==========

  /// Dapatkan deskripsi level akses untuk ditampilkan di UI
  String get accessLevelDescription {
    switch (userRole) {
      case 'Ketua':
        return '👑 Ketua Tim - Full Access';
      case 'Anggota':
        return '👤 Anggota - Edit Data Sendiri';
      case 'Asisten':
        return '👨‍🏫 Asisten - Read & Review';
      default:
        return '👤 $userRole';
    }
  }

  /// Dapatkan list permission yang dimiliki user (untuk debugging)
  List<String> get permissions {
    final perms = <String>[];
    if (canCreate) perms.add('Create');
    if (canRead) perms.add('Read');
    if (isLeader || isAssistant) perms.add('Update All');
    if (isMember) perms.add('Update Own');
    if (isLeader) perms.add('Delete All');
    if (isMember) perms.add('Delete Own');
    return perms;
  }

  /// Dapatkan pesan error RBAC yang informatif
  String getDeniedMessage(String action) {
    if (isMember && (action == 'update' || action == 'delete')) {
      return '❌ Anggota hanya bisa $action data milik sendiri!';
    }
    return '❌ Role "$userRole" tidak memiliki akses untuk $action!';
  }

  // ========== TEAM ISOLATION HELPER ==========

  /// Check apakah log termasuk dalam tim yang sama
  bool isInSameTeam(String logTeamId, String userTeamId) {
    return logTeamId == userTeamId;
  }

  /// Validasi kombinasi: Permission + Team Isolation + Ownership
  bool canAccessLog({
    required String action,
    required String logAuthorId,
    required String logTeamId,
    required String userTeamId,
  }) {
    // Step 1: Team Isolation Check
    if (!isInSameTeam(logTeamId, userTeamId)) {
      return false;
    }

    // Step 2: Permission Check
    final isOwner = logAuthorId == userId;
    return AccessControlService.canPerform(userRole, action, isOwner: isOwner);
  }

  @override
  String toString() {
    return 'AccessPolicy(role: $userRole, uid: $userId, permissions: $permissions)';
  }
}
