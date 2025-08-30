import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ShelterSignUpScreen extends StatefulWidget {
  const ShelterSignUpScreen({super.key});

  @override
  State<ShelterSignUpScreen> createState() => _ShelterSignUpScreenState();
}

class _ShelterSignUpScreenState extends State<ShelterSignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers per tutti i campi del form
  final _nomeCanileController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _paeseController = TextEditingController();
  final _provinciaController = TextEditingController();
  final _cittaController = TextEditingController();
  final _capController = TextEditingController();
  final _viaController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confermaPasswordController = TextEditingController();

  Future<void> _signUpShelter() async {
    // 1. Valida l'input del form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() { _isLoading = true; });

    try {
      // 2. Controlla che le password corrispondano
      if (_passwordController.text != _confermaPasswordController.text) {
        throw 'Le password non corrispondono.';
      }

      // 3. Crea l'utente in Firebase Authentication
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = userCredential.user;
      if (user == null) {
        throw 'Errore: UID utente non disponibile dopo la registrazione.';
      }

      // 4. Prepara i dati da salvare in Firestore
      final canileData = {
        "nomeCanile": _nomeCanileController.text.trim(),
        "telefono": _telefonoController.text.trim(),
        "email": _emailController.text.trim(),
        "paese": _paeseController.text.trim(),
        "provincia": _provinciaController.text.trim(),
        "citta": _cittaController.text.trim(),
        "cap": _capController.text.trim(),
        "via": _viaController.text.trim(),
        "tokens": 0, // Inizializza i token a 0 per i canili
        "accountType": "canile",
      };

      // 5. Salva il documento nella collezione 'canili' con l'UID dell'utente
      await FirebaseFirestore.instance.collection("canili").doc(user.uid).set(canileData);

      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registrazione del canile avvenuta con successo!'),
            backgroundColor: Colors.green,
          ),
        );
        // Torna indietro fino alla prima schermata dello stack (login/auth_gate)
        Navigator.of(context).popUntil((route) => route.isFirst);
      }

    } catch (e) {
      if (mounted) {
        String errorMessage = "Si è verificato un errore.";
        if (e is FirebaseAuthException) {
          errorMessage = e.message ?? errorMessage;
        } else {
          errorMessage = e.toString();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  void dispose() {
    _nomeCanileController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _paeseController.dispose();
    _provinciaController.dispose();
    _cittaController.dispose();
    _capController.dispose();
    _viaController.dispose();
    _passwordController.dispose();
    _confermaPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrazione Canile'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildTextFormField(controller: _nomeCanileController, labelText: 'Nome Canile'),
                _buildTextFormField(controller: _telefonoController, labelText: 'Telefono', keyboardType: TextInputType.phone),
                _buildTextFormField(controller: _emailController, labelText: 'Email', keyboardType: TextInputType.emailAddress),
                _buildTextFormField(controller: _paeseController, labelText: 'Paese'),
                _buildTextFormField(controller: _provinciaController, labelText: 'Provincia'),
                _buildTextFormField(controller: _cittaController, labelText: 'Città'),
                _buildTextFormField(controller: _capController, labelText: 'CAP', keyboardType: TextInputType.number),
                _buildTextFormField(controller: _viaController, labelText: 'Via'),
                _buildTextFormField(controller: _passwordController, labelText: 'Password', obscureText: true),
                _buildTextFormField(controller: _confermaPasswordController, labelText: 'Conferma Password', obscureText: true),
                const SizedBox(height: 24),
                _isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _signUpShelter,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('REGISTRA CANILE'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: labelText,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Questo campo è obbligatorio.';
          }
          if (labelText == 'CAP' && value.length != 5) {
            return 'Il CAP deve essere di 5 cifre.';
          }
          return null;
        },
      ),
    );
  }
}