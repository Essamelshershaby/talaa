// ============================================================
// ملف: models/user_model.dart
// الوظيفة: نموذج المستخدم لـ Firestore
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import '../enums/user_role.dart';

class UserModel {
  final String uid;
  final String email;
  final UserRole role;
  final String name;
  final String? phone;
  final String? avatarUrl;
  final DateTime createdAt;
  final bool isActive;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.name,
    this.phone,
    this.avatarUrl,
    required this.createdAt,
    this.isActive = true,
  });

  // ==================== تحويل إلى Firestore ====================
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'role': role.toStorageString(),
      'name': name,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'createdAt': Timestamp.fromDate(createdAt),  // Timestamp في Firestore
      'isActive': isActive,
    };
  }

  // ==================== إنشاء من Firestore ====================
  factory UserModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return UserModel(
      uid: data['uid'] ?? docId,
      email: data['email'] ?? '',
      role: UserRoleExtension.fromString(data['role'] ?? 'member'),
      name: data['name'] ?? '',
      phone: data['phone'],
      avatarUrl: data['avatarUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  // ==================== نسخة معدلة ====================
  UserModel copyWith({
    String? uid,
    String? email,
    UserRole? role,
    String? name,
    String? phone,
    String? avatarUrl,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      role: role ?? this.role,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  // ==================== الحروف الأولى ====================
  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}';
    }
    return name.isNotEmpty ? name[0] : 'U';
  }
}