import 'package:cloud_firestore/cloud_firestore.dart';

class Dog {
  final String id;
  final String nome;
  final String razza;
  final Timestamp? dataNascita;
  final String descrizione;
  final String urlImmagine;
  final String sesso;
  final String taglia;
  final Timestamp? dataAggiunta;
  final String? proprietarioId;
  final String status;

  Dog({
    required this.id,
    required this.nome,
    required this.razza,
    this.dataNascita,
    required this.descrizione,
    required this.urlImmagine,
    required this.sesso,
    required this.taglia,
    this.dataAggiunta,
    this.proprietarioId,
    required this.status,
  });

  // Metodo per creare un oggetto Dog da un documento Firestore
  factory Dog.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Dog(
      id: doc.id,
      nome: data['nome'] ?? '',
      razza: data['razza'] ?? '',
      dataNascita: data['dataNascita'] as Timestamp?,
      descrizione: data['descrizione'] ?? '',
      urlImmagine: data['urlImmagine'] ?? '',
      sesso: data['sesso'] ?? '',
      taglia: data['taglia'] ?? '',
      dataAggiunta: data['dataAggiunta'] as Timestamp?,
      proprietarioId: data['proprietarioId'],
      status: data['status'] ?? 'di_proprieta',
    );
  }
}