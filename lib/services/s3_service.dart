import 'dart:io';
import 'dart:typed_data';
import 'package:aws_s3_api/s3-2006-03-01.dart';
import '../models/file_item.dart';
import '../utils/config.dart';
import 'database_service.dart';

class S3Service {
  late S3 _s3;
  final DatabaseService _databaseService = DatabaseService();
  static const int _maxRetries = 3;
  static const Duration _timeout = Duration(seconds: 30);

  S3Service() {
    _initializeS3();
  }

  void _initializeS3() {
    try {
      _s3 = S3(
        region: Config.awsRegion,
        credentials: AwsClientCredentials(
          accessKey: Config.awsAccessKeyId,
          secretKey: Config.awsSecretAccessKey,
        ),
      );
      print('S3 Service initialized for region: ${Config.awsRegion}');
    } catch (e) {
      print('Failed to initialize S3 service: $e');
      rethrow;
    }
  }

  /// Try to initialize S3 with a different region if the current one fails
  void _reinitializeS3WithRegion(String region) {
    try {
      _s3 = S3(
        region: region,
        credentials: AwsClientCredentials(
          accessKey: Config.awsAccessKeyId,
          secretKey: Config.awsSecretAccessKey,
        ),
      );
      print('S3 Service reinitialized for region: $region');
    } catch (e) {
      print('Failed to reinitialize S3 service for region $region: $e');
      rethrow;
    }
  }

  /// Validates S3 configuration before making API calls
  bool _validateS3Config() {
    if (Config.s3BucketName.isEmpty ||
        Config.s3BucketName == 'your-bucket-name' ||
        Config.s3BucketName.contains('your-bucket')) {
      throw '📝 S3 BUCKET NOT CONFIGURED!\n\nPlease update the .env file with your actual S3 bucket name:\nS3_BUCKET_NAME=your-actual-bucket-name';
    }
    if (Config.awsAccessKeyId.isEmpty ||
        Config.awsAccessKeyId == 'your-access-key-id' ||
        Config.awsAccessKeyId.contains('your-access')) {
      throw '🔑 AWS ACCESS KEY NOT CONFIGURED!\n\nPlease update the .env file with your actual AWS Access Key ID:\nAWS_ACCESS_KEY_ID=AKIA...';
    }
    if (Config.awsSecretAccessKey.isEmpty ||
        Config.awsSecretAccessKey == 'YOUR_ACTUAL_SECRET_KEY_HERE' ||
        Config.awsSecretAccessKey == 'REPLACE_WITH_ACTUAL_SECRET_KEY' ||
        Config.awsSecretAccessKey == 'your-actual-secret-key-here' ||
        Config.awsSecretAccessKey == 'your-secret-access-key' ||
        Config.awsSecretAccessKey == 'REPLACE_WITH_YOUR_REAL_AWS_SECRET_KEY_FROM_CONSOLE' ||
        Config.awsSecretAccessKey.toLowerCase().contains('replace') ||
        Config.awsSecretAccessKey.toLowerCase().contains('your-actual') ||
        Config.awsSecretAccessKey.toLowerCase().contains('secret-key-here') ||
        Config.awsSecretAccessKey.toLowerCase().contains('your-secret') ||
        Config.awsSecretAccessKey.toLowerCase().contains('placeholder')) {
      throw '🔐 AWS SECRET KEY NOT CONFIGURED!\n\nCurrent value: "${Config.awsSecretAccessKey}"\n\nPlease update the .env file with your real AWS Secret Access Key:\nAWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYzEXAMPLEKEY\n\n💡 Get your credentials from AWS IAM Console';
    }

    // Debug logging for APK environment
    print('✅ S3 Configuration validated:');
    print('   Bucket: ${Config.s3BucketName}');
    print('   Region: ${Config.awsRegion}');
    print('   Access Key: ${Config.awsAccessKeyId}');
    print('   Secret Key: ${Config.awsSecretAccessKey.length > 5 ? Config.awsSecretAccessKey.substring(0, 5) : Config.awsSecretAccessKey}...');

    return true;
  }

