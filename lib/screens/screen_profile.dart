import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ScreenProfile extends StatefulWidget {
  const ScreenProfile({super.key});

  @override
  State<ScreenProfile> createState() => _ScreenProfileState();
}

class _ScreenProfileState extends State<ScreenProfile> {
  final User? user = FirebaseAuth.instance.currentUser;

  void _showLogoutSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.logout, size: 50, color: Colors.red),
              SizedBox(height: 10),
              Text(
                "Are you sure you want to logout?",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Cancel", style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _logout,
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: Text("Logout",
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _logout() async {
    Navigator.pop(context); // Close bottom sheet
    await FirebaseAuth.instance.signOut();
    // Navigate to login screen or replace with your logic
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Profile",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          children: [
            // Profile Picture
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blueGrey,
              backgroundImage:
                  user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
              child: user?.photoURL == null
                  ? Icon(Icons.person, size: 50, color: Colors.white)
                  : null,
            ),
            SizedBox(height: 10),

            // User Name
            Text(
              user?.displayName ?? "User Name",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            // User Email
            Text(
              user?.email ?? "example@gmail.com",
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            SizedBox(height: 30),

            // Logout Button
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              trailing: Icon(Icons.arrow_forward_ios),
              title: Text("Logout",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
              onTap: _showLogoutSheet,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.grey),
              ),
              focusColor: Colors.grey,

            ),
          ],
        ),
      ),
    );
  }
}
