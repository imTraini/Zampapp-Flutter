import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/dog_model.dart';
import '../screens/add_dog_screen.dart';
// Importa la nuova schermata
import '../screens/edit_dog_screen.dart';

class MyDogsList extends StatelessWidget {
  final String accountType;
  final String userId;

  const MyDogsList({
    super.key,
    required this.accountType,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    bool isShelter = accountType == 'canile';

    return StreamBuilder<QuerySnapshot>(
      // Ascolta in tempo reale i cani dell'utente corrente
      stream: FirebaseFirestore.instance
          .collection('cani')
          .where('proprietarioId', isEqualTo: userId)
          .orderBy('dataAggiunta', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Errore nel caricare i cani. Assicurati di aver creato l\'indice su Firebase come da istruzioni.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          // Se non ci sono cani, mostra solo il pulsante per aggiungere
          return _buildAddDogCard(context, isShelter);
        }

        final dogs = snapshot.data!.docs.map((doc) => Dog.fromFirestore(doc)).toList();

        if (isShelter) {
          // Griglia per il canile
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            itemCount: dogs.length + 1, // +1 per il pulsante
            itemBuilder: (context, index) {
              if (index == 0) return _buildAddDogCard(context, isShelter);
              // Rendi la card cliccabile
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => EditDogScreen(dog: dogs[index - 1]),
                    ),
                  );
                },
                child: _buildDogCardContent(context, dogs[index - 1]),
              );
            },
          );
        } else {
          // Lista orizzontale per l'utente
          return SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: dogs.length + 1, // +1 per il pulsante
              itemBuilder: (context, index) {
                if (index == dogs.length) return _buildAddDogCard(context, isShelter);
                // Rendi la card cliccabile
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => EditDogScreen(dog: dogs[index]),
                      ),
                    );
                  },
                  child: _buildDogCardContent(context, dogs[index]),
                );
              },
            ),
          );
        }
      },
    );
  }

  // Card per aggiungere un cane (rimane uguale)
  Widget _buildAddDogCard(BuildContext context, bool isShelter) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => AddDogScreen(accountType: accountType),
        ));
      },
      child: Container(
        width: isShelter ? null : 150,
        margin: isShelter ? null : const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, size: 50, color: Colors.grey),
            SizedBox(height: 8),
            Text('Aggiungi Cane'),
          ],
        ),
      ),
    );
  }

  // Contenuto della card del cane (spostato in una funzione separata)
  Widget _buildDogCardContent(BuildContext context, Dog dog) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: CachedNetworkImage(
                imageUrl: dog.urlImmagine,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.grey.shade300),
                errorWidget: (context, url, error) => const Icon(Icons.pets, color: Colors.grey),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(dog.nome, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis,),
            ),
          ],
        ),
      ),
    );
  }
}