# Video Pd

A comprehensive Flutter application for viewing, uploading, and managing documents, images, and videos with Firebase authentication and AWS S3 integration.

## 📱 Application Overview

Video Pd is a mobile application designed to handle document management for business loans. It provides secure authentication, cloud storage, and multi-format file viewing capabilities.

### 🎯 Key Features

- **Firebase Authentication**: Secure user authentication and session management
- **AWS S3 Integration**: Cloud storage for documents, images, and videos
- **Multi-format Support**: View PDFs, images, and videos
- **Document Organization**: Files organized by loan numbers
- **Real-time Database**: Firebase Realtime Database for metadata storage
- **Cross-platform**: Built with Flutter for iOS and Android

## 🏗️ Project Structure

```text
videopd/
├── lib/
│   ├── main.dart                    # Application entry point & authentication wrapper
│   ├── models/                      # Data models
│   │   └── file_item.dart          # File metadata model
│   ├── screens/                     # UI screens
│   │   ├── home_screen.dart        # Main navigation screen
│   │   ├── login_screen.dart       # Authentication screen
│   │   ├── upload_screen.dart      # File upload interface
│   │   ├── view_screen.dart        # File viewing interface
│   │   ├── test_database_screen.dart       # Database testing
│   │   ├── system_test_screen.dart         # System testing
│   │   └── comprehensive_test_screen.dart  # Comprehensive testing
│   ├── services/                    # Business logic services
│   │   ├── auth_service.dart       # Firebase authentication
│   │   ├── database_service.dart   # Firebase database operations
│   │   └── s3_service.dart         # AWS S3 operations
│   ├── utils/                       # Utilities and configurations
│   │   └── config.dart             # Environment configuration
│   └── widgets/                     # Reusable UI components
│       └── file_display_widget.dart # File display component
├── android/                         # Android-specific configuration
├── assets/                          # Static assets
│   └── images/                      # App icons and images
├── .env                            # Environment variables
├── pubspec.yaml                    # Dependencies and project configuration
└── firebase configuration files
```

## 🔄 Application Workflow

### 1. Authentication Flow

```text
App Launch → Firebase Init → Auth Check → Login Screen / Home Screen
```

### 2. Main Navigation Flow

```text
Home Screen → Bottom Navigation (View Files / Upload Files)
```

### 3. File Management Flow

```text
Upload Screen → File Selection → S3 Upload → Database Metadata Save
View Screen → Loan Number Input → Database Query → File List → File Viewer
```

## 📋 Module Documentation

### 🔐 Authentication Module

**Components:**

- **AuthWrapper** (`main.dart`): Manages authentication state
- **LoginScreen** (`screens/login_screen.dart`): User authentication interface
- **AuthService** (`services/auth_service.dart`): Firebase authentication logic

**Features:**

- Email/password authentication
- Persistent login sessions
- Automatic authentication state management
- Error handling and user feedback

### 🏠 Navigation Module

**Components:**

- **HomeScreen** (`screens/home_screen.dart`): Main navigation hub
- Bottom navigation bar with two main sections

**Features:**

- View files section
- Upload files section
- Test screens for development
- User logout functionality

### 📁 File Management Module

**Upload Component:**

- **UploadScreen** (`screens/upload_screen.dart`): File upload interface
- **S3Service** (`services/s3_service.dart`): Cloud storage operations

**Viewing Component:**

- **ViewScreen** (`screens/view_screen.dart`): File browsing interface
- **FileDisplayWidget** (`widgets/file_display_widget.dart`): File display component

**Features:**

- Multi-format file upload (images, videos, PDFs)
- Loan number-based organization
- File preview and viewing
- Download capabilities

### 💾 Data Management Module

**Components:**

- **DatabaseService** (`services/database_service.dart`): Firebase database operations
- **FileItem** (`models/file_item.dart`): File metadata model

**Features:**

- File metadata storage
- Loan number-based queries
- Real-time data synchronization
- Data validation and error handling

### ⚙️ Configuration Module

**Components:**

- **Config** (`utils/config.dart`): Environment configuration
- **.env**: Environment variables

**Features:**

- AWS credentials management
- Firebase configuration
- Environment-specific settings

## 🛠️ Technical Stack

**Frontend:**

- **Flutter 3.0+**: Cross-platform mobile framework
- **Material Design 3**: UI components and theming
- **State Management**: StatefulWidget pattern

**Backend Services:**

- **Firebase Authentication**: User management
- **Firebase Realtime Database**: Metadata storage
- **AWS S3**: File storage

**Key Dependencies:**

```yaml
Core:
- flutter: SDK
- firebase_core: ^2.24.2
- firebase_auth: ^4.15.3
- firebase_database: ^10.4.0

Storage & Files:
- aws_s3_api: ^2.0.0
- file_picker: ^8.0.0
- image_picker: ^1.0.4
- path_provider: ^2.1.1

Media & Display:
- video_player: ^2.8.1
- photo_view: ^0.14.0
- flutter_pdfview: ^1.3.2
- cached_network_image: ^3.3.0

Utilities:
- flutter_dotenv: ^5.1.0
- dio: ^5.3.3
- permission_handler: ^11.1.0
```

## 🚀 Getting Started

**Prerequisites:**

- Flutter SDK 3.0+
- Android Studio / VS Code
- Firebase project
- AWS S3 bucket

**Installation:**

1. **Clone the repository**

   ```bash
   git clone [repository-url]
   cd videopd
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Configure environment variables**

   Create `.env` file in root directory:

   ```env
   S3_BUCKET_NAME=your-bucket-name
   AWS_ACCESS_KEY_ID=your-access-key
   AWS_SECRET_ACCESS_KEY=your-secret-key
   AWS_REGION=us-east-1
   ```

4. **Firebase setup**

   - Add `google-services.json` to `android/app/`
   - Configure Firebase Authentication
   - Set up Realtime Database

5. **Run the application**

   ```bash
   flutter run
   ```

## 🧪 Testing

The application includes comprehensive testing screens:

- **DatabaseTestScreen**: Test database operations
- **SystemTestScreen**: Test system functionality
- **ComprehensiveTestScreen**: Full application testing

Access these through the drawer menu in the home screen.

## 📱 Platform Support

- **Android**: Full support with Material Design
- **iOS**: Compatible (requires iOS-specific Firebase configuration)

## 🔒 Security Features

- Firebase Authentication with email/password
- Secure AWS S3 integration
- Environment variable protection
- Session management
- Error handling and validation

## 📄 File Format Support

- **Images**: PNG, JPG, JPEG, GIF
- **Videos**: MP4, MOV, AVI
- **Documents**: PDF
- **Organization**: By loan number

## 🏢 Business Logic

The application is designed specifically for business loan document management:

- Files are organized by loan numbers
- Metadata tracking for compliance
- Secure access control
- Audit trail through database logging

## 📞 Support & Maintenance

For development and maintenance:

- Check logs in debug console
- Use test screens for troubleshooting
- Monitor Firebase console for authentication issues
- Check AWS S3 console for storage issues

## 🔄 Future Enhancements

Potential improvements:

- Offline mode support
- Advanced search functionality
- Document categorization
- Batch upload capabilities
- Advanced user roles and permissions

---

## 👨‍💻 Credits

**Created and Designed by**: Nitish

This application was conceptualized, designed, and developed by Nitish, combining modern mobile development practices with robust cloud infrastructure to deliver a comprehensive document management solution.

---

**Version**: 1.0.0+1  
**Last Updated**: September 2025  
**Platform**: Flutter  
**License**: Private/Proprietary