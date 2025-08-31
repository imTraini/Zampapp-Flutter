import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/dog_model.dart';

class EditDogScreen extends StatefulWidget {
  final Dog dog;

  const EditDogScreen({super.key, required this.dog});

  @override
  State<EditDogScreen> createState() => _EditDogScreenState();
}

class _EditDogScreenState extends State<EditDogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  late TextEditingController _nomeController;
  late TextEditingController _razzaController;
  late TextEditingController _descrizioneController;
  late TextEditingController _dataNascitaController;

  String? _selectedSesso;
  String? _selectedTaglia;
  File? _imageFile;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.dog.nome);
    _razzaController = TextEditingController(text: widget.dog.razza);
    _descrizioneController = TextEditingController(text: widget.dog.descrizione);
    _dataNascitaController = TextEditingController(
      text: widget.dog.dataNascita != null
          ? DateFormat('dd/MM/yyyy').format(widget.dog.dataNascita!.toDate())
          : '',
    );
    // FIX: Assicurati che le variabili di stato siano inizializzate con i dati del cane.
    _selectedSesso = widget.dog.sesso.isNotEmpty ? widget.dog.sesso : null;
    _selectedTaglia = widget.dog.taglia.isNotEmpty ? widget.dog.taglia : null;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _razzaController.dispose();
    _descrizioneController.dispose();
    _dataNascitaController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateDog() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      String newImageUrl = widget.dog.urlImmagine;

      try {
        if (_imageFile != null) {
          if (widget.dog.urlImmagine.isNotEmpty && !widget.dog.urlImmagine.contains('default_dog_image.png')) {
            try {
              await _storage.refFromURL(widget.dog.urlImmagine).delete();
            } on FirebaseException catch (e) {
              if (e.code != 'object-not-found') {
                debugPrint("Errore nell'eliminare la vecchia immagine: ${e.message}");
              }
            }
          }

          final ref = _storage.ref().child('dog_images/${widget.dog.proprietarioId}/${DateTime.now().millisecondsSinceEpoch}');
          await ref.putFile(_imageFile!);
          newImageUrl = await ref.getDownloadURL();
        }

        final dogUpdates = {
          'nome': _nomeController.text.trim(),
          'razza': _razzaController.text.trim(),
          'descrizione': _descrizioneController.text.trim(),
          'dataNascita': _dataNascitaController.text.isNotEmpty
              ? Timestamp.fromDate(DateFormat('dd/MM/yyyy').parse(_dataNascitaController.text))
              : null,
          'sesso': _selectedSesso,
          'taglia': _selectedTaglia,
          'urlImmagine': newImageUrl,
          'dataUltimaModifica': Timestamp.now(),
        };

        await _firestore.collection('cani').doc(widget.dog.id).update(dogUpdates);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cane aggiornato con successo!')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        debugPrint("Errore nell'aggiornamento: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Errore nell\'aggiornamento: $e')),
          );
        }
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deleteDog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina Cane'),
        content: const Text('Sei sicuro di voler eliminare questo cane? Questa azione è irreversibile.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final batch = _firestore.batch();
        final adoptionRequests = await _firestore
            .collection('richiesteAdozione')
            .where('dogId', isEqualTo: widget.dog.id)
            .get();

        for (var doc in adoptionRequests.docs) {
          batch.delete(doc.reference);
        }

        final dogRef = _firestore.collection('cani').doc(widget.dog.id);
        batch.delete(dogRef);

        await batch.commit();

        if (widget.dog.urlImmagine.isNotEmpty) {
          await _storage.refFromURL(widget.dog.urlImmagine).delete();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cane eliminato con successo.')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        debugPrint("Errore nell'eliminazione: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Errore nell\'eliminazione: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Modifica ${widget.dog.nome}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _deleteDog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _imageFile != null
                        ? Image.file(_imageFile!, fit: BoxFit.cover)
                        : widget.dog.urlImmagine.isNotEmpty
                        ? CachedNetworkImage(
                      imageUrl: widget.dog.urlImmagine,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) =>
                      const Icon(Icons.pets, size: 50, color: Colors.grey),
                    )
                        : const Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (value) => value!.trim().isEmpty ? 'Campo richiesto' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _razzaController,
                decoration: const InputDecoration(labelText: 'Razza'),
                validator: (value) => value!.trim().isEmpty ? 'Campo richiesto' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dataNascitaController,
                decoration: const InputDecoration(
                  labelText: 'Data di nascita (gg/mm/aaaa)',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: widget.dog.dataNascita?.toDate() ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (pickedDate != null) {
                    _dataNascitaController.text = DateFormat('dd/MM/yyyy').format(pickedDate);
                  }
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Campo richiesto';
                  try {
                    DateFormat('dd/MM/yyyy').parse(value);
                    return null;
                  } catch (e) {
                    return 'Formato data non valido';
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descrizioneController,
                decoration: const InputDecoration(labelText: 'Descrizione'),
                maxLines: 3,
                validator: (value) => value!.trim().isEmpty ? 'Campo richiesto' : null,
              ),
              const SizedBox(height: 16),
              _buildSessoRadio(),
              const SizedBox(height: 16),
              _buildTagliaRadio(), // Qui verrà chiamato il nuovo widget
              const SizedBox(height: 32),
              _isSaving
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _updateDog,
                child: const Text('Aggiorna Cane'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessoRadio() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sesso', style: Theme.of(context).textTheme.titleMedium),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Maschio'),
                value: 'maschio',
                groupValue: _selectedSesso,
                onChanged: (value) => setState(() => _selectedSesso = value),
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Femmina'),
                value: 'femmina',
                groupValue: _selectedSesso,
                onChanged: (value) => setState(() => _selectedSesso = value),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Widget della selezione della taglia aggiornato
  Widget _buildTagliaRadio() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Taglia', style: Theme.of(context).textTheme.titleMedium),
        RadioListTile<String>(
          title: const Text('Piccola'),
          value: 'piccola',
          groupValue: _selectedTaglia,
          onChanged: (value) => setState(() => _selectedTaglia = value),
        ),
        RadioListTile<String>(
          title: const Text('Media'),
          value: 'media',
          groupValue: _selectedTaglia,
          onChanged: (value) => setState(() => _selectedTaglia = value),
        ),
        RadioListTile<String>(
          title: const Text('Grande'),
          value: 'grande',
          groupValue: _selectedTaglia,
          onChanged: (value) => setState(() => _selectedTaglia = value),
        ),
      ],
    );
  }
}