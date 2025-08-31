import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:zampapp/models/donation_model.dart';

class DonationShelterView extends StatelessWidget {
  const DonationShelterView({super.key});

  @override
  Widget build(BuildContext context) {
    final canileId = FirebaseAuth.instance.currentUser!.uid;
    final theme = Theme.of(context);

    return Column(
      children: [
        StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('canili').doc(canileId).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(child: Text('Errore nel caricare il saldo: ${snapshot.error}', textAlign: TextAlign.center)),
              );
            }

            final data = snapshot.data!.data() as Map<String, dynamic>?;
            final tokens = data?['tokens'] ?? 0;
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Saldo attuale: $tokens token',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
            );
          },
        ),

        const Divider(),

        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Storico Donazioni Ricevute',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('donazioni')
                .where('riceventeId', isEqualTo: canileId)
                .orderBy('dataDonazione', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Errore nel caricare lo storico: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('Nessuna donazione ricevuta.'));
              }

              final donations = snapshot.data!.docs.map((doc) => Donation.fromFirestore(doc)).toList();

              return ListView.builder(
                itemCount: donations.length,
                itemBuilder: (context, index) {
                  final donation = donations[index];
                  final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(donation.dataDonazione.toDate());

                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.volunteer_activism)),
                    title: Text('${donation.donatoreNome} ti ha donato ${donation.importo} token'),
                    subtitle: Text(formattedDate),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}