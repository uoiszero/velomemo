# VeloMemo

An intelligent dash cam application developed with Flutter, designed specifically for mobile devices, providing professional video recording and management features.

## 🚗 Application Overview

VeloMemo is a powerful dash cam application that transforms your smartphone or tablet into a professional driving recorder. The app adopts modern Material Design language, providing an intuitive and user-friendly interface with rich feature sets.

## ✨ Core Features

### 🎨 Professional Icon Design
- **Dash Cam Theme**: Professional icon specifically designed for dash cam applications
- **Camera Elements**: Prominent camera body design to enhance app functionality recognition
- **Speed Dial**: Integrated speed dial elements reflecting driving monitoring features
- **Recording Indicator**: Red recording indicator light for intuitive recording function expression
- **Multi-resolution Support**: Complete Android icon specification support (hdpi, xhdpi, xxhdpi, xxxhdpi)
- **Adaptive Icons**: Support for Android 8.0+ Adaptive Icon features
- **SVG Vector Format**: Using SVG source files for easy modification and maintenance

### 📹 Smart Video Recording
- **Multi-resolution Support**: From 240p to 4K ultra-clear quality, meeting different storage and quality needs
- **Automatic Video Segmentation**: Supports automatic video file segmentation by time to avoid oversized single files
- **Real-time Recording Indicator**: Displays red border and time watermark during recording for clear status indication
- **Smart File Naming**: Automatically generates sequential file names based on recording time
- **Background Recording Optimization**: Automatically dims screen during recording to extend battery life

### 🧭 Intelligent Compass System
- **Real-time Direction Display**: Shows current heading with both text and numerical degree indicators
- **Visual Scale Bar**: Horizontal scale with tick marks every 10 degrees (short) and 30 degrees (long)
- **Direction Labels**: Displays Chinese direction names (北/东/南/西) at cardinal points
- **Smooth Animation**: Real-time smooth direction updates using magnetometer and accelerometer sensors
- **Wide View Range**: 180-degree view range (±90 degrees) for comprehensive direction awareness
- **Color-coded Directions**: Different colors for major directions (North: Red, East: Blue, South: Green, West: Orange)

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
- **sensors_plus: ^6.0.1**: Magnetometer and accelerometer sensor access for compass functionality

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
- Intelligent compass overlay with direction indicators and scale bar

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

## 🎨 Icon Management

### Icon Features
- **Professional Design**: Icon specifically designed for dash cam applications
- **Camera Body**: Prominent camera elements, enlarged by 50% for enhanced visual impact
- **Speed Dial**: Integrated speed monitoring elements
- **Recording Indicator**: Red indicator light expressing recording functionality
- **Clean Design**: Text elements removed to maintain icon simplicity

### Quick Icon Updates

#### Using Icon Management Script (Recommended)
```bash
# Complete update (generate + apply)
./update_icons.sh

# Generate PNG icons only
./update_icons.sh --generate

# Apply to project only
./update_icons.sh --apply

# Show help
./update_icons.sh --help
```

#### Using Makefile (macOS/Linux)
```bash
make icon-update            # Complete icon update
make icon-generate          # Generate PNG icons
make icon-apply             # Apply to project
make icon-help              # Show help
```

### Custom Icons

1. **Replace Source Files**:
   - Replace `assets/icons/app_icon.svg` (main icon)
   - Replace `assets/icons/app_icon_adaptive.svg` (adaptive icon)
   - Run `./update_icons.sh` to update

2. **Modify Configuration**:
   - Edit `flutter_launcher_icons` configuration in `pubspec.yaml`
   - Run `flutter packages pub run flutter_launcher_icons:main`

### Icon File Structure
```
assets/icons/
├── app_icon.svg              # Main icon source file
├── app_icon.png              # Main icon PNG
├── app_icon_adaptive.svg     # Adaptive icon source file
├── app_icon_adaptive.png     # Adaptive icon PNG
└── app_icon_foreground.png   # Foreground icon PNG
```

