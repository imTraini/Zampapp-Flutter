import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserSignUpScreen extends StatefulWidget {
  const UserSignUpScreen({super.key});

  @override
  State<UserSignUpScreen> createState() => _UserSignUpScreenState();
}

class _UserSignUpScreenState extends State<UserSignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _nomeController = TextEditingController();
  final _cognomeController = TextEditingController();
  final _usernameController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _paeseController = TextEditingController();
  final _provinciaController = TextEditingController();
  final _cittaController = TextEditingController();
  final _capController = TextEditingController();
  final _viaController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confermaPasswordController = TextEditingController();

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_passwordController.text != _confermaPasswordController.text) {
        throw 'Le password non corrispondono.';
      }

      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final userUid = userCredential.user?.uid;
      if (userUid == null) {
        throw 'Errore: UID utente non disponibile.';
      }

      final userData = {
        "nome": _nomeController.text.trim(),
        "cognome": _cognomeController.text.trim(),
        "username": _usernameController.text.trim(),
        "telefono": _telefonoController.text.trim(),
        "email": _emailController.text.trim(),
        "paese": _paeseController.text.trim(),
        "provincia": _provinciaController.text.trim(),
        "citta": _cittaController.text.trim(),
        "cap": _capController.text.trim(),
        "via": _viaController.text.trim(),
        "tokens": 500,
        "accountType": "utente",
      };

      await FirebaseFirestore.instance.collection("utenti").doc(userUid).set(userData);

      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registrazione avvenuta con successo!'),
            backgroundColor: Colors.green,
          ),
        );
        // Torna indietro di 2 schermate (Signup e Scelta) per arrivare al Login
        int count = 0;
        Navigator.of(context).popUntil((_) => count++ >= 2);
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
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cognomeController.dispose();
    _usernameController.dispose();
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
        title: const Text('Registrazione Utente'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildTextFormField(controller: _nomeController, labelText: 'Nome'),
                _buildTextFormField(controller: _cognomeController, labelText: 'Cognome'),
                _buildTextFormField(controller: _usernameController, labelText: 'Username'),
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
                    onPressed: _signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('REGISTRATI'),
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
          return null;
        },
      ),
    );
  }
}
