# VeloMemo

An intelligent dash cam application developed with Flutter, designed specifically for mobile devices, providing professional video recording and management features.

## 🚗 Application Overview

VeloMemo is a powerful dash cam application that transforms your smartphone or tablet into a professional driving recorder. The app adopts modern Material Design language, providing an intuitive and user-friendly interface with rich feature sets.

## ✨ Core Features

### 📹 Smart Video Recording
- **Multi-resolution Support**: From 240p to 4K ultra-clear quality, meeting different storage and quality needs
- **Automatic Video Segmentation**: Supports automatic video file segmentation by time to avoid oversized single files
- **Real-time Recording Indicator**: Displays red border and time watermark during recording for clear status indication
- **Smart File Naming**: Automatically generates sequential file names based on recording time
- **Background Recording Optimization**: Automatically dims screen during recording to extend battery life

### 🎥 Camera Management
- **Multi-camera Support**: Automatically detects and supports all cameras on the device
- **Smart Camera Selection**: Prioritizes rear camera for optimal recording results
- **Real-time Preview**: Full-screen camera preview - what you see is what you record
- **Dynamic Switching**: Supports switching between different cameras in settings

### 📁 File Management System
- **Dedicated Storage Directory**: Unified video file management in device's Movies/VeloMemo directory
- **Multiple Display Modes**: Supports both list view and grid view
- **Flexible Sorting Options**: Sort by filename, size, or date in ascending or descending order
- **Detailed File Information**: Displays file size, creation time, and other detailed information
- **Batch Operations**: Supports viewing, sharing, and deleting files

### ⚙️ Smart Settings System
- **Quality Adjustment**: 6-level quality settings from space-saving to ultra-clear
- **Camera Configuration**: Supports selection and configuration of different cameras
- **Storage Monitoring**: Real-time display of available storage space and estimated recording duration
- **User Preference Saving**: Automatically saves user setting preferences

### 🔋 Power Optimization
- **Screen Brightness Control**: Automatically dims screen during recording to save power
- **Smart UI Hiding**: Automatically hides interface elements during recording to reduce interference
- **Immersive Experience**: Supports full-screen recording mode to maximize recording area

### 🛡️ Permission Management
- **Smart Permission Requests**: Automatically requests camera, microphone, and storage permissions
- **Permission Status Detection**: Real-time detection of permission status to ensure proper functionality
- **Friendly Error Handling**: Provides clear prompts when permissions are denied

## 🏗️ Technical Architecture

### Development Framework
- **Flutter 3.8.1+**: Cross-platform mobile application development framework
- **Dart Language**: Modern programming language providing excellent performance

### Core Dependencies
- **camera: ^0.10.5+9**: Camera control and video recording
- **permission_handler: ^11.3.1**: Permission management
- **path_provider: ^2.1.2**: File path management
- **shared_preferences: ^2.2.2**: Local data storage
- **screen_brightness: ^0.2.2+1**: Screen brightness control
- **package_info_plus: ^4.2.0**: Application information retrieval
- **intl: ^0.19.0**: Internationalization and date formatting

### Platform Support
- **Android**: Full feature support, including native video segmentation
- **iOS**: Basic feature support (planned)

## 📱 User Interface

### Main Recording Interface
- Full-screen camera preview
- Floating recording control button
- Real-time storage space display
- Recording status indicator
- Smart UI auto-hide

### File Management Interface
- Clear file list display
- Multiple sorting and display options
- File detailed information display
- Convenient operation menu

### Settings Interface
- Clearly categorized setting options
- Real-time setting preview
- Detailed feature descriptions
- Application information display

## 🚀 Quick Start

### Environment Requirements
- Flutter SDK 3.8.1 or higher
- Dart SDK 3.0.0 or higher
- Android Studio or VS Code
- Android device or emulator (API 21+)

### Installation Steps

1. **Clone Project**
   ```bash
   git clone <repository-url>
   cd velomemo
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Run Application**
   ```bash
   flutter run
   ```

### Build Release Version

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release
```

## 📋 Usage Instructions

### First Use
1. After launching the app, the system will automatically request necessary permissions
2. Grant camera, microphone, and storage permissions
3. The app will automatically detect and configure optimal camera settings

### Start Recording
1. Tap the red record button to start recording
2. A red border will be displayed during recording
3. Tap the button again to stop recording
4. Video files will be automatically saved to the dedicated directory

### View Recorded Files
1. Tap the folder icon to enter file management
2. Browse recorded video files
3. Supports playback, sharing, and deletion operations

### Adjust Settings
1. Tap the settings icon to enter the settings page
2. Adjust quality and camera as needed
3. Settings will be automatically saved and take effect immediately

## 🧪 Testing

### Test Coverage
The project includes a comprehensive test suite to ensure code quality and functional stability:

- **Unit Tests**: 50+ test cases covering core business logic
  - Speed calculator tests
  - Video recording functionality tests
  - Video thumbnail management tests
- **Widget Tests**: UI component functionality verification
  - Speed display widget tests (47 test cases)
  - Basic UI component tests
- **Integration Tests**: Component interaction verification

### Quick Test Commands

#### Using Test Scripts (Recommended)
```bash
# macOS/Linux
./run_tests.sh              # Run all tests
./run_tests.sh --unit       # Unit tests
./run_tests.sh --widget     # Widget tests
./run_tests.sh --coverage   # Generate coverage report

# Windows
run_tests.bat -a            # Run all tests
run_tests.bat -u            # Unit tests
run_tests.bat -c            # Generate coverage report
```

#### Using Makefile (macOS/Linux)
```bash
make test                    # Run all tests
make test-unit              # Unit tests
make test-widget            # Widget tests
make test-coverage          # Coverage report
```

#### Direct Flutter Commands
```bash
flutter test                # Run all tests
flutter test --coverage     # Generate coverage report
```

### Development Tools

The project provides a complete development toolchain:

- **`run_tests.sh`** / **`run_tests.bat`**: Cross-platform test scripts
- **`Makefile`**: Convenient development command collection
- **`TESTING.md`**: Detailed testing guide and best practices

For more testing-related information, please refer to [TESTING.md](TESTING.md).

## 🔧 Development Notes

### Project Structure
```
lib/
├── main.dart              # Application entry and main recording interface
├── file_list_page.dart     # File management page
├── settings_page.dart      # Settings page
├── speed_calculator.dart   # Speed calculator
├── speed_display_widget.dart # Speed display widget
├── video_recorder.dart     # Video recorder
├── video_thumbnail_manager.dart # Video thumbnail management
└── video_thumbnail_widget.dart # Video thumbnail widget

test/
├── integration_test.dart   # Integration tests
├── speed_calculator_test.dart # Speed calculator tests
├── speed_display_widget_test.dart # Speed display widget tests
├── video_recorder_test.dart # Video recorder tests
├── video_thumbnail_manager_test.dart # Thumbnail management tests
└── widget_test.dart        # Basic widget tests
```

### Key Feature Implementation
- **Video Recording**: High-quality video recording using Camera plugin
- **File Management**: Custom file browser supporting various operations
- **Settings Persistence**: User preference saving using SharedPreferences
- **Permission Handling**: Smart permission requests and status management
- **UI Optimization**: Responsive design adapting to different screen sizes
- **Test Coverage**: Complete unit tests, widget tests, and integration tests

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Welcome to submit Issues and Pull Requests to help improve this project!

## 📞 Contact

If you have any questions or suggestions, please contact us through:
- Submit GitHub Issues
- Send email to project maintainers

---

**VeloMemo** - Record Every Journey 🚗📹