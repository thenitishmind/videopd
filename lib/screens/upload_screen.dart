import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../services/s3_service.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final TextEditingController _loanNumberController = TextEditingController();
  final S3Service _s3Service = S3Service();
  final List<UploadItem> _uploadQueue = [];
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _loanNumberController,
              decoration: const InputDecoration(
                labelText: 'Loan Number',
                hintText: 'Enter loan number',
                prefixIcon: Icon(Icons.numbers),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 24),
            const Text(
              'Select Files to Upload:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Photos'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickVideos,
                    icon: const Icon(Icons.videocam),
                    label: const Text('Videos'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickMultipleFiles,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Files'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Upload Queue (${_uploadQueue.length})',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (_uploadQueue.isNotEmpty)
                  TextButton(
                    onPressed: _clearQueue,
                    child: const Text('Clear All'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _uploadQueue.isEmpty
                  ? const Center(
                      child: Text(
                        'No files selected',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _uploadQueue.length,
                      itemBuilder: (context, index) {
                        return _buildUploadItem(_uploadQueue[index], index);
                      },
                    ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canUpload() ? _uploadFiles : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isUploading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Uploading...'),
                        ],
                      )
                    : const Text(
                        'Upload All Files',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadItem(UploadItem item, int index) {
    return Card(
      child: ListTile(
        leading: _getFileIcon(item.fileName),
        title: Text(item.fileName),
        subtitle: Text(_formatFileSize(item.file.lengthSync())),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editFileName(index),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _removeFromQueue(index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getFileIcon(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return const Icon(Icons.image, color: Colors.green);
      case 'mp4':
      case 'mov':
      case 'avi':
        return const Icon(Icons.video_file, color: Colors.red);
      case 'pdf':
        return const Icon(Icons.picture_as_pdf, color: Colors.red);
      default:
        return const Icon(Icons.description, color: Colors.blue);
    }
  }

  Future<void> _pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage();

      if (images.isNotEmpty) {
        for (final image in images) {
          _addToQueue(File(image.path), image.name);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Added ${images.length} image(s) to upload queue'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error picking images: $e');
      _showErrorSnackBar('Failed to pick images. Please try again.');
    }
  }

  Future<void> _pickVideos() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: true,
        allowCompression: false,
      );

      if (result != null && result.files.isNotEmpty) {
        for (final file in result.files) {
          if (file.path != null) {
            _addToQueue(File(file.path!), file.name);
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Added ${result.files.length} video(s) to upload queue'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error picking videos: $e');
      _showErrorSnackBar('Failed to pick videos. Please try again.');
    }
  }

  Future<void> _pickCamera() async {
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final XFile? photo = await picker.pickImage(source: ImageSource.camera);
                  if (photo != null) {
                    _addToQueue(File(photo.path), photo.name);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Photo added to upload queue'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  print('Error taking photo: $e');
                  _showErrorSnackBar('Failed to take photo. Please check camera permissions.');
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Record Video'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final XFile? video = await picker.pickVideo(source: ImageSource.camera);
                  if (video != null) {
                    _addToQueue(File(video.path), video.name);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Video added to upload queue'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  print('Error recording video: $e');
                  _showErrorSnackBar('Failed to record video. Please check camera permissions.');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickMultipleFiles() async {
    // Use FilePicker directly without permission request for file picking
    // Modern file pickers handle permissions internally
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any, // Allow all file types
        allowMultiple: true,
        allowCompression: false,
      );

      if (result != null && result.files.isNotEmpty) {
        for (final file in result.files) {
          if (file.path != null) {
            _addToQueue(File(file.path!), file.name);
          }
        }

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Added ${result.files.length} file(s) to upload queue'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error picking files: $e');
      _showErrorSnackBar('Failed to pick files. Please try again.');
    }
  }



  void _addToQueue(File file, String fileName) {
    setState(() {
      _uploadQueue.add(UploadItem(file: file, fileName: fileName));
    });
  }

  void _removeFromQueue(int index) {
    setState(() {
      _uploadQueue.removeAt(index);
    });
  }

  void _clearQueue() {
    setState(() {
      _uploadQueue.clear();
    });
  }

  Future<void> _editFileName(int index) async {
    final TextEditingController controller = TextEditingController(
      text: _uploadQueue[index].fileName,
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit File Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'File Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _uploadQueue[index].fileName = result;
      });
    }
  }

  bool _canUpload() {
    return _loanNumberController.text.isNotEmpty &&
           _uploadQueue.isNotEmpty &&
           !_isUploading;
  }

  Future<void> _uploadFiles() async {
    if (!_canUpload()) return;

    setState(() {
      _isUploading = true;
    });

    int successCount = 0;
    int failCount = 0;
    String lastError = '';

    for (final item in _uploadQueue) {
      try {
        print('🚀 Uploading: ${item.fileName} for loan: ${_loanNumberController.text}');
        final success = await _s3Service.uploadFile(
          loanNumber: _loanNumberController.text,
          file: item.file,
          fileName: item.fileName,
        );

        if (success) {
          successCount++;
          print('✅ Successfully uploaded: ${item.fileName}');
        } else {
          failCount++;
          lastError = 'Upload failed for ${item.fileName}';
          print('❌ Failed to upload: ${item.fileName}');
        }
      } catch (e) {
        failCount++;
        lastError = e.toString();
        print('❌ Error uploading ${item.fileName}: $e');
      }
    }

    setState(() {
      _isUploading = false;
    });

    _showUploadResults(successCount, failCount, lastError);

    if (successCount > 0) {
      setState(() {
        _uploadQueue.clear();
        _loanNumberController.clear();
      });
    }
  }

  void _showUploadResults(int successCount, int failCount, String lastError) {
    if (failCount == 0) {
      // Success case
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Successfully uploaded $successCount file(s)'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // Error case - show detailed error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Upload Results'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (successCount > 0)
                Text('✅ Successfully uploaded: $successCount file(s)'),
              if (failCount > 0)
                Text('❌ Failed to upload: $failCount file(s)'),
              const SizedBox(height: 8),
              if (lastError.isNotEmpty) ...[
                const Text('Error details:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    lastError,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
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

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  void dispose() {
    _loanNumberController.dispose();
    super.dispose();
  }
}

class UploadItem {
  final File file;
  String fileName;

  UploadItem({required this.file, required this.fileName});
}