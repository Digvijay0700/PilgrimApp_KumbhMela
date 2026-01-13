import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'screens/home_page.dart';
import 'models/sos_model.dart';
import 'services/sos_sync_service.dart';

Future<void> main() async {
  // 🔥 REQUIRED FOR ASYNC INIT
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 FIREBASE INIT
  await Firebase.initializeApp();

  // 🔥 HIVE INIT
  await Hive.initFlutter();

  // 🔥 REGISTER ADAPTER
  Hive.registerAdapter(SOSModelAdapter());

  // 🔥 OPEN BOX (MANDATORY)
  await Hive.openBox<SOSModel>('sosBox');

  // 🔥 START AUTO-SYNC LISTENER (PHASE 3)
  SOSTSyncService.startListening();

  runApp(const DigiSangamApp());
}

class DigiSangamApp extends StatelessWidget {
  const DigiSangamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DigiSangam',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF4A261), // Saffron theme
        ),
        scaffoldBackgroundColor: const Color(0xFFFFF7E9),
      ),
      home: const HomePage(),
    );
  }
}
