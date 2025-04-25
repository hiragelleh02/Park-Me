import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReservationService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> makeReservation(Map<String, dynamic> garage) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Not logged in");

    final reservation = {
      'place_id': garage['place_id'],
      'garage_name': garage['name'],
      'garage_address': garage['address'],
      'user_id': user.uid,
      'timestamp': Timestamp.now(),
    };

    await _db.collection('reservations').add(reservation);

    final garageRef = _db.collection('garages').doc(garage['place_id']);
    await garageRef.update({
      'available_spots': FieldValue.increment(-1),
    });
  }
}
