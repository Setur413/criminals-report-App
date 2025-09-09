import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'bottom.dart';
import 'package:video_player/video_player.dart';

class AdminReportManagementScreen extends StatefulWidget {
  const AdminReportManagementScreen({super.key});

  @override
  _AdminReportManagementScreenState createState() =>
      _AdminReportManagementScreenState();
}

class _AdminReportManagementScreenState
    extends State<AdminReportManagementScreen> {
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
    setState(() => _isLoading = true);

    final response = await supabase
        .from('crime_reports')
        .select('id, crime_type, description, status, created_at, media_url')
        .order('created_at', ascending: false);

    setState(() {
      _reports = response.map((r) {
        return {
          'reportNumber': r['id'].toString(),
          'category': r['crime_type'],
          'description': r['description'],
          'status': r['status'],
          'date': r['created_at'],
          'mediaUrl': r['media_urls'],
        };
      }).toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredReports = _reports.where((report) {
      final matchesSearch = report['reportNumber']
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          report['category']
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
      final matchesFilter =
          _selectedFilter == 'All' || report['status'] == _selectedFilter;
      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Report Management"),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by keyword or report number...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: filteredReports.length,
                    itemBuilder: (context, index) {
                      final report = filteredReports[index];
                      return _buildReportCard(report);
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 1,
        onTap: (index) {
          // Navigation logic
        },
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardRow(Icons.calendar_today, 'Date',
                report['date'].toString().split('T')[0]),
            const SizedBox(height: 8),
            _buildCardRow(Icons.report, 'Report #', report['reportNumber']),
            const SizedBox(height: 8),
            _buildCardRow(Icons.category, 'Category', report['category']),
            const SizedBox(height: 8),
            _buildCardRow(Icons.description, 'Description', report['description']),
            const SizedBox(height: 12),
            if (report['mediaUrl'] != null && report['mediaUrl'].toString().isNotEmpty)
              _buildMediaPreview(report['mediaUrl']),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(report['status']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    report['status'],
                    style: TextStyle(
                      color: _getStatusColor(report['status']),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCardRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.black87),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMediaPreview(String url) {
    final isVideo = url.endsWith('.mp4') || url.contains('video');

    if (isVideo) {
      return _VideoPlayerPreview(videoUrl: url);
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            url,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const Text('Failed to load media'),
          ),
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Under Review':
        return Colors.orange;
      case 'Investigating':
        return Colors.blue;
      case 'Resolved':
        return Colors.green;
      case 'Pending':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Filter Reports"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['All', 'Under Review', 'Investigating', 'Resolved']
                .map((status) => RadioListTile(
                      title: Text(status),
                      value: status,
                      groupValue: _selectedFilter,
                      onChanged: (value) {
                        setState(() {
                          _selectedFilter = value.toString();
                        });
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

class _VideoPlayerPreview extends StatefulWidget {
  final String videoUrl;

  const _VideoPlayerPreview({required this.videoUrl});

  @override
  State<_VideoPlayerPreview> createState() => _VideoPlayerPreviewState();
}

class _VideoPlayerPreviewState extends State<_VideoPlayerPreview> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            VideoPlayer(_controller),
            VideoProgressIndicator(_controller, allowScrubbing: true),
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: Icon(
                  _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _controller.value.isPlaying
                        ? _controller.pause()
                        : _controller.play();
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
