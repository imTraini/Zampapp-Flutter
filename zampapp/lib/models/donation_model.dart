import 'package:cloud_firestore/cloud_firestore.dart';

class Donation {
  final String id;
  final String donatoreId;
  final String donatoreNome;
  final String riceventeId;
  final String riceventeNome;
  final int importo;
  final Timestamp dataDonazione;

  Donation({
    required this.id,
    required this.donatoreId,
    required this.donatoreNome,
    required this.riceventeId,
    required this.riceventeNome,
    required this.importo,
    required this.dataDonazione,
  });

  factory Donation.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Donation(
      id: doc.id,
      donatoreId: data['donatoreId'] ?? '',
      donatoreNome: data['donatoreNome'] ?? 'Anonimo',
      riceventeId: data['riceventeId'] ?? '',
      riceventeNome: data['riceventeNome'] ?? '',
      importo: data['importo'] ?? 0,
      dataDonazione: data['dataDonazione'] ?? Timestamp.now(),
    );
  }
}