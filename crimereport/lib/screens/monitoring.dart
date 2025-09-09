import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'bottom.dart';

class ReportTrackingScreen extends StatefulWidget {
  const ReportTrackingScreen({super.key});

  @override
  _ReportTrackingScreenState createState() => _ReportTrackingScreenState();
}

class _ReportTrackingScreenState extends State<ReportTrackingScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _reports = [];
  String _searchQuery = '';
  String _selectedFilter = 'All';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    setState(() {
      _isLoading = true;
    });

    final response = await supabase
        .from('crime_reports')
        .select('id, crime_type, description, status, created_at')
        .order('created_at', ascending: false);

    setState(() {
      _reports = response.map((r) => {
        'id': r['id'],
        'reportNumber': r['id'].toString().substring(0, 8),
        'category': r['crime_type'],
        'description': r['description'],
        'status': r['status'],
        'date': r['created_at'],
      }).toList();
      _isLoading = false;
    });
  }

  Future<void> _updateReportStatus(String fullId, String newStatus) async {
    // Validate the status before updating
    if (!['pending', 'reviewed', 'resolved', 'rejected'].contains(newStatus.toLowerCase())) {
      print("Invalid status: $newStatus");
      return;
    }

    final response = await supabase
        .from('crime_reports')
        .update({'status': newStatus.toLowerCase()})
        .eq('id', fullId);

    if (response.error == null) {
      _fetchReports();
    } else {
      print("Error updating report: ${response.error!.message}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredReports = _reports.where((report) {
      final matchesSearch = report['reportNumber'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          report['category'].toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFilter = _selectedFilter == 'All' || report['status'].toLowerCase() == _selectedFilter.toLowerCase();
      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Report Tracking", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  SearchBar(
                    hintText: 'Search reports...',
                    onChanged: (value) => setState(() => _searchQuery = value),
                    padding: const WidgetStatePropertyAll<EdgeInsets>(
                      EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_selectedFilter != 'All')
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Chip(
                        label: Text(_selectedFilter),
                        onDeleted: () => setState(() => _selectedFilter = 'All'),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: filteredReports.isEmpty
                        ? const Center(child: Text('No reports found', style: TextStyle(fontSize: 16)))
                        : ListView.separated(
                            itemCount: filteredReports.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final report = filteredReports[index];
                              return _buildReportCard(report);
                            },
                          ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 2,
        onTap: (index) {
          // Handle navigation
        },
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final statusColor = _getStatusColor(report['status']);
    final statusText = report['status'][0].toUpperCase() + report['status'].substring(1);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showStatusDialog(report['id'], report['status']),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Report #${report['reportNumber']}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(report['category'], style: const TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 8),
              Text(
                report['description'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    report['date'].toString().split('T')[0],
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    color: Colors.blue,
                    onPressed: () => _showStatusDialog(report['id'], report['status']),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.grey;
      case 'reviewed':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  void _showStatusDialog(String fullId, String currentStatus) {
    String selectedStatus = currentStatus.toLowerCase();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Update Report Status"),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: ['pending', 'reviewed', 'resolved', 'rejected']
                    .map((status) => RadioListTile<String>(
                          title: Text(status[0].toUpperCase() + status.substring(1)),
                          value: status,
                          groupValue: selectedStatus,
                          onChanged: (value) {
                            setState(() => selectedStatus = value!);
                          },
                        ))
                    .toList(),
              );
            },
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _updateReportStatus(fullId, selectedStatus);
              },
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Filter Reports"),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['All', 'pending', 'reviewed', 'resolved', 'rejected']
                .map((status) => RadioListTile<String>(
                      title: Text(status == 'All' ? 'All' : status[0].toUpperCase() + status.substring(1)),
                      value: status,
                      groupValue: _selectedFilter.toLowerCase(),
                      onChanged: (value) {
                        setState(() => _selectedFilter = value!);
                        Navigator.pop(context);
                      },
                    ))
                .toList(),
          ),
        );
      },
    );
  }
}