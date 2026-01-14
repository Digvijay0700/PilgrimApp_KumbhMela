import 'package:flutter/material.dart';
import '../ble_gatt_service.dart';

class SosPage extends StatelessWidget {
  const SosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Emergency SOS"),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            try {
              await BleGattService.startSOS();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("🚨 SOS sent via BLE GATT"),
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
          child: const Text("SEND SOS"),
        ),
      ),
    );
  }
}
