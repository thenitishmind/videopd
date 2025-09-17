import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  static String get s3BucketName => dotenv.env['S3_BUCKET_NAME'] ?? '';
  static String get awsAccessKeyId => dotenv.env['AWS_ACCESS_KEY_ID'] ?? '';
  static String get awsSecretAccessKey => dotenv.env['AWS_SECRET_ACCESS_KEY'] ?? '';
  static String get awsRegion => dotenv.env['AWS_REGION'] ?? 'us-east-1';
  static String get awsBearerToken => dotenv.env['AWS_BEARER_TOKEN_BEDROCK'] ?? '';

  // Generate S3 URL based on current region configuration
  static String get s3BaseUrl => 'https://${s3BucketName}.s3.${awsRegion}.amazonaws.com';
}