import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/file_item.dart';
import '../services/s3_service.dart';

class FileDisplayWidget extends StatelessWidget {
  final FileItem file;

  const FileDisplayWidget({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          ListTile(
            leading: _getFileIcon(),
            title: Text(
              file.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Loan: ${file.loanNumber}'),
                Text('Size: ${_formatFileSize(file.size)}'),
                Text('Date: ${_formatDate(file.uploadDate)}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility),
                  onPressed: () => _openFile(context),
                  tooltip: 'View',
                ),
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () => _downloadFile(context),
                  tooltip: 'Download',
                ),
              ],
            ),
          ),
          if (file.isImage) _buildImagePreview(),
          if (file.isVideo) _buildVideoPreview(),
        ],
      ),
    );
  }

  Widget _getFileIcon() {
    if (file.isImage) {
      return const Icon(Icons.image, color: Colors.green);
    } else if (file.isVideo) {
      return const Icon(Icons.video_file, color: Colors.red);
    } else if (file.isPdf) {
      return const Icon(Icons.picture_as_pdf, color: Colors.red);
    } else {
      return const Icon(Icons.description, color: Colors.blue);
    }
  }

  Widget _buildImagePreview() {
    return Container(
      height: 200,
      width: double.infinity,
      margin: const EdgeInsets.all(8.0),
      child: CachedNetworkImage(
        imageUrl: file.url,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(),
        ),
        errorWidget: (context, url, error) => const Icon(Icons.error),
      ),
    );
  }

  Widget _buildVideoPreview() {
    return Container(
      height: 200,
      width: double.infinity,
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: const Center(
        child: Icon(
          Icons.play_circle_outline,
          size: 64,
          color: Colors.grey,
        ),
      ),
    );
  }

  void _openFile(BuildContext context) {
    if (file.isImage) {
      _openImageViewer(context);
    } else if (file.isVideo) {
      _openVideoPlayer(context);
    } else if (file.isPdf) {
      _openPdfViewer(context);
    } else {
      _showUnsupportedDialog(context);
    }
  }

  void _openImageViewer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(file.name),
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          body: PhotoView(
            imageProvider: CachedNetworkImageProvider(file.url),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 3,
          ),
          backgroundColor: Colors.black,
        ),
      ),
    );
  }

  void _openVideoPlayer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(file: file),
      ),
    );
  }

  void _openPdfViewer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(file: file),
      ),
    );
  }

  void _showUnsupportedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsupported File Type'),
        content: Text('Cannot preview ${file.name}. File type not supported.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadFile(BuildContext context) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Downloading file...'),
            ],
          ),
        ),
      );

      // Get downloads directory
      final dir = await getExternalStorageDirectory();
      final downloadsPath = '${dir?.path}/Downloads';
      final downloadsDir = Directory(downloadsPath);

      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      final filePath = '$downloadsPath/${file.name}';

      // Download file with authentication headers
      final dio = Dio();
      await dio.download(
        file.url,
        filePath,
        options: Options(
          headers: {
            'User-Agent': 'VideoPd/1.0',
          },
        ),
      );

      Navigator.of(context).pop(); // Close loading dialog

      // Show success dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('✅ Download Complete'),
          content: Text('File saved to Downloads folder:\n${file.name}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog

      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('❌ Download Failed'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Failed to download ${file.name}'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  'Error: $e',
                  style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                ),
              ),
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

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final FileItem file;

  const VideoPlayerScreen({super.key, required this.file});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.file.url));
    _controller.initialize().then((_) {
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.file.name),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: _isInitialized
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _controller.value.isPlaying
                                ? _controller.pause()
                                : _controller.play();
                          });
                        },
                        icon: Icon(
                          _controller.value.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : const CircularProgressIndicator(),
      ),
      backgroundColor: Colors.black,
    );
  }
}

class PdfViewerScreen extends StatefulWidget {
  final FileItem file;

  const PdfViewerScreen({super.key, required this.file});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? localPath;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _downloadPdf();
  }

  Future<void> _downloadPdf() async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${widget.file.name}');

      final dio = Dio();
      await dio.download(widget.file.url, file.path);

      setState(() {
        localPath = file.path;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.file.name),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : localPath != null
              ? PDFView(
                  filePath: localPath!,
                  enableSwipe: true,
                  swipeHorizontal: false,
                  autoSpacing: false,
                  pageFling: false,
                )
              : const Center(
                  child: Text('Error loading PDF'),
                ),
    );
  }
}