import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import '../models/sos_model.dart';

class SOSTSyncService {
  static final _connectivity = Connectivity();

  /// Call this once at app start
  static void startListening() {
    _connectivity.onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        syncPendingSOS();
      }
    });
  }

  /// Upload all unsynced SOS
  static Future<void> syncPendingSOS() async {
    final box = Hive.box<SOSModel>('sosBox');

    final pending = box.values.where((sos) => !sos.isSynced).toList();

    if (pending.isEmpty) return;

    for (final sos in pending) {
      try {
        await FirebaseFirestore.instance
            .collection('sos_alerts')
            .doc(sos.id)
            .set({
          'issue': sos.issue,
          'lat': sos.lat,
          'lng': sos.lng,
          'timestamp': sos.timestamp,
          'status': 'ACTIVE',
        });

        sos.isSynced = true;
        await sos.save();
      } catch (e) {
        // Stop if network unstable
        break;
      }
    }
  }
}