  /// Executes S3 operations with retry logic, timeout, and region fallback
  Future<T> _executeWithRetryWithRegionFallback<T>(Future<T> Function() operation) async {
    _validateS3Config();

    final commonRegions = ['us-east-1', 'us-west-2', 'eu-west-1', 'ap-southeast-1', 'ap-south-1'];
    var currentRegion = Config.awsRegion;

    for (final region in [currentRegion, ...commonRegions.where((r) => r != currentRegion)]) {
      if (region != currentRegion) {
        print('Trying S3 operation with region: $region');
        _reinitializeS3WithRegion(region);
      }

      for (int attempt = 1; attempt <= _maxRetries; attempt++) {
        try {
          return await operation().timeout(_timeout);
        } catch (e) {
          print('S3 operation attempt $attempt failed in region $region: $e');

          if (e.toString().contains('Location header') || e.toString().contains('redirect')) {
            // Region mismatch, try next region immediately
            break;
          }

          if (attempt == _maxRetries) {
            if (region == commonRegions.last) {
              // This was the last region to try
              if (e.toString().contains('Access Denied') || e.toString().contains('403')) {
                throw 'Access denied to S3 bucket "${Config.s3BucketName}". Please check your AWS credentials and bucket permissions.';
              } else if (e.toString().contains('NoSuchBucket') || e.toString().contains('404')) {
                throw 'S3 bucket "${Config.s3BucketName}" not found in any common region. Please verify the bucket name and region.';
              } else {
                throw 'Failed to connect to S3 bucket "${Config.s3BucketName}" in any region after multiple attempts: $e';
              }
            }
            break; // Try next region
          }

          // Wait before retrying in the same region
          await Future.delayed(Duration(seconds: attempt));
        }
      }
    }

    throw 'Failed to connect to S3 bucket "${Config.s3BucketName}" in all attempted regions';
  }

  /// Executes S3 operations with retry logic and timeout
  Future<T> _executeWithRetry<T>(Future<T> Function() operation) async {
    _validateS3Config();
    
    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        return await operation().timeout(_timeout);
      } catch (e) {
        print('S3 operation attempt $attempt failed: $e');
        
        if (attempt == _maxRetries) {
          if (e.toString().contains('Access Denied') || e.toString().contains('403')) {
            throw 'Access denied to S3 bucket "${Config.s3BucketName}". Please check your AWS credentials and bucket permissions.';
          } else if (e.toString().contains('NoSuchBucket') || e.toString().contains('404')) {
            throw 'S3 bucket "${Config.s3BucketName}" not found. Please verify the bucket name and region (${Config.awsRegion}).';
          } else if (e.toString().contains('TimeoutException') || e.toString().contains('timeout')) {
            throw 'Connection timeout while accessing S3. Please check your internet connection.';
          } else if (e.toString().contains('SignatureDoesNotMatch')) {
            throw 'Invalid AWS credentials. Please check your access key and secret key.';
          } else if (e.toString().contains('Location header') || e.toString().contains('redirect')) {
            throw 'S3 bucket "${Config.s3BucketName}" region mismatch. The bucket exists in a different region than configured (${Config.awsRegion}). Please check the bucket region in AWS console.';
          } else if (e.toString().contains('InvalidBucketName')) {
            throw 'Invalid S3 bucket name format: "${Config.s3BucketName}". Bucket names must be DNS-compliant.';
          } else {
            throw 'Failed to connect to S3 after $attempt attempts: $e';
          }
        }
        
        // Wait before retrying (exponential backoff)
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
    
    throw 'Unexpected error in S3 operation retry logic';
  }

  Future<List<FileItem>> getFilesByLoanNumber(String loanNumber) async {
    try {
      return await _databaseService.getFilesByLoanNumber(loanNumber);
    } catch (e) {
      print('Error fetching files from database, trying S3: $e');
      return await _getFilesFromS3ByLoanNumber(loanNumber);
    }
  }

  Future<List<FileItem>> _getFilesFromS3ByLoanNumber(String loanNumber) async {
    return await _executeWithRetryWithRegionFallback(() async {
      print('Fetching files for loan number: $loanNumber from S3 bucket: ${Config.s3BucketName}');
      
      final result = await _s3.listObjectsV2(
        bucket: Config.s3BucketName,
        prefix: 'loans/$loanNumber/',
      );

      final List<FileItem> files = [];

      if (result.contents != null) {
        print('Found ${result.contents!.length} objects for loan $loanNumber');
        
        for (final object in result.contents!) {
          if (object.key != null && !object.key!.endsWith('/')) {
            final fileName = object.key!.split('/').last;
            final fileUrl = await _generatePresignedUrl(object.key!);

            final fileItem = FileItem(
              name: fileName,
              url: fileUrl,
              type: _getFileType(fileName),
              loanNumber: loanNumber,
              uploadDate: object.lastModified ?? DateTime.now(),
              size: object.size ?? 0,
            );

            files.add(fileItem);

            try {
              await _databaseService.saveFileMetadata(fileItem);
            } catch (dbError) {
              print('⚠️ Failed to sync file to database: $dbError');
            }
          }
        }
      } else {
        print('No files found for loan number: $loanNumber');
      }

      return files;
    });
  }

