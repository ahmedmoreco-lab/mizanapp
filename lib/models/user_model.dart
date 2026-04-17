import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String role;
  final String? trustedContactId; // Legacy
  final List<String> trustedContacts;
  final String? name; // Optional, can add later
  final int inactivityThresholdHours;
  final bool isPremium;
  final List<String> escalationOrder;
  final List<String> customCheckInTimes;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    this.trustedContactId,
    this.trustedContacts = const [],
    this.name,
    this.inactivityThresholdHours = 24,
    this.isPremium = false,
    this.escalationOrder = const [],
    this.customCheckInTimes = const [],
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? '',
      trustedContactId: data['trustedContactId'],
      trustedContacts: (data['trustedContacts'] as List<dynamic>?)?.cast<String>() ?? (data['trustedContactId'] != null ? [data['trustedContactId']] : []),
      name: data['name'],
      inactivityThresholdHours: data['inactivityThresholdHours'] != null ? (data['inactivityThresholdHours'] as num).toInt() : 24,
      isPremium: data['isPremium'] ?? false,
      escalationOrder: (data['escalationOrder'] as List<dynamic>?)?.cast<String>() ?? [],
      customCheckInTimes: (data['customCheckInTimes'] as List<dynamic>?)?.cast<String>() ?? [],
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
      trustedContacts: (data['trustedContacts'] as List<dynamic>?)?.cast<String>() ?? (data['trustedContactId'] != null ? [data['trustedContactId']] : []),
      name: data['name'],
      inactivityThresholdHours: data['inactivityThresholdHours'] != null ? (data['inactivityThresholdHours'] as num).toInt() : 24,
      isPremium: data['isPremium'] ?? false,
      escalationOrder: (data['escalationOrder'] as List<dynamic>?)?.cast<String>() ?? [],
      customCheckInTimes: (data['customCheckInTimes'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'trustedContactId': trustedContactId,
      'trustedContacts': trustedContacts,
      'name': name,
      'inactivityThresholdHours': inactivityThresholdHours,
      'isPremium': isPremium,
      'escalationOrder': escalationOrder,
      'customCheckInTimes': customCheckInTimes,
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
    List<String>? trustedContacts,
    String? name,
    int? inactivityThresholdHours,
    bool? isPremium,
    List<String>? escalationOrder,
    List<String>? customCheckInTimes,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      role: role ?? this.role,
      trustedContactId: trustedContactId ?? this.trustedContactId,
      trustedContacts: trustedContacts ?? this.trustedContacts,
      name: name ?? this.name,
      inactivityThresholdHours: inactivityThresholdHours ?? this.inactivityThresholdHours,
      isPremium: isPremium ?? this.isPremium,
      escalationOrder: escalationOrder ?? this.escalationOrder,
      customCheckInTimes: customCheckInTimes ?? this.customCheckInTimes,
    );
  }
}
