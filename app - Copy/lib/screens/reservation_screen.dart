// lib/screens/reservation_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReservationScreen extends StatefulWidget {
  final Map<String, dynamic> garageData;
  ReservationScreen({required this.garageData});

  @override
  _ReservationScreenState createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  bool isLoading = false;

  void makeReservation() async {
    final user = _auth.currentUser;
    if (user == null || _nameController.text.isEmpty) return;

    setState(() => isLoading = true);

    try {
      await _db.collection('reservations').add({
        'user_id': user.uid,
        'user_name': _nameController.text,
        'place_id': widget.garageData['place_id'],
        'garage_name': widget.garageData['name'],
        'garage_address': widget.garageData['address'],
        'timestamp': Timestamp.now(),
      });

      await _db
          .collection('garages')
          .doc(widget.garageData['place_id'])
          .update({'available_spots': FieldValue.increment(-1)});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Reservation complete! Proceed to payment.")),
      );
    } catch (e) {
      print("❌ Error reserving: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to reserve.")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController.text = _auth.currentUser?.displayName ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.garageData;

    return Scaffold(
      appBar: AppBar(title: Text("Reservation")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Garage: ${data['name']}",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text("Address: ${data['address']}"),
            Text("Rate: \$${data['hourly_rate']}/hr"),
            Text("Available Spots: ${data['available_spots']}"),
            SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: "Your Name"),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton(
                  onPressed: isLoading ? null : makeReservation,
                  child: isLoading
                      ? CircularProgressIndicator()
                      : Text("Proceed to Payment"),
                ),
                SizedBox(width: 16),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Back"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
