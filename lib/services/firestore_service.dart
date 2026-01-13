import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sos_model.dart';

class FirestoreService {
  static Future<void> uploadSOS(SOSModel sos) async {
    await FirebaseFirestore.instance
        .collection('sos_alerts')
        .doc(sos.id)
        .set({
      // 🔐 ENCRYPTED SOS DATA
      'encryptedPayload': sos.encryptedPayload,

      // 🔹 METADATA ONLY
      'status': 'ACTIVE',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