### Development Tools

The project provides a complete development toolchain:

- **`run_tests.sh`** / **`run_tests.bat`**: Cross-platform test scripts
- **`Makefile`**: Convenient development command collection
- **`update_icons.sh`**: Icon update and management script
- **`TESTING.md`**: Detailed testing guide and best practices
- **`ICON_GUIDE.md`**: Icon design guide and update instructions

For more testing-related information, please refer to [TESTING.md](TESTING.md).
For more icon-related information, please refer to [ICON_GUIDE.md](ICON_GUIDE.md).

## 🔧 Development Notes

### Project Structure
```
velomemo/
├── .gitignore              # Git ignore file configuration
├── .metadata               # Flutter metadata
├── LICENSE                 # MIT license file
├── Makefile               # Development command collection
├── README.md              # English project documentation
├── analysis_options.yaml   # Dart code analysis configuration
├── devtools_options.yaml   # Flutter DevTools configuration
├── pubspec.yaml           # Project dependency configuration
├── pubspec.lock           # Dependency version lock file
├── example_video_segmentation_usage.dart # Video segmentation usage example
│
├── android/               # Android platform configuration
│   ├── app/
│   │   ├── build.gradle.kts
│   │   └── src/
│   ├── build.gradle.kts
│   ├── gradle/
│   ├── gradle.properties
│   ├── gradlew
│   ├── gradlew.bat
│   ├── local.properties
│   └── settings.gradle.kts
│
├── assets/                # Application resource files
│   └── icons/             # Application icon resources
│       ├── app_icon.svg   # Main icon source file
│       ├── app_icon.png   # Main icon PNG
│       ├── app_icon_adaptive.svg # Adaptive icon source file
│       ├── app_icon_adaptive.png # Adaptive icon PNG
│       └── app_icon_foreground.png # Foreground icon PNG
│
├── docs/                  # Project documentation
│   ├── BUILD_GUIDE.md     # Build guide
│   ├── ICON_GUIDE.md      # Icon design guide
│   ├── README_zh.md       # Chinese project documentation
│   └── TESTING.md         # Testing guide
│
├── lib/                   # Main source code
│   ├── main.dart          # Application entry and main recording interface
│   ├── file_list_page.dart # File management page
│   ├── settings_page.dart  # Settings page
│   ├── speed_calculator.dart # Speed calculator
│   ├── speed_display_widget.dart # Speed display widget
│   ├── compass_widget.dart # Compass direction indicator widget
│   ├── video_recorder.dart # Video recorder
│   ├── video_thumbnail_manager.dart # Video thumbnail management
│   ├── video_thumbnail_widget.dart # Video thumbnail widget
│   └── utils.dart         # Utility functions
│
├── scripts/               # Build and development scripts
│   ├── build_apk.bat      # Windows APK build script
│   ├── build_apk.sh       # macOS/Linux APK build script
│   ├── run_tests.bat      # Windows test script
│   ├── run_tests.sh       # macOS/Linux test script
│   └── update_icons.sh    # Icon update script
│
└── test/                  # Test files
    ├── integration_test.dart # Integration tests
    ├── speed_calculator_test.dart # Speed calculator tests
    ├── speed_display_widget_test.dart # Speed display widget tests
    ├── video_recorder_test.dart # Video recorder tests
    ├── video_recorder_test.mocks.dart # Video recorder mock objects
    ├── video_thumbnail_manager_test.dart # Thumbnail management tests
    ├── video_thumbnail_manager_test.mocks.dart # Thumbnail management mock objects
    ├── test_utils.dart     # Test utility functions
    └── widget_test.dart    # Basic widget tests
```

### Key Feature Implementation
- **Video Recording**: High-quality video recording using Camera plugin
- **File Management**: Custom file browser supporting various operations
- **Settings Persistence**: User preference saving using SharedPreferences
- **Permission Handling**: Smart permission requests and status management
- **Compass Navigation**: Real-time direction sensing using device magnetometer and accelerometer
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