import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';
import 'dart:io';
import 'navigation.dart';

class CrimeReportScreen extends StatefulWidget {
  const CrimeReportScreen({super.key});

  @override
  _CrimeReportScreenState createState() => _CrimeReportScreenState();
}

class _CrimeReportScreenState extends State<CrimeReportScreen> {
  int _currentIndex = 1;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedCrimeType;
  TimeOfDay? _incidentTime;
  DateTime? _incidentDate;
  final List<File> _attachedMedia = [];
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  // Supabase client
  late final SupabaseClient _supabase;

  // Crime types for dropdown
  final List<String> _crimeTypes = [
    'Theft',
    'Vandalism',
    'Assault',
    'Burglary',
    'Fraud',
    'Cybercrime',
    'Harassment',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _supabase = Supabase.instance.client;
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to submit a report')),
        );
      });
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _attachedMedia.add(File(image.path));
      });
    }
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _attachedMedia.add(File(video.path));
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _incidentTime = picked;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _incidentDate = picked;
      });
    }
  }

  Future<List<String>> _uploadMediaFiles() async {
    List<String> mediaUrls = [];
    
    try {
      for (var mediaFile in _attachedMedia) {
        final fileExt = path.extension(mediaFile.path);
        final fileName = '${DateTime.now().millisecondsSinceEpoch}$fileExt';
        final mimeType = lookupMimeType(mediaFile.path);
        
        final fileBytes = await mediaFile.readAsBytes();
        
        await _supabase.storage
            .from('crime_reports_media')
            .uploadBinary(fileName, fileBytes, fileOptions: FileOptions(
              contentType: mimeType,
              upsert: false,
            ));
        
        final publicUrl = _supabase.storage
            .from('crime_reports_media')
            .getPublicUrl(fileName);
            
        mediaUrls.add(publicUrl);
      }
    } catch (e) {
      debugPrint('Error uploading media: $e');
      rethrow;
    }
    
    return mediaUrls;
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if user is authenticated
    if (_supabase.auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to submit a report')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      List<String> mediaUrls = [];
      if (_attachedMedia.isNotEmpty) {
        mediaUrls = await _uploadMediaFiles();
      }

      // Prepare incident datetime
      DateTime? incidentDateTime;
      if (_incidentDate != null) {
        incidentDateTime = DateTime(
          _incidentDate!.year,
          _incidentDate!.month,
          _incidentDate!.day,
          _incidentTime?.hour ?? 0,
          _incidentTime?.minute ?? 0,
        );
      }

      // Submit report data
       await _supabase.from('crime_reports').insert({
        'crime_type': _selectedCrimeType,
        'description': _descriptionController.text.trim(),
        'incident_datetime': incidentDateTime?.toIso8601String(),
        'media_urls': mediaUrls.isNotEmpty ? mediaUrls : null,
        'created_at': DateTime.now().toIso8601String(),
        'status': 'pending',
        'user_id': _supabase.auth.currentUser!.id,
      }).select();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted successfully!')),
      );

      // Reset form
      _formKey.currentState?.reset();
      setState(() {
        _selectedCrimeType = null;
        _incidentTime = null;
        _incidentDate = null;
        _attachedMedia.clear();
        _descriptionController.clear();
      });
    } catch (e) {
      debugPrint('Error submitting report: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit report: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Crime'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Important Notice'),
                  content: const Text(
                    'Not all crimes can be reported online. In certain circumstances '
                    'you should contact your local police jurisdiction directly. '
                    'See our list of emergency and non-emergency numbers.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'The crime you are reporting is:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCrimeType,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                  hintText: 'Select crime type...',
                ),
                items: _crimeTypes.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedCrimeType = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a crime type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Describe the crime in detail:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                  hintText: 'Type description here...',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please describe the incident';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'When did the crime happen?',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey[200],
                          hintText: 'Date of incident',
                        ),
                        child: Text(
                          _incidentDate != null
                              ? '${_incidentDate!.day}/${_incidentDate!.month}/${_incidentDate!.year}'
                              : 'Select date',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey[200],
                          hintText: 'Time of incident',
                        ),
                        child: Text(
                          _incidentTime != null
                              ? _incidentTime!.format(context)
                              : 'Select time',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Attach photos or videos (optional):',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo),
                    label: const Text('Add Photo'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _pickVideo,
                    icon: const Icon(Icons.videocam),
                    label: const Text('Add Video'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_attachedMedia.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _attachedMedia.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Stack(
                          children: [
                            _attachedMedia[index].path.endsWith('.mp4') ||
                                    _attachedMedia[index].path.endsWith('.mov')
                                ? const Icon(Icons.videocam, size: 80)
                                : Image.file(
                                    _attachedMedia[index],
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                onPressed: () {
                                  setState(() {
                                    _attachedMedia.removeAt(index);
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitReport,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('SUBMIT REPORT'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () {
                              _formKey.currentState?.reset();
                              setState(() {
                                _selectedCrimeType = null;
                                _incidentTime = null;
                                _incidentDate = null;
                                _attachedMedia.clear();
                              });
                            },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('CANCEL'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Note: False reporting is a crime. All reports are logged and may be investigated.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}