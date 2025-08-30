import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;

  const EditProfileScreen({super.key, required this.initialData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  File? _selectedImage;
  late String _accountType;
  late String _currentImageUrl;

  // Controllers per ogni campo del form
  final Map<String, TextEditingController> _controllers = {
    'nome': TextEditingController(),
    'cognome': TextEditingController(),
    'username': TextEditingController(),
    'telefono': TextEditingController(),
    'email': TextEditingController(),
    'paese': TextEditingController(),
    'provincia': TextEditingController(),
    'citta': TextEditingController(),
    'cap': TextEditingController(),
    'via': TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    _accountType = widget.initialData['accountType'];
    _currentImageUrl = widget.initialData['profilePicUrl'] ?? '';
    _initializeFields();
  }

  void _initializeFields() {
    final data = widget.initialData;
    if (_accountType == 'canile') {
      _controllers['nome']?.text = data['nomeCanile'] ?? '';
    } else {
      _controllers['nome']?.text = data['nome'] ?? '';
      _controllers['cognome']?.text = data['cognome'] ?? '';
      _controllers['username']?.text = data['username'] ?? '';
    }
    _controllers['telefono']?.text = data['telefono'] ?? '';
    _controllers['email']?.text = data['email'] ?? '';
    _controllers['paese']?.text = data['paese'] ?? '';
    _controllers['provincia']?.text = data['provincia'] ?? '';
    _controllers['citta']?.text = data['citta'] ?? '';
    _controllers['cap']?.text = data['cap'] ?? '';
    _controllers['via']?.text = data['via'] ?? '';
  }

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _saveUserProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isLoading = true; });

    try {
      String? newImageUrl;
      final user = FirebaseAuth.instance.currentUser!;

      // 1. Carica la nuova immagine (se selezionata)
      if (_selectedImage != null) {
        final ref = FirebaseStorage.instance.ref().child('profile_pics').child('${user.uid}.jpg');
        await ref.putFile(_selectedImage!);
        newImageUrl = await ref.getDownloadURL();
      }

      // 2. Prepara i dati da aggiornare
      Map<String, dynamic> updates;
      if (_accountType == 'canile') {
        updates = {
          'nomeCanile': _controllers['nome']!.text.trim(),
          'telefono': _controllers['telefono']!.text.trim(),
          'email': _controllers['email']!.text.trim(),
          'paese': _controllers['paese']!.text.trim(),
          'provincia': _controllers['provincia']!.text.trim(),
          'citta': _controllers['citta']!.text.trim(),
          'cap': _controllers['cap']!.text.trim(),
          'via': _controllers['via']!.text.trim(),
        };
      } else {
        updates = {
          'nome': _controllers['nome']!.text.trim(),
          'cognome': _controllers['cognome']!.text.trim(),
          'username': _controllers['username']!.text.trim(),
          'telefono': _controllers['telefono']!.text.trim(),
          'email': _controllers['email']!.text.trim(),
          'paese': _controllers['paese']!.text.trim(),
          'provincia': _controllers['provincia']!.text.trim(),
          'citta': _controllers['citta']!.text.trim(),
          'cap': _controllers['cap']!.text.trim(),
          'via': _controllers['via']!.text.trim(),
        };
      }
      if (newImageUrl != null) {
        updates['profilePicUrl'] = newImageUrl;
      }

      // 3. Salva i dati in Firestore
      final collectionName = _accountType == 'canile' ? 'canili' : 'utenti';
      await FirebaseFirestore.instance.collection(collectionName).doc(user.uid).set(updates, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profilo aggiornato!'), backgroundColor: Colors.green));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if(mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  @override
  void dispose() {
    _controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isShelter = _accountType == 'canile';

    return Scaffold(
      appBar: AppBar(title: const Text('Modifica Profilo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: _selectedImage != null
                      ? FileImage(_selectedImage!)
                      : (_currentImageUrl.isNotEmpty ? CachedNetworkImageProvider(_currentImageUrl) : null) as ImageProvider?,
                  child: _selectedImage == null && _currentImageUrl.isEmpty
                      ? const Icon(Icons.person, size: 50, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              const Text('Tocca per cambiare immagine'),
              const SizedBox(height: 24),
              _buildTextFormField(
                controller: _controllers['nome']!,
                labelText: isShelter ? 'Nome Canile' : 'Nome',
              ),
              if (!isShelter) ...[
                _buildTextFormField(controller: _controllers['cognome']!, labelText: 'Cognome'),
                _buildTextFormField(controller: _controllers['username']!, labelText: 'Username'),
              ],
              _buildTextFormField(controller: _controllers['telefono']!, labelText: 'Telefono', keyboardType: TextInputType.phone),
              _buildTextFormField(controller: _controllers['email']!, labelText: 'Email', keyboardType: TextInputType.emailAddress, enabled: false), // L'email non dovrebbe essere modificabile
              _buildTextFormField(controller: _controllers['via']!, labelText: 'Via'),
              _buildTextFormField(controller: _controllers['citta']!, labelText: 'Città'),
              _buildTextFormField(controller: _controllers['provincia']!, labelText: 'Provincia'),
              _buildTextFormField(controller: _controllers['cap']!, labelText: 'CAP', keyboardType: TextInputType.number),
              _buildTextFormField(controller: _controllers['paese']!, labelText: 'Paese'),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveUserProfile,
                  child: const Text('SALVA MODIFICHE'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: labelText,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (labelText != 'Cognome' && labelText != 'Username' && (value == null || value.isEmpty)) {
            return 'Questo campo è obbligatorio.';
          }
          if (labelText == 'CAP' && value!.length != 5) {
            return 'Il CAP deve essere di 5 cifre.';
          }
          return null;
        },
      ),
    );
  }
}
