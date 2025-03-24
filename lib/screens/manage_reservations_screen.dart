// lib/screens/manage_reservations_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManageReservationsScreen extends StatefulWidget {
  @override
  _ManageReservationsScreenState createState() =>
      _ManageReservationsScreenState();
}

class _ManageReservationsScreenState extends State<ManageReservationsScreen> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getUserReservationsStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }
    return _db
        .collection('reservations')
        .where('user_id', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> cancelReservation(String placeId, String reservationId) async {
    try {
      await _db.collection('reservations').doc(reservationId).delete();
      await _db.collection('garages').doc(placeId).update({
        'available_spots': FieldValue.increment(1),
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Reservation cancelled.")));
    } catch (e) {
      print("Error cancelling reservation: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to cancel reservation.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("My Reservations")),
      body: StreamBuilder<QuerySnapshot>(
        stream: getUserReservationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No reservations found."));
          } else {
            final reservations = snapshot.data!.docs;
            return ListView.builder(
              itemCount: reservations.length,
              itemBuilder: (context, index) {
                final doc = reservations[index];
                final res = doc.data() as Map<String, dynamic>;
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(res['garage_name'] ?? 'Unnamed Garage'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Address: ${res['garage_address'] ?? 'N/A'}"),
                        Text("Reserved by: ${res['user_name'] ?? 'Unknown'}"),
                        Text(
                            "Date: ${res['timestamp']?.toDate().toString().split('.')[0] ?? 'N/A'}"),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.cancel, color: Colors.red),
                      onPressed: () =>
                          cancelReservation(res['place_id'], doc.id),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
