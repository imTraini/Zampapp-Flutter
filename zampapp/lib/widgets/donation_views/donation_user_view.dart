import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/shelter_model.dart';

class DonationUserView extends StatefulWidget {
  const DonationUserView({super.key});

  @override
  State<DonationUserView> createState() => _DonationUserViewState();
}

class _DonationUserViewState extends State<DonationUserView> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _amountController = TextEditingController();

  List<Shelter> _shelters = [];
  Shelter? _selectedShelter;
  int _userTokens = 0;
  String _userFullName = 'Donatore';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([_loadUserData(), _loadShelters()]);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUserData() async {
    final userDoc = await _db.collection('utenti').doc(_auth.currentUser!.uid).get();
    if (userDoc.exists) {
      final data = userDoc.data()!;
      _userTokens = data['tokens'] ?? 0;
      _userFullName = '${data['nome'] ?? ''} ${data['cognome'] ?? ''}'.trim();
    }
  }

  Future<void> _loadShelters() async {
    final querySnapshot = await _db.collection('canili').get();
    _shelters = querySnapshot.docs.map((doc) {
      return Shelter(uid: doc.id, nome: doc.data()['nomeCanile'] ?? 'Nome non disp.');
    }).toList();
  }

  Future<void> _performDonation() async {
    final amount = int.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inserisci un importo valido.')));
      return;
    }
    if (_selectedShelter == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seleziona un canile.')));
      return;
    }
    if (amount > _userTokens) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Non hai abbastanza token.')));
      return;
    }

    setState(() => _isLoading = true);

    final donatoreRef = _db.collection('utenti').doc(_auth.currentUser!.uid);
    final riceventeRef = _db.collection('canili').doc(_selectedShelter!.uid);

    try {
      final newTokens = await _db.runTransaction<int>((transaction) async {
        final donatoreSnapshot = await transaction.get(donatoreRef);
        final riceventeSnapshot = await transaction.get(riceventeRef);

        final donatoreTokens = donatoreSnapshot.data()!['tokens'] ?? 0;
        final riceventeTokens = riceventeSnapshot.data()!['tokens'] ?? 0;

        if (donatoreTokens < amount) {
          throw Exception("Saldo insufficiente.");
        }

        final nuovoSaldoDonatore = donatoreTokens - amount;
        final nuovoSaldoRicevente = riceventeTokens + amount;

        transaction.update(donatoreRef, {'tokens': nuovoSaldoDonatore});
        transaction.update(riceventeRef, {'tokens': nuovoSaldoRicevente});

        final donazioneRef = _db.collection('donazioni').doc();
        transaction.set(donazioneRef, {
          'donatoreId': _auth.currentUser!.uid,
          'donatoreNome': _userFullName,
          'riceventeId': _selectedShelter!.uid,
          'riceventeNome': _selectedShelter!.nome,
          'importo': amount,
          'dataDonazione': FieldValue.serverTimestamp(),
        });

        return nuovoSaldoDonatore;
      });

      if (mounted) {
        setState(() {
          _userTokens = newTokens;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Donazione effettuata con successo!'), backgroundColor: Colors.green));
      _amountController.clear();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Donazione fallita: ${e.toString()}'), backgroundColor: Colors.red));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _shelters.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('I tuoi token: $_userTokens', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 32),
          DropdownButtonFormField<Shelter>(
            value: _selectedShelter,
            decoration: const InputDecoration(labelText: 'Dona a', border: OutlineInputBorder()),
            items: _shelters.map((shelter) {
              return DropdownMenuItem<Shelter>(value: shelter, child: Text(shelter.nome));
            }).toList(),
            onChanged: (value) => setState(() => _selectedShelter = value),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Importo in token', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _performDonation,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            child: _isLoading ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)) : const Text('DONA ORA'),
          ),
        ],
      ),
    );
  }
}