  Future<List<FileItem>> getAllFiles() async {
    try {
      return await _databaseService.getAllFiles();
    } catch (e) {
      print('Error fetching files from database, trying S3: $e');
      return await _getAllFilesFromS3();
    }
  }

  Future<List<FileItem>> _getAllFilesFromS3() async {
    return await _executeWithRetryWithRegionFallback(() async {
      print('🔍 Fetching all files from S3 bucket: ${Config.s3BucketName}');

      final result = await _s3.listObjectsV2(
        bucket: Config.s3BucketName,
        // No prefix to get ALL files in the bucket
        maxKeys: 1000, // Increase limit to get more files
      );

      final List<FileItem> files = [];

      if (result.contents != null) {
        print('📁 Found ${result.contents!.length} objects in S3 bucket');
        
        for (final object in result.contents!) {
          if (object.key != null && !object.key!.endsWith('/')) {
            final fileName = object.key!.split('/').last;
            final fileUrl = await _generatePresignedUrl(object.key!);

            // Extract loan number from path - support multiple path patterns
            String loanNumber = 'general';
            final pathParts = object.key!.split('/');

            if (pathParts.length >= 2) {
              if (pathParts[0] == 'loans' && pathParts.length >= 3) {
                // loans/loanNumber/file.ext pattern
                loanNumber = pathParts[1];
              } else {
                // Any other folder structure - use first folder as loan number
                loanNumber = pathParts[0];
              }
            } else if (pathParts.length == 1) {
              // Files in root - extract from filename or use default
              final nameParts = fileName.split('_');
              if (nameParts.length > 1) {
                loanNumber = nameParts[0]; // Assume first part is loan number
              }
            }

            // Clean up loan number
            loanNumber = loanNumber.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
            if (loanNumber.isEmpty) loanNumber = 'general';

            final fileItem = FileItem(
              name: fileName,
              url: fileUrl,
              type: _getFileType(fileName),
              loanNumber: loanNumber,
              uploadDate: object.lastModified ?? DateTime.now(),
              size: object.size ?? 0,
            );

            files.add(fileItem);
            print('📄 Added file: $fileName (Loan: $loanNumber, Type: ${fileItem.type})');

            try {
              await _databaseService.saveFileMetadata(fileItem);
            } catch (dbError) {
              print('⚠️ Failed to sync file to database: $dbError');
              // Continue processing even if database sync fails
            }
          }
        }
        
        // Check if there are more files (pagination)
        if (result.isTruncated == true) {
          print('📋 More files available - fetching additional pages...');
          await _getAllFilesFromS3Paginated(files, result.nextContinuationToken);
        }
      } else {
        print('📭 No files found in S3 bucket');
      }

      print('✅ Successfully processed ${files.length} files from S3');
      return files;
    });
  }

  /// Handle pagination for large S3 buckets
  Future<void> _getAllFilesFromS3Paginated(List<FileItem> existingFiles, String? continuationToken) async {
    if (continuationToken == null) return;
    
    try {
      final result = await _s3.listObjectsV2(
        bucket: Config.s3BucketName,
        maxKeys: 1000,
        continuationToken: continuationToken,
      );

      if (result.contents != null) {
        for (final object in result.contents!) {
          if (object.key != null && !object.key!.endsWith('/')) {
            final fileName = object.key!.split('/').last;
            final fileUrl = await _generatePresignedUrl(object.key!);

            String loanNumber = 'general';
            final pathParts = object.key!.split('/');

            if (pathParts.length >= 2) {
              if (pathParts[0] == 'loans' && pathParts.length >= 3) {
                loanNumber = pathParts[1];
              } else {
                loanNumber = pathParts[0];
              }
            }

            loanNumber = loanNumber.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
            if (loanNumber.isEmpty) loanNumber = 'general';

            final fileItem = FileItem(
              name: fileName,
              url: fileUrl,
              type: _getFileType(fileName),
              loanNumber: loanNumber,
              uploadDate: object.lastModified ?? DateTime.now(),
              size: object.size ?? 0,
            );

            existingFiles.add(fileItem);
          }
        }
        
        // Continue pagination if needed
        if (result.isTruncated == true) {
          await _getAllFilesFromS3Paginated(existingFiles, result.nextContinuationToken);
        }
      }
    } catch (e) {
      print('⚠️ Error in pagination: $e');
      // Don't throw error, just log it and continue with what we have
    }
  }

