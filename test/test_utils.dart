// 测试工具类
//
// 提供测试中常用的工具函数和模拟数据

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';

/// 测试工具类
class TestUtils {
  /// 创建模拟的GPS位置数据
  static Position createMockPosition({
    double latitude = 37.7749,
    double longitude = -122.4194,
    double speed = 10.0, // m/s
    double accuracy = 5.0,
    DateTime? timestamp,
  }) {
    return Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: timestamp ?? DateTime.now(),
      accuracy: accuracy,
      altitude: 0.0,
      heading: 0.0,
      speed: speed,
      speedAccuracy: 1.0,
      altitudeAccuracy: 1.0,
      headingAccuracy: 1.0,
    );
  }
  
  /// 创建模拟的摄像头描述
  static CameraDescription createMockCamera({
    String name = 'Test Camera',
    CameraLensDirection lensDirection = CameraLensDirection.back,
    int sensorOrientation = 90,
  }) {
    return CameraDescription(
      name: name,
      lensDirection: lensDirection,
      sensorOrientation: sensorOrientation,
    );
  }
  
  /// 创建模拟的视频文件
  static Future<File> createMockVideoFile({
    String fileName = 'test_video.mp4',
    int sizeInBytes = 1024 * 1024, // 1MB
  }) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    
    // 创建模拟的视频文件内容
    final bytes = Uint8List(sizeInBytes);
    for (int i = 0; i < bytes.length; i++) {
      bytes[i] = i % 256;
    }
    
    await file.writeAsBytes(bytes);
    return file;
  }
  
  /// 创建模拟的缩略图数据
  static Uint8List createMockThumbnail({
    int width = 100,
    int height = 100,
  }) {
    // 创建简单的RGB图像数据
    final bytes = Uint8List(width * height * 3);
    for (int i = 0; i < bytes.length; i += 3) {
      bytes[i] = 255; // R
      bytes[i + 1] = 0; // G
      bytes[i + 2] = 0; // B
    }
    return bytes;
  }
  
  /// 等待异步操作完成
  static Future<void> waitForAsync({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
  }
  
  /// 验证文件是否存在
  static Future<bool> fileExists(String path) async {
    return File(path).exists();
  }
  
  /// 清理测试文件
  static Future<void> cleanupTestFiles(List<String> filePaths) async {
    for (final path in filePaths) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }
  
  /// 创建测试用的临时目录
  static Future<Directory> createTestDirectory(String name) async {
    final tempDir = await getTemporaryDirectory();
    final testDir = Directory('${tempDir.path}/$name');
    if (!await testDir.exists()) {
      await testDir.create(recursive: true);
    }
    return testDir;
  }
  
  /// 模拟网络延迟
  static Future<void> simulateNetworkDelay({
    Duration delay = const Duration(milliseconds: 500),
  }) async {
    await Future.delayed(delay);
  }
  
  /// 验证Widget是否在屏幕上可见
  static bool isWidgetVisible(WidgetTester tester, Finder finder) {
    try {
      final widget = tester.widget(finder);
      final renderObject = tester.renderObject(finder);
      return widget != null && renderObject != null;
    } catch (e) {
      return false;
    }
  }
  
  /// 等待Widget出现
  static Future<void> waitForWidget(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final endTime = DateTime.now().add(timeout);
    
    while (DateTime.now().isBefore(endTime)) {
      await tester.pump(const Duration(milliseconds: 100));
      
      if (finder.evaluate().isNotEmpty) {
        return;
      }
    }
    
    throw TimeoutException(
      'Widget not found within timeout: ${finder.description}',
      timeout,
    );
  }
  
  /// 模拟用户滑动操作
  static Future<void> simulateSwipe(
    WidgetTester tester,
    Finder finder,
    Offset offset,
  ) async {
    await tester.drag(finder, offset);
    await tester.pumpAndSettle();
  }
  
  /// 模拟长按操作
  static Future<void> simulateLongPress(
    WidgetTester tester,
    Finder finder,
  ) async {
    await tester.longPress(finder);
    await tester.pumpAndSettle();
  }
  
  /// 验证性能指标
  static void verifyPerformance(
    Duration actualDuration,
    Duration expectedMaxDuration,
    String operationName,
  ) {
    if (actualDuration > expectedMaxDuration) {
      throw AssertionError(
        '$operationName took ${actualDuration.inMilliseconds}ms, '
        'expected less than ${expectedMaxDuration.inMilliseconds}ms',
      );
    }
  }
  
  /// 创建测试用的SharedPreferences模拟数据
  static Map<String, dynamic> createMockPreferences() {
    return {
      'camera_resolution': '1920x1080',
      'video_quality': 'high',
      'auto_split_enabled': true,
      'split_duration_minutes': 10,
      'gps_enabled': true,
      'speed_unit': 'kmh',
      'theme_mode': 'system',
    };
  }
  
  /// 验证错误处理
  static void verifyErrorHandling(
    Function() operation,
    Type expectedErrorType,
  ) {
    bool errorCaught = false;
    
    try {
      operation();
    } catch (e) {
      if (e.runtimeType == expectedErrorType) {
        errorCaught = true;
      } else {
        throw AssertionError(
          'Expected error type $expectedErrorType, but got ${e.runtimeType}',
        );
      }
    }
    
    if (!errorCaught) {
      throw AssertionError(
        'Expected error of type $expectedErrorType, but no error was thrown',
      );
    }
  }
  
  /// 模拟设备传感器数据
  static Map<String, double> createMockSensorData({
    double accelerometerX = 0.0,
    double accelerometerY = 0.0,
    double accelerometerZ = 9.8,
    double gyroscopeX = 0.0,
    double gyroscopeY = 0.0,
    double gyroscopeZ = 0.0,
  }) {
    return {
      'accelerometer_x': accelerometerX,
      'accelerometer_y': accelerometerY,
      'accelerometer_z': accelerometerZ,
      'gyroscope_x': gyroscopeX,
      'gyroscope_y': gyroscopeY,
      'gyroscope_z': gyroscopeZ,
    };
  }
  
  /// 验证内存使用情况
  static void verifyMemoryUsage({
    int maxMemoryMB = 100,
  }) {
    // 在实际应用中，这里可以添加内存使用情况的检查
    // 目前只是一个占位符
    print('Memory usage check: max allowed ${maxMemoryMB}MB');
  }
  
  /// 创建测试报告
  static void generateTestReport({
    required String testName,
    required bool passed,
    Duration? duration,
    String? errorMessage,
  }) {
    final status = passed ? 'PASSED' : 'FAILED';
    final durationStr = duration != null ? ' (${duration.inMilliseconds}ms)' : '';
    final errorStr = errorMessage != null ? '\nError: $errorMessage' : '';
    
    print('[$status] $testName$durationStr$errorStr');
  }
}

