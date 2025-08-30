import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/donation_views/donation_user_view.dart';
import '../widgets/donation_views/donation_shelter_view.dart';

class DonationScreen extends StatefulWidget {
  const DonationScreen({super.key});

  @override
  State<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  Future<String?> _getAccountType() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final userDoc = await FirebaseFirestore.instance.collection('utenti').doc(user.uid).get();
    if (userDoc.exists) return 'utente';

    final shelterDoc = await FirebaseFirestore.instance.collection('canili').doc(user.uid).get();
    if (shelterDoc.exists) return 'canile';

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Donazioni'),
      ),
      body: FutureBuilder<String?>(
        future: _getAccountType(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Tipo di account non riconosciuto.'));
          }

          if (snapshot.data == 'utente') {
            return const DonationUserView();
          } else {
            return const DonationShelterView();
          }
        },
      ),
    );
  }
}