import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'faq_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  User? currentUser;
  int reservationCount = 0;
  double totalPaid = 0.0;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    _fetchUserStats();
  }

  void _fetchUserStats() async {
    if (currentUser != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('reservations')
          .where('uid', isEqualTo: currentUser!.uid)
          .get();

      double sum = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final amount = data['amount'];

        if (amount != null) {
          try {
            sum += (amount is int)
                ? amount.toDouble()
                : (amount as num).toDouble();
          } catch (e) {
            print("Could not parse amount for reservation: ${doc.id}");
          }
        }
      }

      setState(() {
        reservationCount = snapshot.docs.length;
        totalPaid = double.parse(sum.toStringAsFixed(2));
      });
    }
  }

  void _logout() async {
    await _authService.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        title: Row(
          children: [
            Icon(Icons.local_parking, color: Colors.blue, size: 28),
            SizedBox(width: 10),
            Text("Park Me",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Divider(),
            SizedBox(height: 8),
            Text("Version 1.0.0", style: TextStyle(fontSize: 16)),
            SizedBox(height: 12),
            Text(
              "Reserve parking with ease.\n\nFind nearby garages, reserve a spot, and pay securely using Stripe.",
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Color(0xFF3066BE),
              textStyle: TextStyle(fontWeight: FontWeight.bold),
            ),
            child: Text("Close"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = currentUser?.email ?? 'user@example.com';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF3066BE),
        title: Text("Profile", style: TextStyle(color: Colors.white)),
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // User Info
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.blue.shade100,
                        child: Icon(Icons.person, size: 32, color: Colors.blue),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Logged in as",
                                style: TextStyle(color: Colors.grey[600])),
                            SizedBox(height: 4),
                            Text(
                              userEmail,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // Stats
                Container(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.bookmark, color: Colors.blue),
                        title: Text("Total Reservations"),
                        trailing: Text(
                          reservationCount.toString(),
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                      Divider(height: 0),
                      ListTile(
                        leading: Icon(Icons.attach_money, color: Colors.blue),
                        title: Text("Total Paid"),
                        trailing: Text(
                          "\$${totalPaid.toStringAsFixed(2)}",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                // About & FAQs
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.info_outline, color: Colors.blue),
                        title: Text("About App"),
                        onTap: _showAboutDialog,
                      ),
                      Divider(height: 0),
                      ListTile(
                        leading:
                            Icon(Icons.question_answer, color: Colors.blue),
                        title: Text("FAQs"),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => FAQScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                Spacer(),

                // Logout
                Center(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.logout, color: Colors.white),
                    label: Text("Logout",
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    onPressed: _logout,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
