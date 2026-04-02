import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String role;
  final String? trustedContactId;
  final String? name; // Optional, can add later
  final int inactivityThresholdHours;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    this.trustedContactId,
    this.name,
    this.inactivityThresholdHours = 24,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? '',
      trustedContactId: data['trustedContactId'],
      name: data['name'],
      inactivityThresholdHours: data['inactivityThresholdHours'] ?? 24,
    );
  }

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    if (!doc.exists) return UserModel.empty();
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      role: data['role'] ?? '',
      trustedContactId: data['trustedContactId'],
      name: data['name'],
      inactivityThresholdHours: data['inactivityThresholdHours'] ?? 24,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'trustedContactId': trustedContactId,
      'name': name,
      'inactivityThresholdHours': inactivityThresholdHours,
    };
  }

  bool get isElder => role.toLowerCase() == 'elder';
  bool get isContact => role.toLowerCase() == 'contact';

  static UserModel empty() {
    return UserModel(uid: '', email: '', role: '');
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? role,
    String? trustedContactId,
    String? name,
    int? inactivityThresholdHours,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      role: role ?? this.role,
      trustedContactId: trustedContactId ?? this.trustedContactId,
      name: name ?? this.name,
      inactivityThresholdHours: inactivityThresholdHours ?? this.inactivityThresholdHours,
    );
  }
}
