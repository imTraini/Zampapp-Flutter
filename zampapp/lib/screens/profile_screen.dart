import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'edit_profile_screen.dart'; // <-- 1. IMPORTA LA NUOVA SCHERMATA

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> _fetchProfileData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      DocumentSnapshot userDoc = await _firestore.collection('utenti').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        data['accountType'] = 'utente';
        return data;
      }

      DocumentSnapshot shelterDoc = await _firestore.collection('canili').doc(user.uid).get();
      if (shelterDoc.exists) {
        final data = shelterDoc.data() as Map<String, dynamic>;
        data['accountType'] = 'canile';
        return data;
      }
    } catch (e) {
      debugPrint("Errore nel fetch del profilo: $e");
      rethrow;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchProfileData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Si è verificato un errore: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("Profilo non trovato. Prova a registrarti di nuovo."));
          }

          final profileData = snapshot.data!;
          final accountType = profileData['accountType'];
          final isShelter = accountType == 'canile';

          final name = isShelter
              ? profileData['nomeCanile'] ?? 'Nome Canile non disp.'
              : '${profileData['nome'] ?? ''} ${profileData['cognome'] ?? ''}'.trim();
          final email = profileData['email'] ?? _auth.currentUser?.email ?? 'N/D';
          final profilePicUrl = profileData['profilePicUrl'];

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {}); // Ricarica i dati quando l'utente "tira" verso il basso
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: profilePicUrl != null && profilePicUrl.isNotEmpty
                          ? CachedNetworkImageProvider(profilePicUrl)
                          : null,
                      child: profilePicUrl == null || profilePicUrl.isEmpty
                          ? const Icon(Icons.person, size: 50, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(name, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
                    const SizedBox(height: 4),
                    Text(email, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Modifica Profilo'),
                      onPressed: () {
                        // --- 2. AZIONE MODIFICATA ---
                        // Naviga alla schermata di modifica, passando i dati caricati.
                        // Quando torneremo indietro, la pagina si aggiornerà.
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => EditProfileScreen(initialData: profileData),
                          ),
                        ).then((_) => setState(() {})); // Ricarica lo stato al ritorno
                      },
                    ),
                    const Divider(height: 40),

                    Text(
                      isShelter ? 'I Cani del Canile' : 'I Miei Cani',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(child: Text('Lista cani in costruzione')),
                    ),
                    const SizedBox(height: 24),

                    if (!isShelter) ...[
                      Text(
                        'Stato Adozioni',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(child: Text('Lista stato adozioni in costruzione')),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