/// 测试常量
class TestConstants {
  static const Duration defaultTimeout = Duration(seconds: 10);
  static const Duration shortTimeout = Duration(seconds: 3);
  static const Duration longTimeout = Duration(seconds: 30);
  
  static const double defaultLatitude = 37.7749;
  static const double defaultLongitude = -122.4194;
  static const double defaultSpeed = 10.0; // m/s
  static const double defaultAccuracy = 5.0;
  
  static const String testVideoFileName = 'test_video.mp4';
  static const String testThumbnailFileName = 'test_thumbnail.jpg';
  
  static const int defaultVideoWidth = 1920;
  static const int defaultVideoHeight = 1080;
  static const int defaultThumbnailWidth = 100;
  static const int defaultThumbnailHeight = 100;
}

/// 自定义测试匹配器
class CustomMatchers {
  /// 验证速度值在合理范围内
  static Matcher isValidSpeed() {
    return predicate<double>(
      (speed) => speed >= 0.0 && speed <= 200.0, // 0-200 km/h
      'is a valid speed value',
    );
  }
  
  /// 验证GPS坐标有效
  static Matcher isValidCoordinate() {
    return predicate<double>(
      (coord) => coord >= -180.0 && coord <= 180.0,
      'is a valid coordinate',
    );
  }
  
  /// 验证文件大小合理
  static Matcher isValidFileSize() {
    return predicate<int>(
      (size) => size > 0 && size < 1024 * 1024 * 1024, // 小于1GB
      'is a valid file size',
    );
  }
  
  /// 验证时间戳有效
  static Matcher isValidTimestamp() {
    return predicate<DateTime>(
      (timestamp) {
        final now = DateTime.now();
        final oneYearAgo = now.subtract(const Duration(days: 365));
        return timestamp.isAfter(oneYearAgo) && timestamp.isBefore(now.add(const Duration(minutes: 1)));
      },
      'is a valid timestamp',
    );
  }
}