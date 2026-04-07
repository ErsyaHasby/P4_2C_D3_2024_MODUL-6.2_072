import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

part 'log_model.g.dart';

@HiveType(typeId: 0)
class LogModel {
  @HiveField(0)
  final String? id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String date;

  @HiveField(4)
  final String authorId; // BARU: ID pemilik log

  @HiveField(5)
  final String teamId; // BARU: ID kelompok untuk kolaborasi

  @HiveField(6)
  final bool isPublic; // TASK 5: Privacy control - true=Public, false=Private

  @HiveField(7)
  final String category; // HOMEWORK: Categorization - Mechanical/Electronic/Software

  LogModel({
    this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.authorId,
    required this.teamId,
    this.isPublic = false, // Default: Private (hanya owner yang lihat)
    this.category = 'Software', // Default: Software
  });

  // [CONVERT] Memasukkan data ke "Kardus" (BSON/Map) untuk dikirim ke Cloud
  Map<String, dynamic> toMap() => {
    '_id': id != null ? ObjectId.fromHexString(id!) : ObjectId(),
    'title': title,
    'description': description,
    'date': date,
    'authorId': authorId,
    'teamId': teamId,
    'isPublic': isPublic, // Task 5: Include privacy status
    'category': category, // Homework: Include category
  };

  // [REVERT] Membongkar "Kardus" (BSON/Map) kembali menjadi objek Flutter
  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      id: (map['_id'] as ObjectId?)?.oid,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: map['date'] ?? '',
      authorId: map['authorId'] ?? 'unknown_user', // Cegah error null
      teamId: map['teamId'] ?? 'default_team', // Cegah error null
      isPublic: map['isPublic'] ?? false, // Task 5: Default private
      category: map['category'] ?? 'Software', // Homework: Default category
    );
  }

  // Helper: Get category color
  static Color getCategoryColor(String category) {
    switch (category) {
      case 'Mechanical':
        return const Color(0xFF4CAF50); // Green
      case 'Electronic':
        return const Color(0xFF2196F3); // Blue
      case 'Software':
        return const Color(0xFF9C27B0); // Purple
      default:
        return const Color(0xFF757575); // Grey
    }
  }

  // Helper: Get category icon
  static IconData getCategoryIcon(String category) {
    switch (category) {
      case 'Mechanical':
        return Icons.build;
      case 'Electronic':
        return Icons.electrical_services;
      case 'Software':
        return Icons.code;
      default:
        return Icons.category;
    }
  }
}
