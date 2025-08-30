import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart'; // Aggiungi questa dipendenza se non l'hai già

class AddDogScreen extends StatefulWidget {
  final String accountType;
  const AddDogScreen({super.key, required this.accountType});

  @override
  State<AddDogScreen> createState() => _AddDogScreenState();
}

class _AddDogScreenState extends State<AddDogScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  File? _selectedImage;

  // Controllers per i campi
  final _nomeController = TextEditingController();
  final _razzaController = TextEditingController();
  final _descrizioneController = TextEditingController();
  final _dataNascitaController = TextEditingController();
  DateTime? _selectedDate;
  String? _sesso;
  String? _taglia;

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() => _selectedImage = File(image.path));
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dataNascitaController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _saveDog() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Per favore, seleziona un\'immagine.')));
      return;
    }

    setState(() { _isLoading = true; });

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final ref = FirebaseStorage.instance.ref().child('dog_images').child('${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(_selectedImage!);
      final imageUrl = await ref.getDownloadURL();

      final dogStatus = widget.accountType == 'canile' ? 'di_canile' : 'di_proprieta';

      final dogData = {
        'nome': _nomeController.text.trim(),
        'razza': _razzaController.text.trim(),
        'descrizione': _descrizioneController.text.trim(),
        'dataNascita': _selectedDate != null ? Timestamp.fromDate(_selectedDate!) : null,
        'sesso': _sesso,
        'taglia': _taglia,
        'urlImmagine': imageUrl,
        'proprietarioId': user.uid,
        'status': dogStatus,
        'dataAggiunta': Timestamp.now(),
      };

      await FirebaseFirestore.instance.collection('cani').add(dogData);

      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cane aggiunto con successo!'), backgroundColor: Colors.green));
        Navigator.of(context).pop();
      }

    } catch (e) {
      if(mounted) {
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
    _nomeController.dispose();
    _razzaController.dispose();
    _descrizioneController.dispose();
    _dataNascitaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aggiungi Cane')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: _selectedImage != null ? FileImage(_selectedImage!) : null,
                    child: _selectedImage == null ? const Icon(Icons.add_a_photo, size: 50, color: Colors.white) : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(controller: _nomeController, decoration: const InputDecoration(labelText: 'Nome'), validator: (v) => v!.isEmpty ? 'Campo obbligatorio' : null),
              TextFormField(controller: _razzaController, decoration: const InputDecoration(labelText: 'Razza'), validator: (v) => v!.isEmpty ? 'Campo obbligatorio' : null),
              TextFormField(controller: _descrizioneController, decoration: const InputDecoration(labelText: 'Descrizione'), maxLines: 3, validator: (v) => v!.isEmpty ? 'Campo obbligatorio' : null),
              TextFormField(controller: _dataNascitaController, readOnly: true, onTap: () => _selectDate(context), decoration: const InputDecoration(labelText: 'Data di Nascita'), validator: (v) => v!.isEmpty ? 'Campo obbligatorio' : null),
              const SizedBox(height: 16),
              const Text('Sesso', style: TextStyle(fontSize: 16)),
              DropdownButtonFormField<String>(value: _sesso, items: ['Maschio', 'Femmina'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: (v) => setState(() => _sesso = v), validator: (v) => v == null ? 'Campo obbligatorio' : null),
              const SizedBox(height: 16),
              const Text('Taglia', style: TextStyle(fontSize: 16)),
              DropdownButtonFormField<String>(value: _taglia, items: ['Piccola', 'Media', 'Grande'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (v) => setState(() => _taglia = v), validator: (v) => v == null ? 'Campo obbligatorio' : null),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _saveDog, child: const Text('SALVA CANE'))),
            ],
          ),
        ),
      ),
    );
  }
}