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

  await initializeDateFormatting('it_IT', null);

  runApp(const ZampApp());
}

class ZampApp extends StatelessWidget {
  const ZampApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Definizione del colore azzurro personalizzato.
    final Color azzurro = Color(0xFF73AAEA);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ZampApp',
      // Imposta il tema dell'intera applicazione.
      theme: ThemeData(
        // Utilizza ColorScheme.fromSeed per un tema moderno basato su un colore "seme".
        colorScheme: ColorScheme.fromSeed(seedColor: azzurro),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}