import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'home_screen.dart'; // Importa la nuova schermata principale

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Se l'utente non è loggato, mostra la schermata di login
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        // Se l'utente è loggato, mostra la HomeScreen con la navbar!
        return const HomeScreen();
      },
    );
  }
}
