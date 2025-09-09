import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'navigation.dart'; // Your bottom navigation

class ReportTracking extends StatefulWidget {
  const ReportTracking({super.key});

  @override
  _ReportTrackingState createState() => _ReportTrackingState();
}

class _ReportTrackingState extends State<ReportTracking> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = true;
  int _currentIndex = 2;

  @override
  void initState() {
    super.initState();
    _fetchUserReports();
  }

  Future<void> _fetchUserReports() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      print("User not logged in.");
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      print("Fetching reports for user ID: ${user.id}");

      final response = await _supabase
          .from('crime_reports')
          .select('*')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      setState(() {
        _reports = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching reports: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'reviewed':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Tracking'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reports.isEmpty
              ? const Center(child: Text('No reports found.'))
              : RefreshIndicator(
                  onRefresh: _fetchUserReports,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _reports.length,
                    itemBuilder: (context, index) {
                      final report = _reports[index];
                      final status = report['status'] ?? 'pending';
                      final title = report['crime_type'] ?? 'Unknown Crime';
                      final subtitle = report['description'] ?? 'No Description';
                      final createdAt = report['created_at'] != null
                          ? DateFormat('MMM d, y • h:mm a').format(DateTime.parse(report['created_at']))
                          : 'Unknown Date';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(status).withOpacity(0.1),
                                      border: Border.all(color: _getStatusColor(status)),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: _getStatusColor(status),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                subtitle,
                                style: TextStyle(color: Colors.grey[600]),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text("Reported on $createdAt", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}
