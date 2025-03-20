import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edu_elite/screens/screen_login.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ScreenSignUp extends StatefulWidget {
  const ScreenSignUp({super.key});

  @override
  State<ScreenSignUp> createState() => _ScreenSignUpState();
}

class _ScreenSignUpState extends State<ScreenSignUp> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  Future<void> _signUp() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Passwords do not match!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'email': _emailController.text.trim(),
          'createdAt': Timestamp.now(),
        });

        await FirebaseFirestore.instance.collection('users').doc(user.uid)
            .collection('purchased_courses').doc('init').set({'init': true});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Sign-Up Successful!")),
        );

        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => ScreenLogin(),));
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Sign-Up Failed')),
      );
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Firestore Error: ${e.toString()}")),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.purpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 25, vertical: 40),
            child: Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Create Account",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    SizedBox(height: 10),

                    // First Name
                    _buildTextField(
                      controller: _firstNameController,
                      label: "First Name",
                      icon: Icons.person,
                    ),

                    // Last Name
                    _buildTextField(
                      controller: _lastNameController,
                      label: "Last Name",
                      icon: Icons.person_outline,
                    ),

                    // Email
                    _buildTextField(
                      controller: _emailController,
                      label: "Email",
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    // Password
                    _buildTextField(
                      controller: _passwordController,
                      label: "Password",
                      icon: Icons.lock,
                      obscureText: true,
                    ),

                    // Confirm Password
                    _buildTextField(
                      controller: _confirmPasswordController,
                      label: "Confirm Password",
                      icon: Icons.lock_outline,
                      obscureText: true,
                    ),

                    SizedBox(height: 20),

                    // Sign Up Button
                    _isLoading
                        ? CircularProgressIndicator()
                        : ElevatedButton(
                      onPressed: _signUp,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text("Sign Up", style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),

                    SizedBox(height: 15),

                    // Login Text Button
                    TextButton(
                      onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => ScreenLogin()),
                      ),
                      child: Text(
                        "Already have an account? Login",
                        style: TextStyle(fontSize: 16, color: Colors.blueAccent),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blueAccent),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}
