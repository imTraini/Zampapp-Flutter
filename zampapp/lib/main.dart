import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'screens/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ Aggiunto per risolvere l'errore di formattazione della data
  await initializeDateFormatting('it_IT', null);

  runApp(const ZampApp());
}

class ZampApp extends StatelessWidget {
  const ZampApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ZampApp',
      home: AuthGate(),
    );
  }
}
