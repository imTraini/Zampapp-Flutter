import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'edit_profile_screen.dart';
import '../widgets/my_dogs_list.dart'; // <-- 1. IMPORTA IL NUOVO WIDGET
import '../widgets/user_adoption_status_list.dart'; // <-- AGGIUNGI QUESTO

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
              setState(() {});
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column( // Rimuovi il Center per allineare a sinistra
                crossAxisAlignment: CrossAxisAlignment.stretch, // Allunga i figli
                children: [
                  // --- Sezione Intestazione Profilo (centrata) ---
                  Column(
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
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => EditProfileScreen(initialData: profileData),
                            ),
                          ).then((_) => setState(() {}));
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 40),

                  // --- Sezione "I Miei Cani" ---
                  Text(
                    isShelter ? 'I Cani del Canile' : 'I Miei Cani',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),

                  // --- 2. SOSTITUISCI IL CONTAINER CON IL NUOVO WIDGET ---
                  MyDogsList(
                    accountType: accountType,
                    userId: _auth.currentUser!.uid,
                  ),

                  const SizedBox(height: 24),

                  // --- Sezione "Stato Adozioni" (solo per utenti) ---
                  // --- Sezione "Stato Adozioni" (solo per utenti) ---
                  if (!isShelter) ...[
                    Text(
                      'Stato Adozioni',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    UserAdoptionStatusList(userId: _auth.currentUser!.uid),
                  ],

                ],
              ),
            ),
          );
        },
      ),
    );
  }
}