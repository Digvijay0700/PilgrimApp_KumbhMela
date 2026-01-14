import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ble_gatt_service.dart';


import '../widgets/wave_clipper.dart';
import 'pre_registration_page.dart';
import 'my_kumbh_id_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // 🔧 DEV ONLY – clear local QR
  Future<void> _clearLocalKumbhID(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("kumbh_qr");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Local KumbhID cleared")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🔶 HEADER
            ClipPath(
              clipper: WaveClipper(),
              child: Container(
                height: 280,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/kumbh_bg.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.65),
                        Colors.transparent,
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "DigiSangam (KumbhID)",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        "Digital Identity for a Safe Kumbh",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Seva • Suraksha • Shraddha",
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🔶 MAIN ACTIONS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _mainActionCard(
                    context: context,
                    icon: Icons.calendar_month,
                    title: "Pre-Registration",
                    subtitle: "Register before arrival\nChoose darshan slot",
                    backgroundColor: const Color(0xFFF08000),
                    textColor: const Color(0xFF2E2E2E),
                    iconColor: Colors.white,
                    arrowColor: const Color(0xFF2E2E2E),
                    onTap: () async {
                      final prefs = await SharedPreferences.getInstance();
                      final existingQR = prefs.getString("kumbh_qr");

                      if (existingQR != null) {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Already Registered"),
                            content: const Text(
                              "You already have a KumbhID.\nWould you like to view your pass?",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Cancel"),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const MyKumbhIDPage(),
                                    ),
                                  );
                                },
                                child: const Text("View Pass"),
                              ),
                            ],
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PreRegistrationPage(),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  _mainActionCard(
                    context: context,
                    icon: Icons.location_on,
                    title: "On-Spot Registration",
                    subtitle: "For walk-in pilgrims\nInstant KumbhID",
                    backgroundColor: const Color(0xFF228B22),
                    textColor: Colors.white,
                    iconColor: Colors.white,
                    arrowColor: Colors.white,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("On-Spot Registration (Demo)"),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 🔶 GRID OPTIONS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
                children: [
                  _GridTile(
                    icon: Icons.badge,
                    title: "My KumbhID",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MyKumbhIDPage(),
                        ),
                      );
                    },
                  ),
                  _GridTile(
                    icon: Icons.home,
                    title: "Verified Stays",
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Coming soon")),
                      );
                    },
                  ),
                  _GridTile(
  icon: Icons.warning_amber,
  title: "Emergency Help",
  onTap: () async {
    try {
      await BleGattService.startSOS();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🚨 SOS sent via BLE GATT"),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Failed to send SOS"),
        ),
      );
    }
  },
),

                  _GridTile(
                    icon: Icons.person,
                    title: "My Profile",
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Profile (Demo)")),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),


            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => _clearLocalKumbhID(context),
                child: const Text("DEV: Clear Local Pass"),
              ),
            ),


            const SizedBox(height: 16),

            // 🔶 FOOTER
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                "Prototype for Smart Crowd Management at Kumbh Mela",
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔶 MAIN ACTION CARD WIDGET
  Widget _mainActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color backgroundColor,
    required Color textColor,
    required Color iconColor,
    required Color arrowColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: iconColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: textColor.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: arrowColor),
          ],
        ),
      ),
    );
  }
}

// 🔶 GRID TILE
class _GridTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _GridTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0D6C8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: const Color(0xFF264653)),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E2E2E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
