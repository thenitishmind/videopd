import 'dart:async';
import 'package:flutter/material.dart';
import '../models/file_item.dart';
import '../services/s3_service.dart';
import '../widgets/file_display_widget.dart';

class ViewScreen extends StatefulWidget {
  const ViewScreen({super.key});

  @override
  State<ViewScreen> createState() => _ViewScreenState();
}

class _ViewScreenState extends State<ViewScreen> {
  final TextEditingController _searchController = TextEditingController();
  final S3Service _s3Service = S3Service();
  List<FileItem> _allFiles = [];
  List<FileItem> _filteredFiles = [];
  bool _isLoading = false;
  String _selectedFilter = 'All';
  Timer? _refreshTimer;

  final List<String> _filterOptions = ['All', 'Images', 'Videos', 'Documents'];

  @override
  void initState() {
    super.initState();
    _loadAllFiles();
    // Set up a timer for real-time updates
    _setupRealTimeUpdates();
  }

  void _setupRealTimeUpdates() {
    // Refresh data every 30 seconds for real-time updates
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadAllFiles();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _loadAllFiles() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('🚀 Loading all files from S3 bucket: ${S3Service().toString()}');
      final files = await _s3Service.getAllFiles();

      if (!mounted) return;

      setState(() {
        _allFiles = files;
        _filteredFiles = files;
        _isLoading = false;
      });
      print('✅ Successfully loaded ${files.length} files');

      if (mounted) {
        if (files.isEmpty) {
          _showInfoSnackBar('📭 No files found in the S3 bucket. Upload some files to see them here.');
        } else {
          _showInfoSnackBar('📁 Loaded ${files.length} documents from S3 bucket');
        }
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
      print('❌ Error loading files: $e');

      if (!mounted) return;

      // Enhanced error handling for APK environment
      String errorMessage = 'Error loading files: ';
      if (e.toString().contains('AWS SECRET KEY NOT CONFIGURED')) {
        errorMessage = 'AWS credentials not configured properly. Please check your .env file.';
      } else if (e.toString().contains('Access Denied') || e.toString().contains('403')) {
        errorMessage = 'Access denied to S3 bucket. Please check your AWS permissions.';
      } else if (e.toString().contains('NoSuchBucket') || e.toString().contains('404')) {
        errorMessage = 'S3 bucket not found. Please verify the bucket name and region.';
      } else if (e.toString().contains('timeout') || e.toString().contains('TimeoutException')) {
        errorMessage = 'Connection timeout. Please check your internet connection and try again.';
      } else if (e.toString().contains('SocketException') || e.toString().contains('NetworkError')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (e.toString().contains('InvalidAccessKeyId')) {
        errorMessage = 'Invalid AWS Access Key ID. Please check your AWS credentials.';
      } else {
        errorMessage += e.toString();
      }

      _showErrorSnackBar(errorMessage);

      // Show retry button
      _showRetryDialog();
    }
  }

  Future<void> _searchByLoanNumber(String loanNumber) async {
    if (loanNumber.isEmpty) {
      if (mounted) {
        setState(() {
          _filteredFiles = _allFiles;
        });
        _applyTypeFilter();
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final files = await _s3Service.getFilesByLoanNumber(loanNumber);
      if (mounted) {
        setState(() {
          _filteredFiles = files;
          _isLoading = false;
        });
        _applyTypeFilter();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Error searching files: $e');
      }
    }
  }

  void _applyTypeFilter() {
    List<FileItem> filtered = _searchController.text.isEmpty
        ? _allFiles
        : _filteredFiles;

    switch (_selectedFilter) {
      case 'Images':
        filtered = filtered.where((file) => file.isImage).toList();
        break;
      case 'Videos':
        filtered = filtered.where((file) => file.isVideo).toList();
        break;
      case 'Documents':
        filtered = filtered.where((file) => file.isDocument).toList();
        break;
      default:
        break;
    }

    if (mounted) {
      setState(() {
        _filteredFiles = filtered;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Documents'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadAllFiles,
            tooltip: 'Refresh data from S3',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey.shade50,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search by Loan Number',
                    hintText: 'Enter loan number to search',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _searchByLoanNumber('');
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.cloud_download),
                          onPressed: _loadAllFiles,
                          tooltip: 'Load all files from ops-loan-data',
                        ),
                      ],
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: _searchByLoanNumber,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Filter: '),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedFilter,
                        isExpanded: true,
                        items: _filterOptions.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedFilter = newValue!;
                          });
                          _applyTypeFilter();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        _searchByLoanNumber(_searchController.text);
                      },
                      child: const Text('Search'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Found ${_filteredFiles.length} file(s)',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadAllFiles,
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredFiles.isEmpty
                    ? const Center(
                        child: Text(
                          'No files found',
                          style: TextStyle(fontSize: 18),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredFiles.length,
                        itemBuilder: (context, index) {
                          return FileDisplayWidget(file: _filteredFiles[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showRetryDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Connection Error'),
          content: const Text('Failed to load documents from S3. Would you like to retry?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _loadAllFiles();
              },
              child: const Text('Retry'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }
}