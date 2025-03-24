import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  final AuthService _authService = AuthService();

  void logout(BuildContext context) async {
    await _authService.logout();
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Profile")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("User Profile"),
            SizedBox(height: 20),
            ElevatedButton(
                onPressed: () => logout(context), child: Text("Logout")),
          ],
        ),
      ),
    );
  }
}
