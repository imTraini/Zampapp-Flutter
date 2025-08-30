// lib/screens/donation_screen.dart

import 'package:flutter/material.dart';

class DonationScreen extends StatelessWidget {
  const DonationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Qui andrai a ricreare la logica dei tuoi DonationUserFragment.kt
    // e DonationCanileFragment.kt.
    // Rileva il tipo di utente e mostra la UI per donare o per vedere
    // lo storico delle donazioni ricevute.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Donazioni'),
      ),
      body: const Center(
        child: Text(
          'Schermata Donazioni - In costruzione',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}