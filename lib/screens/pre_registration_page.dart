import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'accommodation_list_page.dart';
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
  String? city;
  DateTime? visitDate;
  Map<String, dynamic>? _selectedStay; // null if skipped
  bool _accommodationDecided = false;

  // TEMP QR STORAGE
  String? _tempQrId;
  String? _tempQrData;
  int _pilgrimCount = 1;

  // ───── VISIT DETAILS ─────
  String? slot;
  String? snanType;

  // ───── GROUP ─────
  bool isGroup = false;
  int groupSize = 1;
  bool elderlyPresent = false;

  // ───── TRAVEL ─────
  String? travelMode;
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

  // ───── ZONE ALLOCATION ─────
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

    return {"bath": bathZone, "parking": parkingZone};
  }

  // ───── MAIN FLOW ─────

  // ───── ACCOMMODATION PROMPT ─────
  void _showAccommodationPrompt() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // 🔥 important for custom card
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.45,
          minChildSize: 0.35,
          maxChildSize: 0.6,
          builder: (_, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ─── DRAG HANDLE ───
                    Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 🖼 IMAGE
                    Image.asset(
                      "assets/stay.jpg",
                      height: 140,
                      fit: BoxFit.contain,
                    ),

                    const SizedBox(height: 20),

                    // 🏠 TITLE
                    const Text(
                      "Need Accommodation?",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // 🧠 DESCRIPTION
                    const Text(
                      "We can suggest free, government-verified stays near your selected zone, based on your group size.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ✅ YES BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.home),
                        label: const Text(
                          "Yes, show recommended stays",
                          style: TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF15803D),
                          padding:
                          const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                        onPressed: () async {
                          Navigator.pop(context);

                          final stay = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AccommodationListPage(
                                city: city!,
                                people: _pilgrimCount,
                              ),
                            ),
                          );

                          _selectedStay = stay;
                          _handleAccommodationDone();
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ❌ SKIP BUTTON
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _selectedStay = null;
                        _handleAccommodationDone();
                      },
                      child: const Text(
                        "Skip for now",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // 🕉 FOOTER
                    const Text(
                      "🕉 You can book accommodation later as well",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleAccommodationDone() async {
    final verified = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtpVerificationPage(phone: phone),
      ),
    );

    if (verified != true) return;

    await _finalizeAfterOtp();
  }
  Future<void> _finalizeAfterOtp() async {
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
        "size": _pilgrimCount,
        "elderly_present": elderlyPresent,
      },
      "travel": {
        "mode": travelMode,
        "vehicle_no": travelMode == "CAR" ? vehicleNumber : null,
      },
      "stay": _selectedStay, // null if skipped
      "status": "CONFIRMED",
      "createdAt": FieldValue.serverTimestamp(),
    });

    final assignedZones = _allocateZones();

    await FirebaseFirestore.instance
        .collection("zones")
        .doc(assignedZones["bath"])
        .update({
      "counters.registered": FieldValue.increment(_pilgrimCount)
    });

    final qrRef =
    FirebaseFirestore.instance.collection("qr_passes").doc();

    await qrRef.set({
      "visit_id": visitRef.id,
      "zones": assignedZones,
      "group_size": _pilgrimCount,
      "slot": slot,
      "date": visitDate!.toIso8601String().split('T')[0],
      "stay": _selectedStay,
      "createdAt": FieldValue.serverTimestamp(),
    });

    final qrId = qrRef.id;

    final qrData = _generateQrData(
      qrId: qrId,
      date: visitDate!.toIso8601String().split('T')[0],
      slot: slot!,
      zone: assignedZones["bath"]!,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("kumbh_qr", qrData);

    setState(() => _isLoading = false);

    _showQrDialog(qrData, qrId);
  }


  Future<void> _onGeneratePressed() async {
    if (!_formKey.currentState!.validate() ||
        visitDate == null ||
        city == null ||
        slot == null ||
        snanType == null ||
        travelMode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please complete all details")),
      );
      return;
    }

    _formKey.currentState!.save();

    final pilgrimCount = isGroup ? groupSize : 1;
    _pilgrimCount = pilgrimCount;

    // Ask accommodation first
    _showAccommodationPrompt();
  }

  // ───── QR DIALOG ─────
  void _showQrDialog(String qrData, String qrId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Your Kumbh QR"),
        content: SizedBox(
          width: 260, // ✅ forces layout
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QrImageView(
                data: qrData,
                size: 200,
              ),
              const SizedBox(height: 12),
              Text(
                "QR ID: $qrId",
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // dialog
              Navigator.pop(context); // pre-registration page
            },
            child: const Text("Done"),
          )
        ],
      ),
    );
  }


  // ───── UI BELOW (UNCHANGED) ─────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7ED),
      appBar: AppBar(
        title: const Text("Kumbh Pre-Registration"),
        backgroundColor: const Color(0xFFD97706),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _formCard(),
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _formCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _section("🧍 Pilgrim Details"),
            _field("Mobile Number", (v) => phone = v!,
                keyboard: TextInputType.phone),
            _dateField(),

            _section("📍 Visit Details"),
            _dropdown("City", city, ["Nashik", "Trimbakeshwar"],
                    (v) => setState(() => city = v)),
            _dropdown("Time Slot", slot,
                ["MORNING", "AFTERNOON", "EVENING"],
                    (v) => setState(() => slot = v)),
            _dropdown("Snan Type", snanType, ["NORMAL", "SHAHI"],
                    (v) => setState(() => snanType = v)),

            _section("👨‍👩‍👧 Group Information"),
            SwitchListTile(
              title: const Text("Coming in a group?"),
              value: isGroup,
              onChanged: (v) => setState(() => isGroup = v),
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

            _section("🚗 Travel"),
            _dropdown("Travel Mode", travelMode,
                ["CAR", "BUS", "WALK", "TWO_WHEELER"],
                    (v) => setState(() => travelMode = v)),

            if (travelMode == "CAR")
              _field("Vehicle Number", (v) => vehicleNumber = v!),

            const SizedBox(height: 24),
            _generateButton(),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Text(title,
        style:
        const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
  );

  Widget _dropdown(String label, String? value, List<String> items,
      Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        hint: Text("Select $label"),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (v) => onChanged(v!),
        validator: (v) => v == null ? "Please select $label" : null,
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFFFF3E0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
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
            borderRadius: BorderRadius.circular(16),
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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(16),
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

  Widget _generateButton() => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: _onGeneratePressed,

      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),
      child: const Text(
        "Generate Kumbh QR",
        style: TextStyle(fontSize: 18),
      ),
    ),
  );
}
