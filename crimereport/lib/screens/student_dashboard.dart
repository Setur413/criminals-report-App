import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'navigation.dart';
import 'qr_scanning.dart'; // Import your profile screen file

class UserDashboard extends StatefulWidget {
  final Map<String, dynamic> userData;

  const UserDashboard({super.key, required this.userData});

  @override
  _UserDashboardState createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  int _currentIndex = 0;
  late final SupabaseClient _supabase;
  List<Map<String, dynamic>> _reports = [];
  Map<String, dynamic> _reportStats = {};
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _supabase = Supabase.instance.client;
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      // Fetch recent reports
      final reportsResponse = await _supabase
          .from('crime_reports')
          .select()
          .eq('user_id', _supabase.auth.currentUser!.id)
          .order('created_at', ascending: false)
          .limit(5);

      // Fetch report statistics
      final statsResponse = await _supabase
          .rpc('get_user_report_stats', params: {
            'user_id': _supabase.auth.currentUser!.id
          });

      setState(() {
        _reports = List<Map<String, dynamic>>.from(reportsResponse);
        _reportStats = statsResponse as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading dashboard: ${e.toString()}')),
      );
    }
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  List<Map<String, dynamic>> get _filteredReports {
    if (_searchQuery.isEmpty) return _reports;
    return _reports.where((report) {
      return report['description'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
             report['crime_type'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 30, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportActivityItem(Map<String, dynamic> report) {
    final date = DateTime.parse(report['created_at']);
    final formattedDate = '${date.day}/${date.month}/${date.year}';
    final formattedTime = '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    
    return ListTile(
      leading: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(formattedTime, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(formattedDate, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
      title: Text(report['crime_type'] ?? 'Unknown crime type'),
      subtitle: Text(
        report['description']?.length > 50 
          ? '${report['description'].substring(0, 50)}...' 
          : report['description'] ?? '',
      ),
      trailing: Chip(
        label: Text(
          report['status'] ?? 'pending',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: _getStatusColor(report['status']),
      ),
      onTap: () {
        // Navigate to report details
      },
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'under investigation': return Colors.blue;
      case 'resolved': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Crime Report Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.account_circle, size: 30),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StudentProfileScreen(
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search reports...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                  const SizedBox(height: 20),
                  
                  // Statistics Section
                  const Text(
                    "Your Report Statistics",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    children: [
                      _buildStatCard(
                        'Total Reports',
                        _reportStats['total_reports']?.toString() ?? '0',
                        Icons.assignment,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        'Pending',
                        _reportStats['pending']?.toString() ?? '0',
                        Icons.access_time,
                        Colors.orange,
                      ),
                      _buildStatCard(
                        'Investigating',
                        _reportStats['investigating']?.toString() ?? '0',
                        Icons.search,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        'Resolved',
                        _reportStats['resolved']?.toString() ?? '0',
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Recent Reports Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Recent Reports",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          // Navigate to all reports screen
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: _filteredReports.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text("No reports found"),
                          )
                        : Column(
                            children: _filteredReports
                                .map((report) => _buildReportActivityItem(report))
                                .toList(),
                          ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}