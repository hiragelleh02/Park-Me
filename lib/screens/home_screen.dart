// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'parking_screen.dart';
import 'manage_reservations_screen.dart';
import 'profile_screen.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  final AuthService _authService = AuthService();

  void logout(BuildContext context) async {
    await _authService.logout();
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Smart Parking"), actions: [
        IconButton(icon: Icon(Icons.logout), onPressed: () => logout(context)),
      ]),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: Text("Find Parking"),
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => ParkingScreen()));
              },
            ),
            ElevatedButton(
              child: Text("Manage Reservations"),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ManageReservationsScreen()));
              },
            ),
            ElevatedButton(
              child: Text("Profile"),
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => ProfileScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }
}
