import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class MyKumbhIDPage extends StatefulWidget {
  const MyKumbhIDPage({super.key});

  @override
  State<MyKumbhIDPage> createState() => _MyKumbhIDPageState();
}

class _MyKumbhIDPageState extends State<MyKumbhIDPage> {
  String? qrData;
  Map<String, dynamic>? decodedData;
  String? parkingZoneId;
  double? parkingLat;
  double? parkingLng;


  @override
  void initState() {
    super.initState();
    _loadQr();
  }

  // 📥 LOAD QR FROM LOCAL STORAGE
  Future<void> _openParkingMap() async {
    if (parkingLat == null || parkingLng == null) return;

    final url =
        "https://www.google.com/maps/search/?api=1&query=$parkingLat,$parkingLng";

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _loadQr() async {
    final prefs = await SharedPreferences.getInstance();
    final storedQr = prefs.getString("kumbh_qr");

    if (storedQr == null) return;

    final decodedJson =
    jsonDecode(utf8.decode(base64Decode(storedQr)));

    final qrId = decodedJson['qr_id'];

    setState(() {
      qrData = storedQr;
      decodedData = decodedJson;
    });

    // 🔥 Fetch parking from Firestore
    final qrSnap = await FirebaseFirestore.instance
        .collection("qr_passes")
        .doc(qrId)
        .get();

    if (!qrSnap.exists) return;

    final parkingId = qrSnap.data()?['zones']?['parking'];

    if (parkingId == null) return;

    final zoneSnap = await FirebaseFirestore.instance
        .collection("zones")
        .doc(parkingId)
        .get();

    if (!zoneSnap.exists) return;

    final loc = zoneSnap.data()?['location'];

    setState(() {
      parkingZoneId = parkingId;
      parkingLat = loc['lat'];
      parkingLng = loc['lng'];
    });
  }


  bool _isExpired() {
    if (decodedData == null) return false;

    final dateStr = decodedData!['date'];
    if (dateStr == null || dateStr is! String) return false;

    final visitDate = DateTime.parse(dateStr);
    return visitDate.isBefore(DateTime.now());
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0),
      appBar: AppBar(
        title: const Text("My KumbhID"),
        backgroundColor: const Color(0xFFD9822B),
        foregroundColor: Colors.white,
      ),
      body: qrData == null
          ? _emptyState()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _headerCard(),
            const SizedBox(height: 20),
            _qrCard(),
            const SizedBox(height: 20),
            _detailsCard(),
            const SizedBox(height: 20),
            _offlineNote(),
          ],
        ),
      ),
    );
  }

  // 🟠 EMPTY STATE
  Widget _emptyState() {
    return const Center(
      child: Text(
        "No KumbhID found.\nPlease register first.",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  // 🔶 HEADER CARD
  Widget _headerCard() {
    final expired = _isExpired();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "🕉 DigiSangam Pass",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: expired ? Colors.red : Colors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              expired ? "EXPIRED" : "VALID",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // 🔳 QR CARD
  Widget _qrCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          QrImageView(
            data: qrData!,
            size: 220,
            backgroundColor: Colors.white,
          ),
          const SizedBox(height: 10),
          Text(
            decodedData?['kid'] ?? decodedData?['qr_id'] ?? "—",
            style: const TextStyle(fontSize: 12),
          ),

        ],
      ),
    );
  }

  // 📋 DETAILS CARD
  Widget _detailsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          _detailRow("Visit Date", decodedData?['date'] ?? "—"),
          _detailRow("Slot", decodedData?['slot'] ?? "—"),
          _detailRow("Bathing Zone", decodedData?['zone'] ?? "—"),
          _detailRow("Parking Zone", parkingZoneId ?? "Not Assigned"),

          if (parkingLat != null && parkingLng != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.navigation),
                label: const Text("Navigate to Parking"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _openParkingMap,
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.black54, fontSize: 14)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }

  // 📶 OFFLINE NOTE
  Widget _offlineNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6E7D8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.offline_bolt, color: Color(0xFFD9822B)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "This QR pass works offline.\nShow it at checkpoints for scanning.",
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
