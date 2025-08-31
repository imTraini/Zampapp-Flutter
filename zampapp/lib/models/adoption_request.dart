import 'package:cloud_firestore/cloud_firestore.dart';

class AdoptionRequest {
  final String id;
  final String richiedenteId;
  final String canileId;
  final String dogId;
  final Timestamp dataRichiesta;
  final String status;
  final Timestamp? dataAggiornamentoStato;
  final String? richiedenteNome;
  final String? richiedenteCognome;
  final String? richiedenteEmail;
  final String? richiedenteTelefono;
  final String? richiedenteVia;
  final String? richiedenteCitta;
  final String? richiedenteProvincia;

  AdoptionRequest({
    required this.id,
    required this.richiedenteId,
    required this.canileId,
    required this.dogId,
    required this.dataRichiesta,
    required this.status,
    this.dataAggiornamentoStato,
    this.richiedenteNome,
    this.richiedenteCognome,
    this.richiedenteEmail,
    this.richiedenteTelefono,
    this.richiedenteVia,
    this.richiedenteCitta,
    this.richiedenteProvincia,
  });

  factory AdoptionRequest.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AdoptionRequest(
      id: doc.id,
      richiedenteId: data['richiedenteId'] ?? '',
      canileId: data['canileId'] ?? '',
      dogId: data['dogId'] ?? data['caneId'] ?? '',
      dataRichiesta: data['dataRichiesta'] ?? Timestamp.now(),
      status: data['status'] ?? 'In elaborazione',
      dataAggiornamentoStato: data['dataAggiornamentoStato'],
      richiedenteNome: data['richiedenteNome'],
      richiedenteCognome: data['richiedenteCognome'],
      richiedenteEmail: data['richiedenteEmail'],
      richiedenteTelefono: data['richiedenteTelefono'],
      richiedenteVia: data['richiedenteVia'],
      richiedenteCitta: data['richiedenteCitta'],
      richiedenteProvincia: data['richiedenteProvincia'],
    );
  }
}