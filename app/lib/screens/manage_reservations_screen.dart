import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'extend_reservation_screen.dart';

class ManageReservationsScreen extends StatelessWidget {
  const ManageReservationsScreen({Key? key}) : super(key: key);

  Stream<QuerySnapshot> _getUserReservations() {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return FirebaseFirestore.instance
        .collection('reservations')
        .where('uid', isEqualTo: uid)
        .orderBy('startTime', descending: true)
        .snapshots();
  }

  Future<void> _cancelReservation(
      BuildContext context, DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final DateTime now = DateTime.now();
    final DateTime startTime = data['startTime'].toDate();
    final bool isLateCancel = startTime.difference(now).inMinutes < 60;
    final bool isAlreadyInactive = data['status'] != 'active';

    if (isAlreadyInactive) {
      _showPopup(context, "Reservation is already canceled.", isError: true);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => _confirmDialog(
        context,
        "Cancel Reservation",
        isLateCancel
            ? "Canceling now will incur a 20% cancellation fee.\n\nDo you want to continue?"
            : "Are you sure you want to cancel this reservation?",
        icon: Icons.warning_amber_rounded,
        iconColor: Colors.red,
      ),
    );

    if (confirm == true) {
      double cancellationFee = 0;
      if (isLateCancel) {
        cancellationFee = (data['amount'] ?? 0) * 0.2;
      }

      await doc.reference.update({
        'status': 'canceled',
        'cancellationFee': double.parse(cancellationFee.toStringAsFixed(2)),
        'canceledAt': Timestamp.now(),
      });

      _showPopup(context, "Reservation canceled successfully.", isError: false);
    }
  }

  Future<void> _deleteReservation(
      BuildContext context, DocumentSnapshot doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => _confirmDialog(
        context,
        "Delete Reservation",
        "Are you sure you want to delete this past reservation?",
        icon: Icons.delete_forever,
        iconColor: Colors.red,
      ),
    );

    if (confirm == true) {
      await doc.reference.delete();
      _showPopup(context, "Reservation deleted.", isError: false);
    }
  }

  AlertDialog _confirmDialog(BuildContext context, String title, String message,
      {required IconData icon, required Color iconColor}) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(icon, color: iconColor),
          SizedBox(width: 10),
          Text(title),
        ],
      ),
      content: Text(message, style: TextStyle(fontSize: 16)),
      actionsPadding: EdgeInsets.only(right: 16, bottom: 8),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text("No", style: TextStyle(color: Colors.grey[700])),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text("Yes", style: TextStyle(color: iconColor)),
        ),
      ],
    );
  }

  void _showPopup(BuildContext context, String message,
      {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.redAccent : Colors.green.shade600,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        duration: Duration(seconds: 4),
      ),
    );
  }

  String formatDuration(double duration) {
    int totalMinutes = (duration * 60).round();
    int hours = totalMinutes ~/ 60;
    int minutes = totalMinutes % 60;

    if (hours > 0 && minutes > 0) return "$hours hr ${minutes} min";
    if (hours > 0) return "$hours hr";
    return "$minutes min";
  }

  Widget _buildSection(
      String title, List<DocumentSnapshot> docs, BuildContext context) {
    if (docs.isEmpty) return SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        ...docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final start = (data['startTime'] as Timestamp).toDate();
          final end = data['endTime'] != null
              ? (data['endTime'] as Timestamp).toDate()
              : null;
          final duration = (data['duration'] ?? 0).toDouble();
          final amount = (data['amount'] ?? 0).toDouble();
          final status = data['status'] ?? 'active';

          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 3,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['garageName'] ?? 'Unknown Garage',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text("Start: ${DateFormat.yMMMd().add_jm().format(start)}"),
                  if (end != null)
                    Text("End: ${DateFormat.yMMMd().add_jm().format(end)}"),
                  Text("Duration: ${formatDuration(duration)}"),
                  Text("Amount: \$${amount.toStringAsFixed(2)}"),
                  Text(
                      "Status: ${status[0].toUpperCase()}${status.substring(1)}"),
                  if (data['lastExtensionAmount'] != null)
                    Text(
                        "Last Extension Paid: \$${(data['lastExtensionAmount'] ?? 0).toStringAsFixed(2)}"),
                  if (data['cancellationFee'] != null)
                    Text(
                        "Cancellation Fee: \$${(data['cancellationFee'] ?? 0).toStringAsFixed(2)}"),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (status == 'active') ...[
                        ElevatedButton.icon(
                          icon: Icon(Icons.access_time,
                              size: 18, color: Colors.white),
                          label: Text("Extend",
                              style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF3066BE),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ExtendReservationScreen(
                                    reservationDoc: doc),
                              ),
                            );
                          },
                        ),
                        SizedBox(width: 8),
                        OutlinedButton.icon(
                          icon: Icon(Icons.cancel, size: 18, color: Colors.red),
                          label: Text("Cancel",
                              style: TextStyle(color: Colors.red)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                          ),
                          onPressed: () => _cancelReservation(context, doc),
                        ),
                      ],
                      if (status != 'active')
                        OutlinedButton.icon(
                          icon: Icon(Icons.delete, size: 18, color: Colors.red),
                          label: Text("Delete",
                              style: TextStyle(color: Colors.red)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                          ),
                          onPressed: () => _deleteReservation(context, doc),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Reservations", style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF3066BE),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6190E8), Color(0xFFa7bfe8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: _getUserReservations(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            final now = DateTime.now();
            final List<DocumentSnapshot> active = [];
            final List<DocumentSnapshot> canceled = [];
            final List<DocumentSnapshot> past = [];

            for (var doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final status = data['status'] ?? 'active';
              final endTime = (data['endTime'] as Timestamp?)?.toDate();

              if (status == 'canceled') {
                canceled.add(doc);
              } else if (endTime != null && endTime.isBefore(now)) {
                final daysSinceEnd = now.difference(endTime).inDays;
                if (daysSinceEnd <= 30) {
                  past.add(doc);
                }
              } else {
                active.add(doc);
              }
            }

            return ListView(
              children: [
                _buildSection("Active Reservations", active, context),
                _buildSection("Canceled Reservations", canceled, context),
                _buildSection("Past Reservations", past, context),
              ],
            );
          },
        ),
      ),
    );
  }
}
