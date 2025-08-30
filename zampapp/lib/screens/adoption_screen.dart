// lib/screens/adoption_screen.dart

import 'package:flutter/material.dart';

class AdoptionScreen extends StatelessWidget {
  const AdoptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Qui andrai a ricreare la logica del tuo AdozioniFragment.kt
    // Dovrai rilevare il tipo di account (utente o canile) e mostrare
    // la UI corrispondente per visualizzare i cani o le richieste.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adozioni'),
      ),
      body: const Center(
        child: Text(
          'Schermata Adozioni - In costruzione',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}