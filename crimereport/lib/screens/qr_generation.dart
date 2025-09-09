import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'bottom.dart';

class LecturerProfileScreen extends StatefulWidget {
  const LecturerProfileScreen({super.key});

  @override
  State<LecturerProfileScreen> createState() => _LecturerProfileScreenState();
}

class _LecturerProfileScreenState extends State<LecturerProfileScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  Map<String, dynamic>? _lecturerData;
  bool _isLoading = true;
  int _currentIndex = 3; // Assuming profile is the 4th tab (0-indexed)

  @override
  void initState() {
    super.initState();
    _fetchLecturerData();
  }

  Future<void> _fetchLecturerData() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('No user logged in');
      }

      final response = await _supabase
          .from('lecturers')
          .select('*')
          .eq('user_id', userId)
          .single();

      setState(() {
        _lecturerData = response;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching lecturer data: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load profile data')),
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

  void _openTermsAndConditions() {
    // TODO: Implement proper terms and conditions screen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms and Conditions'),
        content: const SingleChildScrollView(
          child: Text(
            'Here would be your app terms and conditions...',
            style: TextStyle(fontSize: 16),
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
        title: const Text("Lecturer Profile", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchLecturerData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircleAvatar(
                          radius: 40,
                          backgroundImage: AssetImage("assets/profile_placeholder.png"),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _lecturerData?['full_name'] ?? 'No name',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _lecturerData?['email'] ?? 'No email',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildProfileOption(
                  Icons.person,
                  "Full Name",
                  _lecturerData?['full_name'] ?? 'Not available',
                ),
                _buildProfileOption(
                  Icons.email,
                  "Email",
                  _lecturerData?['email'] ?? 'Not available',
                ),
                _buildProfileOption(
                  Icons.badge,
                  "Staff ID",
                  _lecturerData?['staff_id'] ?? 'Not available',
                ),
                _buildProfileOption(
                  Icons.description,
                  "Terms and Conditions",
                  "",
                  onTap: _openTermsAndConditions,
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
          setState(() {
            _currentIndex = index;
          });
          // Add navigation logic here if needed
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 2,
        child: ListTile(
          leading: Icon(icon, color: isDestructive ? Colors.red : Colors.red[700]),
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