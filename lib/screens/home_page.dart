import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ble_gatt_service.dart';
import 'sos_page.dart';
import '../widgets/wave_clipper.dart';
import 'pre_registration_page.dart';
import 'my_kumbh_id_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Seva • Suraksha • Shraddha",
                        style: TextStyle(color: Colors.white60, fontSize: 13),
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MyKumbhIDPage(),
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
                    onTap: () {},
                  ),

                  // 🚨 SIMPLE SOS SLIDER
                  const SizedBox(height: 28),
                  const SimpleSosSlider(),
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
                    onTap: () {},
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
          ],
        ),
      ),
    );
  }

  // 🔶 MAIN ACTION CARD
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

// 🚨 SIMPLE, BUG-FREE SOS SLIDER
class SimpleSosSlider extends StatefulWidget {
  const SimpleSosSlider({super.key});

  @override
  State<SimpleSosSlider> createState() => _SimpleSosSliderState();
}

class _SimpleSosSliderState extends State<SimpleSosSlider> {
  double _value = 0;

  Future<void> _triggerSOS() async {
    await BleGattService.startSOS();

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SosPage()),
    );

    setState(() => _value = 0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        gradient: const LinearGradient(
          colors: [Color(0xFFB71C1C), Color(0xFFD32F2F)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: 1 - (_value / 100),
            child: const Text(
              "SLIDE FOR EMERGENCY SOS",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 70,
              activeTrackColor: Colors.transparent,
              inactiveTrackColor: Colors.transparent,
              overlayShape: SliderComponentShape.noOverlay,
              thumbShape:
              const RoundSliderThumbShape(enabledThumbRadius: 28),
              thumbColor: Colors.white,
            ),
            child: Slider(
              value: _value,
              min: 0,
              max: 100,
              onChanged: (val) {
                setState(() => _value = val);
                if (val >= 95) _triggerSOS();
              },
            ),
          ),
        ],
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
