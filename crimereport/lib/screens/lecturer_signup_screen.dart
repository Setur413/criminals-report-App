import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crimereport/screens/lecturer_login_screen.dart';

class LecturerSignUpScreen extends StatefulWidget {
  const LecturerSignUpScreen({super.key});

  @override
  _LecturerSignUpScreenState createState() => _LecturerSignUpScreenState();
}

class _LecturerSignUpScreenState extends State<LecturerSignUpScreen> {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController staffIdController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  late final SupabaseClient _supabase;

  @override
  void initState() {
    super.initState();
    _supabase = Supabase.instance.client;
  }

  Future<void> _signUpLecturer() async {
    if (fullNameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        staffIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Sign up the user with Supabase Auth
      final authResponse = await _supabase.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (authResponse.user == null) {
        throw Exception('User registration failed');
      }

      // 2. Insert lecturer data into the lecturers table
      await _supabase.from('lecturers').insert({
        'user_id': authResponse.user!.id,
        'full_name': fullNameController.text.trim(),
        'email': emailController.text.trim(),
        'staff_id': staffIdController.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
      });

      // 3. Show success message and navigate to login
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sign-up successful! You can now log in.")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LecturerLoginScreen()),
      );
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Auth Error: ${e.message}")),
      );
    } on PostgrestException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Database Error: ${e.message}")),
      );
      // Attempt to delete the user if profile creation failed
      if (_supabase.auth.currentUser != null) {
        await _supabase.auth.admin.deleteUser(_supabase.auth.currentUser!.id);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error during sign-up: ${e.toString()}")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sign Up"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Create an Account",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            const Text("Enter your details to continue"),
            const SizedBox(height: 15),
            TextField(
              controller: fullNameController,
              decoration: const InputDecoration(
                labelText: "Full Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Email Address",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                labelText: "Password",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: staffIdController,
              decoration: const InputDecoration(
                labelText: "Staff ID",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _signUpLecturer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade200,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text(
                        "Sign Up as Admin",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
            const SizedBox(height: 15),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LecturerLoginScreen()),
                  );
                },
                child: const Text("Already have an account? Log In"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}