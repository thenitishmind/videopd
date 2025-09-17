import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

class AppIconGenerator extends StatefulWidget {
  @override
  _AppIconGeneratorState createState() => _AppIconGeneratorState();
}

class _AppIconGeneratorState extends State<AppIconGenerator> {
  final GlobalKey _globalKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Pd App Icon Generator'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RepaintBoundary(
              key: _globalKey,
              child: _buildIcon(1024),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: _generateIcon,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: Text('Generate PNG Icon'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.15),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2196F3),
            Color(0xFF1976D2),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Document icon in corner
          Positioned(
            top: size * 0.1,
            right: size * 0.1,
            child: Container(
              width: size * 0.12,
              height: size * 0.16,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(size * 0.012),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  SizedBox(height: size * 0.03),
                  ...List.generate(3, (index) => Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: size * 0.02,
                      vertical: size * 0.008,
                    ),
                    height: size * 0.004,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  )),
                ],
              ),
            ),
          ),
          
          // Main container
          Center(
            child: Container(
              width: size * 0.4,
              height: size * 0.4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(size * 0.06),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 3,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'BL',
                    style: TextStyle(
                      fontSize: size * 0.18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'DOCS',
                    style: TextStyle(
                      fontSize: size * 0.048,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.9),
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Decorative elements
          Positioned(
            top: size * 0.15,
            left: size * 0.15,
            child: Container(
              width: size * 0.08,
              height: size * 0.08,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: size * 0.12,
            right: size * 0.12,
            child: Container(
              width: size * 0.1,
              height: size * 0.1,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateIcon() async {
    try {
      RenderRepaintBoundary boundary = 
          _globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 1.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Get app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/app_icon.png');
      await file.writeAsBytes(pngBytes);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Icon saved to: ${file.path}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating icon: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

void main() {
  runApp(MaterialApp(
    home: AppIconGenerator(),
    title: 'Video Pd Icon Generator',
  ));
}