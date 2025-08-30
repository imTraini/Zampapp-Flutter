// lib/widgets/user_adoption_status_list.dart
import '../models/dog_model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/adoption_request.dart';

class UserAdoptionStatusList extends StatelessWidget {
  final String userId;
  const UserAdoptionStatusList({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('richiesteAdozione')
          .where('richiedenteId', isEqualTo: userId)
          .orderBy('dataRichiesta', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Errore nel caricamento delle richieste.'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Text('Non hai nessuna richiesta di adozione attiva.')),
          );
        }

        final requests = snapshot.data!.docs
            .map((doc) => AdoptionRequest.fromFirestore(doc))
            .toList();

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            return _UserAdoptionStatusCard(request: requests[index]);
          },
          separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
        );
      },
    );
  }
}

class _UserAdoptionStatusCard extends StatelessWidget {
  final AdoptionRequest request;
  const _UserAdoptionStatusCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('cani')
          .doc(request.dogId) // supponendo che AdoptionRequest abbia dogId
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const ListTile(
            title: Text("Caricamento..."),
            leading: CircularProgressIndicator(),
          );
        }

        if (!snapshot.data!.exists) {
          return const ListTile(
            title: Text("Cane non trovato"),
          );
        }

        final dog = Dog.fromFirestore(snapshot.data!);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: dog.urlImmagine,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const CircularProgressIndicator(),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                    ),
                  ),
                  title: Text(
                    dog.nome,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("Richiesta: ${request.status}"),
                ),
                const SizedBox(height: 10),
                _AdoptionProgressBar(status: request.status),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AdoptionProgressBar extends StatelessWidget {
  final String status;

  const _AdoptionProgressBar({required this.status});

  static const List<String> steps = [
    'In elaborazione',
    'Attesa moduli',
    'Attesa controllo abitazione',
    'Accettata',
    'Rifiutata',
  ];

  int _getStepIndex(String status) {
    return steps.indexOf(status);
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getStepIndex(status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 50,
          child: Row(
            children: List.generate(steps.length, (index) {
              final isCompleted = index <= currentIndex;

              return Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: isCompleted ? Colors.green : Colors.grey.shade300,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black26),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      steps[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        color: isCompleted ? Colors.green.shade700 : Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
        Row(
          children: List.generate(steps.length - 1, (index) {
            final isCompleted = index < currentIndex;
            return Expanded(
              child: Container(
                height: 2,
                color: isCompleted ? Colors.green : Colors.grey.shade300,
              ),
            );
          }),
        ),
      ],
    );
  }
}
