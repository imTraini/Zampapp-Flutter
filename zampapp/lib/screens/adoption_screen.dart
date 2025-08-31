import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'confirm_adoption_screen.dart';
import '../models/dog_model.dart';
import '../models/adoption_request.dart';

class AdoptionScreen extends StatefulWidget {
  const AdoptionScreen({super.key});

  @override
  State<AdoptionScreen> createState() => _AdoptionScreenState();
}

class _AdoptionScreenState extends State<AdoptionScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _accountType;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _detectAccountType();
  }

  Future<void> _detectAccountType() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final shelterDoc = await _firestore.collection('canili').doc(user.uid).get();
    if (shelterDoc.exists) {
      if (mounted) {
        setState(() {
          _accountType = 'canile';
          _isLoading = false;
        });
      }
      return;
    }

    final userDoc = await _firestore.collection('utenti').doc(user.uid).get();
    if (userDoc.exists) {
      if (mounted) {
        setState(() {
          _accountType = 'utente';
          _isLoading = false;
        });
      }
      return;
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adozioni'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (_accountType) {
      case 'utente':
        return _buildUserView();
      case 'canile':
        return _buildCanileView();
      default:
        return const Center(
          child: Text('Tipo di account non riconosciuto. Accedi per continuare.'),
        );
    }
  }

  Widget _buildUserView() {
    final userId = _auth.currentUser!.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('richiesteAdozione')
          .where('richiedenteId', isEqualTo: userId)
          .snapshots(),
      builder: (context, requestSnapshot) {
        if (requestSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final requestedDogIds = requestSnapshot.hasData
            ? requestSnapshot.data!.docs.map((doc) => doc['caneId'] as String).toSet()
            : <String>{};

        return StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('cani')
              .where('status', isEqualTo: 'di_canile')
              .snapshots(),
          builder: (context, dogSnapshot) {
            if (dogSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!dogSnapshot.hasData || dogSnapshot.data!.docs.isEmpty) {
              return const Center(child: Text('Nessun cane disponibile per l\'adozione al momento.'));
            }

            final dogs = dogSnapshot.data!.docs
                .map((doc) => Dog.fromFirestore(doc))
                .toList();

            return GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
                childAspectRatio: 0.8,
              ),
              itemCount: dogs.length,
              itemBuilder: (context, index) {
                final dog = dogs[index];
                final isRequested = requestedDogIds.contains(dog.id);
                return _DogCard(
                  dog: dog,
                  isRequested: isRequested,
                  onTap: () => _onDogTapped(dog),
                );
              },
            );
          },
        );
      },
    );
  }

  void _onDogTapped(Dog dog) async {
    final userId = _auth.currentUser!.uid;

    final existingRequest = await _firestore
        .collection('richiesteAdozione')
        .where('richiedenteId', isEqualTo: userId)
        .where('caneId', isEqualTo: dog.id)
        .limit(1)
        .get();

    if (mounted) {
      if (existingRequest.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hai già inviato una richiesta per questo cane.'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ConfirmAdoptionScreen(dog: dog),
          ),
        );
      }
    }
  }


  Widget _buildCanileView() {
    final canileId = _auth.currentUser!.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('richiesteAdozione')
          .where('canileId', isEqualTo: canileId)
          .where('status', isNotEqualTo: 'Rifiutata')
          .orderBy('status')
          .orderBy('dataRichiesta', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Nessuna richiesta di adozione ricevuta.'));
        }

        final requests = snapshot.data!.docs
            .map((doc) => AdoptionRequest.fromFirestore(doc))
            .toList();

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return _RequestCard(
              request: request,
              onTap: () => _showCanileManagementDialog(request),
            );
          },
        );
      },
    );
  }

  void _showCanileManagementDialog(AdoptionRequest request) async {
    final dogDoc = await _firestore.collection('cani').doc(request.dogId).get();

    if (!dogDoc.exists) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Errore: dati del cane non trovati.')));
      return;
    }

    final dog = Dog.fromFirestore(dogDoc);
    final String nomeCompleto = '${request.richiedenteNome ?? ''} ${request.richiedenteCognome ?? ''}'.trim();
    final String indirizzo = '${request.richiedenteVia ?? ''}, ${request.richiedenteCitta ?? ''} (${request.richiedenteProvincia ?? ''})'.trim();
    final (nextStatus, actionText) = switch (request.status) {
      "In elaborazione" => ("Attesa moduli", "Invia moduli idoneità"),
      "Attesa moduli" => ("Attesa controllo abitazione", "Richiedi controllo"),
      "Attesa controllo abitazione" => ("Accettata", "Approva adozione"),
      _ => (null, null)
    };

    if(mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Richiesta per ${dog.nome}'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Dati Richiedente:', style: Theme.of(context).textTheme.titleMedium),
                Text('Nome: $nomeCompleto'),
                Text('Email: ${request.richiedenteEmail ?? 'N/D'}'),
                Text('Telefono: ${request.richiedenteTelefono ?? 'N/D'}'),
                Text('Indirizzo: $indirizzo'),
                const Divider(height: 20),
                Text('Stato Attuale:', style: Theme.of(context).textTheme.titleMedium),
                Text(request.status, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Rifiuta', style: TextStyle(color: Colors.red)),
              onPressed: () {
                _updateRequestStatus(request.id, 'Rifiutata');
                Navigator.of(ctx).pop();
              },
            ),
            if (actionText != null)
              ElevatedButton(
                child: Text(actionText),
                onPressed: () {
                  if (nextStatus == 'Accettata') {
                    _finalizeAdoption(request);
                  } else {
                    _updateRequestStatus(request.id, nextStatus!);
                  }
                  Navigator.of(ctx).pop();
                },
              ),
            TextButton(
              child: const Text('Chiudi'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _updateRequestStatus(String requestId, String newStatus) async {
    try {
      await _firestore.collection('richiesteAdozione').doc(requestId).update({
        'status': newStatus,
        'dataAggiornamentoStato': Timestamp.now(),
      });
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stato aggiornato con successo!'), backgroundColor: Colors.green,));
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore: ${e.toString()}'), backgroundColor: Colors.red,));
    }
  }

  Future<void> _finalizeAdoption(AdoptionRequest request) async {
    try {
      final batch = _firestore.batch();
      final requestRef = _firestore.collection('richiesteAdozione').doc(request.id);
      batch.update(requestRef, {'status': 'Accettata','dataAggiornamentoStato': Timestamp.now()});
      final dogRef = _firestore.collection('cani').doc(request.dogId);
      batch.update(dogRef, {'status': 'di_proprieta','proprietarioId': request.richiedenteId});
      await batch.commit();
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Adozione approvata! Il cane ha un nuovo padrone.'), backgroundColor: Colors.green,));
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore nella finalizzazione: ${e.toString()}'), backgroundColor: Colors.red,));
    }
  }
}

class _DogCard extends StatelessWidget {
  final Dog dog;
  final bool isRequested;
  final VoidCallback onTap;
  const _DogCard({required this.dog, required this.isRequested, required this.onTap});

  String _calculateAge(Timestamp? birthDate) {
    if (birthDate == null) return "Età ignota";
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
    return "Cucciolo";
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      color: isRequested ? Colors.blue.shade50 : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isRequested ? BorderSide(color: Colors.blueAccent, width: 2) : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: CachedNetworkImage(
                imageUrl: dog.urlImmagine,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const Icon(Icons.pets, color: Colors.grey, size: 50),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(dog.nome, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis,),
                      ),
                      if(dog.sesso.toLowerCase() == 'maschio')
                        Icon(Icons.male, color: Colors.blue.shade700)
                      else if(dog.sesso.toLowerCase() == 'femmina')
                        Icon(Icons.female, color: Colors.pink.shade400)
                    ],
                  ),
                  Text(_calculateAge(dog.dataNascita), style: Theme.of(context).textTheme.bodySmall,),
                ],
              ),
            ),
            if (isRequested)
              Container(
                color: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: const Text('RICHIESTO', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),),
              )
          ],
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final AdoptionRequest request;
  final VoidCallback onTap;
  const _RequestCard({required this.request, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final nomeCompleto = '${request.richiedenteNome ?? ''} ${request.richiedenteCognome ?? ''}'.trim();

    return FutureBuilder<Dog?>(
      future: _fetchDogDetails(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const ListTile(title: Text("Caricamento..."));
        }
        final dog = snapshot.data;
        final dogName = dog?.nome ?? "Cane non trovato";

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: dog != null ? CachedNetworkImageProvider(dog.urlImmagine) : null,
                        child: dog == null ? const Icon(Icons.pets) : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dogName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('Richiesta da: $nomeCompleto', style: Theme.of(context).textTheme.bodyMedium),
                            Text('Data: ${DateFormat.yMMMd('it_IT').format(request.dataRichiesta.toDate())}', style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _AdoptionProgressBar(status: request.status),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<Dog?> _fetchDogDetails() async {
    final firestore = FirebaseFirestore.instance;
    final dogDoc = await firestore.collection('cani').doc(request.dogId).get();
    if (dogDoc.exists) {
      return Dog.fromFirestore(dogDoc);
    }
    return null;
  }
}

class _AdoptionProgressBar extends StatelessWidget {
  final String status;
  const _AdoptionProgressBar({required this.status});

  @override
  Widget build(BuildContext context) {
    const activeColor = Colors.blueAccent;
    final inactiveColor = Colors.grey.shade300;
    const rejectedColor = Colors.red;
    Color step1Color, line1Color, step2Color, line2Color, step3Color, line3Color, step4Color;

    if (status == 'Rifiutata') {
      step1Color = line1Color = step2Color = line2Color = step3Color = line3Color = step4Color = rejectedColor;
    } else {
      step1Color = activeColor;
      line1Color = (status == 'Attesa moduli' || status == 'Attesa controllo abitazione' || status == 'Accettata') ? activeColor : inactiveColor;
      step2Color = (status == 'Attesa moduli' || status == 'Attesa controllo abitazione' || status == 'Accettata') ? activeColor : inactiveColor;
      line2Color = (status == 'Attesa controllo abitazione' || status == 'Accettata') ? activeColor : inactiveColor;
      step3Color = (status == 'Attesa controllo abitazione' || status == 'Accettata') ? activeColor : inactiveColor;
      line3Color = (status == 'Accettata') ? activeColor : inactiveColor;
      step4Color = (status == 'Accettata') ? activeColor : inactiveColor;
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStep(step1Color), _buildLine(line1Color),
            _buildStep(step2Color), _buildLine(line2Color),
            _buildStep(step3Color), _buildLine(line3Color),
            _buildStep(step4Color),
          ],
        ),
        const SizedBox(height: 4),
        Text(status, style: TextStyle(color: status == 'Rifiutata' ? rejectedColor : activeColor, fontWeight: FontWeight.bold)),
      ],
    );
  }
  Widget _buildStep(Color color) => Icon(Icons.check_circle, color: color, size: 24);
  Widget _buildLine(Color color) => Expanded(child: Container(height: 3, color: color));
}
