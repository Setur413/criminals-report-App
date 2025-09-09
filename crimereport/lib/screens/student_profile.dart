import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'navigation.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  _StudentProfileScreenState createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();
  File? _profileImage;
  Map<String, dynamic>? _studentData;
  bool _isLoading = true;
  int _currentIndex = 3;

  @override
  void initState() {
    super.initState();
    _fetchStudentData();
  }

  Future<void> _fetchStudentData() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('No user logged in');
      }

      final response = await _supabase
          .from('students')
          .select('*')
          .eq('id', userId)
          .single();

      setState(() {
        _studentData = response;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching student data: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load profile data')),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() => _profileImage = File(pickedFile.path));
        
        // Upload to Supabase Storage (optional)
        // final fileBytes = await pickedFile.readAsBytes();
        // final fileExt = pickedFile.path.split('.').last;
        // final fileName = '${_supabase.auth.currentUser!.id}.$fileExt';
        // await _supabase.storage
        //   .from('profile_pictures')
        //   .uploadBinary(fileName, fileBytes);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile image updated")),
        );
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update profile image")),
      );
    }
  }

  Future<void> _logout() async {
    try {
      setState(() => _isLoading = true);
      await _supabase.auth.signOut();
      Navigator.pushNamedAndRemoveUntil(context, '/role', (route) => false);
    } catch (e) {
      print('Error during logout: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to logout')),
      );
    }
  }

  Future<void> _deleteAccount() async {
    try {
      setState(() => _isLoading = true);
      final userId = _supabase.auth.currentUser!.id;
      
      // Delete from students table first
      await _supabase.from('students').delete().eq('id', userId);
      
      // Then delete auth user
      await _supabase.auth.admin.deleteUser(userId);
      
      Navigator.pushNamedAndRemoveUntil(context, '/role', (route) => false);
    } catch (e) {
      print('Error deleting account: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete account')),
      );
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Account Deletion"),
        content: const Text(
            "Are you sure you want to delete your account? All your data will be permanently removed."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount();
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showTermsAndConditions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms and Conditions'),
        content: SingleChildScrollView(
          child: Text(
            'Here are the terms and conditions for using our crime reporting app...\n\n'
            '1. You agree to report only factual information\n'
            '2. False reports may lead to account suspension\n'
            '3. Your data will be handled according to our privacy policy',
            style: const TextStyle(fontSize: 16),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text("Student Profile", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchStudentData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 200,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(50),
                          bottomRight: Radius.circular(50),
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        const SizedBox(height: 30),
                        GestureDetector(
                          onTap: _pickImage,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            backgroundImage: _profileImage != null
                                ? FileImage(_profileImage!)
                                : const AssetImage("assets/profile_placeholder.png") as ImageProvider,
                            child: Align(
                              alignment: Alignment.bottomRight,
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.red,
                                child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _studentData?['full_name'] ?? 'Student',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _studentData?['email'] ?? _supabase.auth.currentUser?.email ?? 'No email',
                          style: const TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildProfileOption(
                  Icons.person,
                  "Full Name",
                  _studentData?['full_name'] ?? 'Not available',
                ),
                _buildProfileOption(
                  Icons.email,
                  "Email",
                  _studentData?['email'] ?? _supabase.auth.currentUser?.email ?? 'Not available',
                ),
                _buildProfileOption(
                  Icons.badge,
                  "Registration Number",
                  _studentData?['registration_number'] ?? 'Not available',
                ),
                _buildProfileOption(
                  Icons.description,
                  "Terms and Conditions",
                  "",
                  onTap: _showTermsAndConditions,
                ),
                _buildProfileOption(
                  Icons.delete,
                  "Delete Account",
                  "",
                  onTap: _showDeleteConfirmation,
                  isDestructive: true,
                ),
                _buildProfileOption(
                  Icons.logout,
                  "Log Out",
                  "",
                  onTap: _logout,
                  isDestructive: true,
                ),
              ],
            ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }

  Widget _buildProfileOption(
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 2,
        child: ListTile(
          leading: Icon(
            icon,
            color: isDestructive ? Colors.red : Colors.red[700],
          ),
          title: Text(
            title,
            style: TextStyle(
              color: isDestructive ? Colors.red : Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: subtitle.isNotEmpty
              ? Text(
                  subtitle,
                  style: TextStyle(
                    color: isDestructive ? Colors.red : Colors.grey[700],
                  ),
                )
              : null,
          trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
          onTap: onTap,
        ),
      ),
    );
  }
}