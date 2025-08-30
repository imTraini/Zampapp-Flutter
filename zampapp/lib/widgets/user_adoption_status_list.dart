import '../models/dog_model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/adoption_request.dart';
import 'package:intl/intl.dart';

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

        final allRequests = snapshot.data!.docs
            .map((doc) => AdoptionRequest.fromFirestore(doc))
            .toList();

        final now = DateTime.now();
        final oneMonthAgo = now.subtract(const Duration(days: 30));

        final visibleRequests = allRequests.where((request) {
          final isFinalStatus = request.status == "Accettata" || request.status == "Rifiutata";
          final requestDate = request.dataRichiesta.toDate();
          final updateDate = request.dataAggiornamentoStato?.toDate();

          // Display final status requests for 1 month after update
          if (isFinalStatus) {
            return updateDate != null && updateDate.isAfter(oneMonthAgo);
          } else {
            // Display pending requests for 1 month after creation
            return requestDate.isAfter(oneMonthAgo);
          }
        }).toList();

        if (visibleRequests.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Text('Nessuna richiesta di adozione recente da visualizzare.')),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visibleRequests.length,
          itemBuilder: (context, index) {
            return _UserAdoptionStatusCard(request: visibleRequests[index]);
          },
          separatorBuilder: (context, index) => const SizedBox(height: 8), // Spazio tra le card
        );
      },
    );
  }
}

class _UserAdoptionStatusCard extends StatelessWidget {
  final AdoptionRequest request;
  const _UserAdoptionStatusCard({required this.request});

  // Funzione per ottenere il nome del canile (rimane invariata)
  Future<String> _fetchShelterName() async {
    if (request.canileId == null) return "Canile non trovato";
    final firestore = FirebaseFirestore.instance;
    final shelterDoc = await firestore.collection('canili').doc(request.canileId).get();
    if (shelterDoc.exists) {
      return shelterDoc.data()?['nomeCanile'] ?? "Canile Sconosciuto";
    }
    return "Canile non trovato";
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('cani')
          .doc(request.dogId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Card(
              elevation: 0.5,
              child: ListTile(
                title: Text("Caricamento..."),
                leading: CircularProgressIndicator(),
              ),
            ),
          );
        }

        if (!snapshot.data!.exists) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Card(
              elevation: 0.5,
              child: ListTile(
                title: Text("Cane non trovato"),
              ),
            ),
          );
        }

        final dog = Dog.fromFirestore(snapshot.data!);

        // Definisci i colori in base allo stato
        Color statusColor = Colors.orange; // Colore di default per "In elaborazione"
        if (request.status == "Accettata") {
          statusColor = Colors.green.shade700;
        } else if (request.status == "Rifiutata") {
          statusColor = Colors.red.shade700;
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28, // Dimensione leggermente più grande
                      backgroundImage: CachedNetworkImageProvider(dog.urlImmagine),
                      onBackgroundImageError: (exception, stackTrace) => const Icon(Icons.pets),
                      backgroundColor: Colors.grey.shade200,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dog.nome,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          // Rimosso "Richiesta a: Canile..."
                          Text(
                            'Data: ${DateFormat('dd MMM yyyy', 'it_IT').format(request.dataRichiesta.toDate())}', // Formato più compatto
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            request.status, // Mostra lo stato corrente
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
    'Inviata', // Rinominato 'In elaborazione' a 'Inviata' per chiarezza
    'Moduli',
    'Controllo',
    'Accettata',
    'Rifiutata', // Lasciamo Rifiutata come stato finale ma visualizzabile
  ];

  int _getStepIndex(String currentStatus) {
    if (currentStatus == 'In elaborazione') return 0; // Mappa 'In elaborazione' a 'Inviata'
    return steps.indexOf(currentStatus);
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getStepIndex(status);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0), // Padding per la barra di progresso
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(steps.length, (index) {
              final isCompleted = index <= currentIndex;
              final isCurrent = index == currentIndex;
              final isFinalAndRejected = (status == "Rifiutata" && index == steps.length - 1);
              final isFinalAndAccepted = (status == "Accettata" && index == steps.length - 2);


              Color dotColor = Colors.grey.shade400;
              if (isCompleted && !isFinalAndRejected) { // Non colorare di verde se è rifiutata
                dotColor = Colors.blue; // Colore blu per i passi completati
              }
              if (isFinalAndRejected) {
                dotColor = Colors.red; // Rosso per stato rifiutato
              }
              if (isFinalAndAccepted) {
                dotColor = Colors.green; // Verde per stato accettato
              }
              if (isCurrent && !isFinalAndRejected && !isFinalAndAccepted) {
                dotColor = Theme.of(context).primaryColor; // Colore primario per lo stato attuale
              }


              return Expanded(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: dotColor.withOpacity(isCompleted ? 1.0 : 0.3), // Colore più tenue per non completati
                            shape: BoxShape.circle,
                            border: Border.all(color: dotColor, width: 1.5),
                          ),
                          child: isCompleted
                              ? Icon(Icons.check, color: Colors.white, size: 14)
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 8),
        // Linea di collegamento
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: List.generate(steps.length - 1, (index) {
              final isCompletedSegment = index < currentIndex;
              Color lineColor = Colors.grey.shade300;
              if (isCompletedSegment && !(status == "Rifiutata" && index >= _getStepIndex("Accettata"))) {
                lineColor = Colors.blue; // Linea blu per segmenti completati
              } else if (status == "Rifiutata" && index == _getStepIndex("Moduli") ||
                  status == "Rifiutata" && index == _getStepIndex("Controllo")) {
                lineColor = Colors.red; // Linea rossa se rifiutato a un passo intermedio
              }


              return Expanded(
                child: Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: lineColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(steps.length, (index) {
            final isCurrent = index == currentIndex;
            final isFinalAndRejected = (status == "Rifiutata" && index == steps.length - 1);
            final isFinalAndAccepted = (status == "Accettata" && index == steps.length - 2);

            Color textColor = Colors.grey.shade600;
            FontWeight textWeight = FontWeight.normal;

            if (isFinalAndRejected && index == steps.length -1) {
              textColor = Colors.red.shade700;
              textWeight = FontWeight.bold;
            } else if (isFinalAndAccepted && index == steps.length -2) {
              textColor = Colors.green.shade700;
              textWeight = FontWeight.bold;
            } else if (isCurrent) {
              textColor = Theme.of(context).primaryColor; // Colore primario per il testo dello stato attuale
              textWeight = FontWeight.bold;
            }

            return Expanded(
              child: Text(
                steps[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: textColor,
                  fontWeight: textWeight,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}