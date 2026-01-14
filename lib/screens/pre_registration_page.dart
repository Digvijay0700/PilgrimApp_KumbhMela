import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'otp_verification_page.dart';

const String QR_SECRET = "KUMBHATHON_2027_SECRET";

class PreRegistrationPage extends StatefulWidget {
  const PreRegistrationPage({super.key});

  @override
  State<PreRegistrationPage> createState() => _PreRegistrationPageState();
}

class _PreRegistrationPageState extends State<PreRegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  // ───── BASIC ─────
  String phone = '';
  String city = "Nashik";
  DateTime? visitDate;

  // ───── VISIT DETAILS ─────
  String slot = "MORNING";
  String snanType = "NORMAL";

  // ───── GROUP ─────
  bool isGroup = false;
  int groupSize = 1;
  bool elderlyPresent = false;

  // ───── TRAVEL ─────
  String travelMode = "CAR";
  String vehicleNumber = "";

  bool _isLoading = false;

  // ───── QR SIGN ─────
  String _sign(String qrId) {
    final hmac = Hmac(sha256, utf8.encode(QR_SECRET));
    return hmac.convert(utf8.encode(qrId)).toString().substring(0, 10);
  }

  String _generateQrData({
    required String qrId,
    required String date,
    required String slot,
    required String zone,
  }) {
    final payload = {
      "qr_id": qrId,
      "date": date,
      "slot": slot,
      "zone": zone,
      "sig": _sign(qrId),
    };
    return base64Encode(utf8.encode(jsonEncode(payload)));
  }

  Future<void> _saveQrLocally(String qrData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("kumbh_qr", qrData);
  }

  // ───── ZONE ALLOCATION (REAL IDS) ─────
  Map<String, String?> _allocateZones() {
    String bathZone;
    String? parkingZone;

    if (city == "Nashik") {
      bathZone = "RAMKUND_G1";
      parkingZone = travelMode == "CAR" ? "PARK_NASHIK_A1" : null;
    } else {
      bathZone = snanType == "SHAHI"
          ? "TRIMBAKESHWAR_TEMPLE_SNAN_G1"
          : "KUSHAVARTA_KUND_G1";
      parkingZone = travelMode == "CAR" ? "PARK_TRIMBAK_A1" : null;
    }

    return {
      "bath": bathZone,
      "parking": parkingZone,
    };
  }

  // ───── COUNTER INCREMENT ─────
  Future<void> _incrementZoneCounter({
    required String zoneId,
    required int count,
  }) async {
    final zoneRef =
    FirebaseFirestore.instance.collection("zones").doc(zoneId);

    await FirebaseFirestore.instance.runTransaction((txn) async {
      final snap = await txn.get(zoneRef);
      if (!snap.exists) {
        throw Exception("Zone $zoneId not found");
      }
      final current =
      (snap.data()?['counters']?['registered'] ?? 0) as int;

      txn.update(zoneRef, {
        "counters.registered": current + count,
      });
    });
  }

  // ───── MAIN FLOW ─────
  Future<void> _generateQR() async {
    if (!_formKey.currentState!.validate() || visitDate == null) return;
    _formKey.currentState!.save();

    final verified = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtpVerificationPage(phone: phone),
      ),
    );
    if (verified != true) return;

    setState(() => _isLoading = true);

    final visitRef =
    FirebaseFirestore.instance.collection("visits").doc();

    await visitRef.set({
      "user": {"phone": phone},
      "city": city,
      "visit_date": visitDate!.toIso8601String().split('T')[0],
      "time_slot": slot,
      "snan_type": snanType,
      "group": {
        "is_group": isGroup,
        "size": isGroup ? groupSize : 1,
        "elderly_present": elderlyPresent,
      },
      "travel": {
        "mode": travelMode,
        "vehicle_no": travelMode == "CAR" ? vehicleNumber : null,
      },
      "status": "CONFIRMED",
      "createdAt": FieldValue.serverTimestamp(),
    });

    final assignedZones = _allocateZones();
    final int pilgrimCount = isGroup ? groupSize : 1;

    // 🔥 Increment zone counters
    await _incrementZoneCounter(
      zoneId: assignedZones["bath"]!,
      count: pilgrimCount,
    );

    if (assignedZones["parking"] != null) {
      await _incrementZoneCounter(
        zoneId: assignedZones["parking"]!,
        count: 1,
      );
    }

    // ───── CREATE QR PASS ─────
    final qrRef =
    FirebaseFirestore.instance.collection("qr_passes").doc();

    await qrRef.set({
      "visit_id": visitRef.id,
      "zones": assignedZones,
      "group_size": pilgrimCount,
      "slot": slot,
      "date": visitDate!.toIso8601String().split('T')[0],
      "createdAt": FieldValue.serverTimestamp(),
    });

    final qrId = qrRef.id;

    final qrData = _generateQrData(
      qrId: qrId,
      date: visitDate!.toIso8601String().split('T')[0],
      slot: slot,
      zone: assignedZones["bath"]!,
    );

    await _saveQrLocally(qrData);

    setState(() => _isLoading = false);
    _showQrDialog(qrData, qrId);
  }

  // ───── UI ─────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0),
      appBar: AppBar(
        title: const Text("Kumbh Pre-Registration"),
        backgroundColor: const Color(0xFFD9822B),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _formCard(),
          ),
          if (_isLoading) _loadingOverlay(),
        ],
      ),
    );
  }

  Widget _loadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.4),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  Widget _formCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _field("Phone Number", (v) => phone = v!,
                keyboard: TextInputType.phone),
            _dateField(),
            const SizedBox(height: 12),
            _dropdown("City", city, ["Nashik", "Trimbakeshwar"],
                    (v) => setState(() => city = v)),
            _dropdown("Time Slot", slot,
                ["MORNING", "AFTERNOON", "EVENING"],
                    (v) => setState(() => slot = v)),
            _dropdown("Snan Type", snanType,
                ["NORMAL", "SHAHI"],
                    (v) => setState(() => snanType = v)),
            const Divider(),
            SwitchListTile(
              title: const Text("Is this a group?"),
              value: isGroup,
              onChanged: (v) => setState(() {
                isGroup = v;
                if (!v) groupSize = 1;
              }),
            ),
            if (isGroup)
              _field("Group Size",
                      (v) => groupSize = int.parse(v!),
                  keyboard: TextInputType.number),
            SwitchListTile(
              title: const Text("Elderly present"),
              value: elderlyPresent,
              onChanged: (v) => setState(() => elderlyPresent = v),
            ),
            const Divider(),
            _dropdown("Travel Mode", travelMode,
                ["CAR", "BUS", "WALK", "TWO_WHEELER"],
                    (v) => setState(() => travelMode = v)),
            if (travelMode == "CAR")
              _field("Vehicle Number", (v) => vehicleNumber = v!),
            const SizedBox(height: 20),
            _generateButton(),
          ],
        ),
      ),
    );
  }

  Widget _dropdown(
      String label, String value, List<String> items, Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (v) => onChanged(v!),
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFFFF3E0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _field(String hint, Function(String?) onSaved,
      {TextInputType keyboard = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        validator: (v) => v!.isEmpty ? "Required" : null,
        onSaved: onSaved,
        keyboardType: keyboard,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: const Color(0xFFFFF3E0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _dateField() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 30)),
          initialDate: DateTime.now(),
        );
        if (picked != null) setState(() => visitDate = picked);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today),
            const SizedBox(width: 10),
            Text(
              visitDate == null
                  ? "Select Visit Date"
                  : visitDate!.toIso8601String().split('T')[0],
            ),
          ],
        ),
      ),
    );
  }

  Widget _generateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _generateQR,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Text("Generate Kumbh QR"),
      ),
    );
  }

  void _showQrDialog(String qrData, String qrId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Your Kumbh QR"),
        content: SizedBox(
          width: 260,
          height: 280,
          child: Column(
            children: [
              QrImageView(data: qrData, size: 200),
              const SizedBox(height: 10),
              Text("QR ID: $qrId",
                  style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Done"),
          )
        ],
      ),
    );
  }
}
