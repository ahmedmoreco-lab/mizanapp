import 'package:cloud_firestore/cloud_firestore.dart';

class CheckinModel {
  final String id;
  final String userId;
  final DateTime timestamp;
  final bool isEmergency;

  CheckinModel({
    required this.id,
    required this.userId,
    required this.timestamp,
    this.isEmergency = false,
  });

  factory CheckinModel.fromMap(String documentId, Map<String, dynamic> data) {
    return CheckinModel(
      id: documentId,
      userId: data['userId'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isEmergency: data['isEmergency'] ?? false,
    );
  }

  factory CheckinModel.fromDocument(DocumentSnapshot doc) {
    if (!doc.exists) throw Exception('Document does not exist');
    final data = doc.data() as Map<String, dynamic>;
    return CheckinModel.fromMap(doc.id, data);
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'timestamp': Timestamp.fromDate(timestamp),
      'isEmergency': isEmergency,
    };
  }
}
