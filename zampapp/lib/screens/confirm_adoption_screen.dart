import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/dog_model.dart';
import '../models/adoption_request.dart';

class ConfirmAdoptionScreen extends StatefulWidget {
  final Dog dog;

  const ConfirmAdoptionScreen({super.key, required this.dog});

  @override
  State<ConfirmAdoptionScreen> createState() => _ConfirmAdoptionScreenState();
}

class _ConfirmAdoptionScreenState extends State<ConfirmAdoptionScreen> {
  bool _isSending = false;

  String _calculateAge(Timestamp? birthDate) {
    if (birthDate == null) return "Età non specificata";
    final birth = birthDate.toDate();
    final now = DateTime.now();
    int years = now.year - birth.year;
    int months = now.month - birth.month;
    if (months < 0 || (months == 0 && now.day < birth.day)) {
      years--;
      months += 12;
    }
    if (years > 0) return "$years ${years == 1 ? 'anno' : 'anni'}";
    if (months > 0) return "$months ${months == 1 ? 'mese' : 'mesi'}";
    return "Meno di un mese";
  }

  Future<void> _sendAdoptionRequest() async {
    setState(() => _isSending = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Errore: utente non autenticato.'), backgroundColor: Colors.red),
        );
      }
      setState(() => _isSending = false);
      return;
    }

    final userDoc = await FirebaseFirestore.instance.collection('utenti').doc(user.uid).get();
    if (!userDoc.exists) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Errore: dati utente non trovati.'), backgroundColor: Colors.red),
        );
      }
      setState(() => _isSending = false);
      return;
    }
    final userData = userDoc.data();

    if (widget.dog.proprietarioId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Errore: ID canile mancante.'), backgroundColor: Colors.red),
        );
      }
      setState(() => _isSending = false);
      return;
    }

    final newRequest = {
      'richiedenteId': user.uid,
      'canileId': widget.dog.proprietarioId,
      'caneId': widget.dog.id,
      'dataRichiesta': Timestamp.now(),
      'status': 'In elaborazione',
      'richiedenteNome': userData?['nome'] ?? 'N/D',
      'richiedenteCognome': userData?['cognome'] ?? 'N/D',
      'richiedenteEmail': userData?['email'] ?? 'N/D',
      'richiedenteTelefono': userData?['telefono'] ?? 'N/D',
      'richiedenteVia': userData?['via'] ?? 'N/D',
      'richiedenteCitta': userData?['citta'] ?? 'N/D',
      'richiedenteProvincia': userData?['provincia'] ?? 'N/D',
      'dataAggiornamentoStato': null,
    };

    try {
      await FirebaseFirestore.instance.collection('richiesteAdozione').add(newRequest);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Richiesta inviata con successo!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore nell\'invio della richiesta: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conferma Adozione'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            CachedNetworkImage(
              imageUrl: widget.dog.urlImmagine,
              height: 300,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(height: 300, color: Colors.grey.shade300, child: const Center(child: CircularProgressIndicator())),
              errorWidget: (context, url, error) => Container(height: 300, color: Colors.grey.shade300, child: const Icon(Icons.pets, size: 80, color: Colors.grey)),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.dog.nome, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildDetailRow(Icons.pets, 'Razza', widget.dog.razza),
                  _buildDetailRow(Icons.cake, 'Età', _calculateAge(widget.dog.dataNascita)),
                  _buildDetailRow(Icons.straighten, 'Taglia', widget.dog.taglia),
                  _buildDetailRow(widget.dog.sesso.toLowerCase() == 'maschio' ? Icons.male : Icons.female, 'Sesso', widget.dog.sesso),
                  const Divider(height: 32),
                  Text('Descrizione', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(widget.dog.descrizione, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
        child: _isSending
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton.icon(
          icon: const Icon(Icons.favorite),
          label: const Text('INVIA RICHIESTA DI ADOZIONE'),
          onPressed: _sendAdoptionRequest,
          style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600),
          const SizedBox(width: 16),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}