  Future<bool> uploadFile({
    required String loanNumber,
    required File file,
    required String fileName,
  }) async {
    try {
      return await _executeWithRetry(() async {
        final key = 'loans/$loanNumber/$fileName';
        final fileBytes = await file.readAsBytes();

        print('Uploading file: $key (${fileBytes.length} bytes)');

        await _s3.putObject(
          bucket: Config.s3BucketName,
          key: key,
          body: fileBytes,
          contentType: _getContentType(fileName),
        );

        final fileUrl = await _generatePresignedUrl(key);
        final fileItem = FileItem(
          name: fileName,
          url: fileUrl,
          type: _getFileType(fileName),
          loanNumber: loanNumber,
          uploadDate: DateTime.now(),
          size: fileBytes.length,
        );

        try {
          await _databaseService.saveFileMetadata(fileItem);
        } catch (dbError) {
          print('Failed to save file metadata to database: $dbError');
        }

        print('Successfully uploaded file: $fileName');
        return true;
      });
    } catch (e) {
      print('Error uploading file: $e');
      return false;
    }
  }

  Future<bool> uploadFileFromBytes({
    required String loanNumber,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    try {
      return await _executeWithRetry(() async {
        final key = 'loans/$loanNumber/$fileName';

        print('Uploading file from bytes: $key (${fileBytes.length} bytes)');

        await _s3.putObject(
          bucket: Config.s3BucketName,
          key: key,
          body: fileBytes,
          contentType: _getContentType(fileName),
        );

        final fileUrl = await _generatePresignedUrl(key);
        final fileItem = FileItem(
          name: fileName,
          url: fileUrl,
          type: _getFileType(fileName),
          loanNumber: loanNumber,
          uploadDate: DateTime.now(),
          size: fileBytes.length,
        );

        try {
          await _databaseService.saveFileMetadata(fileItem);
        } catch (dbError) {
          print('Failed to save file metadata to database: $dbError');
        }

        print('Successfully uploaded file from bytes: $fileName');
        return true;
      });
    } catch (e) {
      print('Error uploading file from bytes: $e');
      return false;
    }
  }

  Future<bool> deleteFile(String loanNumber, String fileName) async {
    try {
      return await _executeWithRetry(() async {
        final key = 'loans/$loanNumber/$fileName';

        print('Deleting file: $key');

        await _s3.deleteObject(
          bucket: Config.s3BucketName,
          key: key,
        );

        try {
          await _databaseService.deleteFileMetadata(loanNumber, fileName);
        } catch (dbError) {
          print('Failed to delete file metadata from database: $dbError');
        }

        print('Successfully deleted file: $fileName');
        return true;
      });
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }

  String _getFileType(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return 'image';
      case 'mp4':
      case 'mov':
      case 'avi':
        return 'video';
      case 'pdf':
        return 'pdf';
      case 'doc':
      case 'docx':
      case 'txt':
        return 'document';
      default:
        return 'unknown';
    }
  }

  String _getContentType(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  /// Generate URL for accessing S3 objects (using public access or signed URLs)
  Future<String> _generatePresignedUrl(String key) async {
    try {
      // For now, use direct S3 URL - this assumes bucket has proper public read policy
      // or the files are accessible via proper IAM permissions
      final url = 'https://${Config.s3BucketName}.s3.${Config.awsRegion}.amazonaws.com/$key';
      print('📎 Generated S3 URL for $key: $url');
      return url;
    } catch (e) {
      print('⚠️ Failed to generate URL for $key: $e');
      // Fallback to config-based URL
      return '${Config.s3BaseUrl}/$key';
    }
  }
}