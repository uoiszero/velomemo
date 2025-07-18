import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:screen_brightness/screen_brightness.dart';

/// 视频录制器
/// 负责管理摄像头初始化、视频录制、文件管理等功能
class VideoRecorder {
  static VideoRecorder? _instance;
  static VideoRecorder get instance => _instance ??= VideoRecorder._();
  
  VideoRecorder._();
  
  // 摄像头相关
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isPermissionGranted = false;
  
  // 录制状态
  bool _isRecording = false;
  String? _customFileName;
  
  // 视频分割相关
  Timer? _segmentTimer;
  bool _enableVideoSegmentation = true;
  int _segmentDurationMinutes = 1;
  int _currentSegmentIndex = 0;
  bool _isUsingNativeRecording = false;
  
  // Platform Channel for native video segmentation
  static const platform = MethodChannel('com.yueao.velomemo/video_recorder');
  
  // 屏幕亮度控制
  double? _originalBrightness;
  bool _isScreenDimmed = false;
  
  // 录制状态监听器
  final List<Function(bool)> _recordingStateListeners = [];
  final List<Function(String)> _recordingMessageListeners = [];
  
  /// 获取摄像头控制器
  CameraController? get cameraController => _cameraController;
  
  /// 获取摄像头初始化状态
  bool get isCameraInitialized => _isCameraInitialized;
  
  /// 获取权限状态
  bool get isPermissionGranted => _isPermissionGranted;
  
  /// 获取录制状态
  bool get isRecording => _isRecording;
  
  /// 获取屏幕调暗状态
  bool get isScreenDimmed => _isScreenDimmed;
  
  /// 设置权限状态
  void setPermissionGranted(bool granted) {
    _isPermissionGranted = granted;
  }
  
  /// 初始化摄像头
  Future<void> initializeCamera(List<CameraDescription> cameras) async {
    if (cameras.isEmpty) {
      print('没有可用的摄像头');
      return;
    }
    
    await _setupCamera(cameras);
  }
  
  /// 设置摄像头配置
  Future<void> _setupCamera(List<CameraDescription> cameras) async {
    try {
      // 释放之前的摄像头资源
      await _cameraController?.dispose();
      
      // 从设置中加载分辨率和摄像头选择
      final prefs = await SharedPreferences.getInstance();
      final resolutionIndex = prefs.getInt('camera_resolution') ?? 1;
      final cameraIndex = prefs.getInt('selected_camera') ?? await _getDefaultCameraIndex(cameras);
      
      ResolutionPreset resolution;
      switch (resolutionIndex) {
        case 0:
          resolution = ResolutionPreset.low;
          break;
        case 1:
          resolution = ResolutionPreset.medium;
          break;
        case 2:
          resolution = ResolutionPreset.high;
          break;
        case 3:
          resolution = ResolutionPreset.veryHigh;
          break;
        case 4:
          resolution = ResolutionPreset.ultraHigh;
          break;
        case 5:
          resolution = ResolutionPreset.max;
          break;
        default:
          resolution = ResolutionPreset.medium;
      }
      
      // 确保摄像头索引有效
      int validCameraIndex = cameraIndex;
      if (cameraIndex >= cameras.length || cameraIndex < 0) {
        validCameraIndex = await _getDefaultCameraIndex(cameras);
        await prefs.setInt('selected_camera', validCameraIndex);
      }
      
      // 使用选择的摄像头
      _cameraController = CameraController(
        cameras[validCameraIndex],
        resolution,
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      
      await _cameraController!.initialize();
      _isCameraInitialized = true;
      
      print('摄像头初始化成功');
    } catch (e) {
      print('摄像头设置失败: $e');
      _isCameraInitialized = false;
      
      // 重试机制
      await Future.delayed(const Duration(seconds: 1));
      await _setupCamera(cameras);
    }
  }
  
  /// 获取默认摄像头索引
  /// 优先从设置中读取保存的摄像头索引，如果没有则选择后置摄像头
  Future<int> _getDefaultCameraIndex(List<CameraDescription> cameras) async {
    if (cameras.isEmpty) return 0;
    
    try {
      // 从 SharedPreferences 中读取保存的摄像头索引
      final prefs = await SharedPreferences.getInstance();
      final savedCameraIndex = prefs.getInt('selected_camera');
      
      // 如果有保存的索引且在有效范围内，直接使用
      if (savedCameraIndex != null && 
          savedCameraIndex >= 0 && 
          savedCameraIndex < cameras.length) {
        print('使用保存的摄像头索引: $savedCameraIndex');
        return savedCameraIndex;
      }
      
      print('未找到有效的保存摄像头索引，使用默认选择逻辑');
    } catch (e) {
      print('读取保存的摄像头索引失败: $e，使用默认选择逻辑');
    }
    
    // 如果没有保存的索引或读取失败，优先选择后置摄像头
    for (int i = 0; i < cameras.length; i++) {
      if (cameras[i].lensDirection == CameraLensDirection.back) {
        print('选择默认后置摄像头，索引: $i');
        return i;
      }
    }
    
    print('使用第一个可用摄像头，索引: 0');
    return 0;
  }
  
  /// 重新初始化摄像头
  Future<void> reinitializeCamera() async {
    if (_isRecording) {
      print('录制中无法重新初始化摄像头');
      return;
    }
    
    _isCameraInitialized = false;
    // 重新获取可用摄像头
    final cameras = await availableCameras();
    await _setupCamera(cameras);
  }
  
  /// 开始录制视频
  Future<void> startVideoRecording() async {
    if (_cameraController == null || !_isCameraInitialized) {
      _notifyMessage('摄像头未准备就绪');
      return;
    }
    
    if (_isRecording) {
      print('已在录制中');
      return;
    }
    
    try {
      // 确保摄像头状态正常
      if (!_cameraController!.value.isInitialized) {
        _notifyMessage('摄像头未初始化，正在重新初始化...');
        return;
      }
      
      // 重置分割索引
      _currentSegmentIndex = 0;
      
      // 生成基于当前时间的文件名
      final now = DateTime.now();
      final roundedMinute = DateTime(now.year, now.month, now.day, now.hour, now.minute);
      final formatter = DateFormat('yyyy_MM_dd_HH_mm');
      _customFileName = '${formatter.format(roundedMinute)}_${_currentSegmentIndex.toString().padLeft(3, '0')}.mp4';
      
      // 如果启用了视频分割，使用Platform Channel启动原生录制
      if (_enableVideoSegmentation && Platform.isAndroid) {
        _isUsingNativeRecording = await _startNativeVideoRecording();
      } else {
        // 使用Flutter Camera插件录制
        await _cameraController!.startVideoRecording();
        _isUsingNativeRecording = false;
      }
      
      _isRecording = true;
      _notifyRecordingState(true);
      _notifyMessage('开始录制视频...');
      
      // 启用屏幕常亮
      await WakelockPlus.enable();
      print('已启用屏幕常亮模式');
      
      // 启动视频分割定时器
      if (_enableVideoSegmentation && _isUsingNativeRecording) {
        _startSegmentTimer();
      }
      
      print('开始录制视频，文件名: $_customFileName');
      
    } catch (e) {
      print('开始录制失败: $e');
      await _handleRecordingError('开始录制失败: ${e.toString()}');
    }
  }
  
  /// 启动原生视频录制
  Future<bool> _startNativeVideoRecording() async {
    try {
      final directory = await _getVideoDirectory();
      final filePath = '${directory.path}/$_customFileName';
      
      await platform.invokeMethod('startRecording', {
        'filePath': filePath,
        'maxDurationMs': _segmentDurationMinutes * 60 * 1000,
      });
      
      print('原生录制已启动: $filePath');
      return true;
    } catch (e) {
      print('启动原生录制失败: $e');
      // 回退到Flutter Camera录制
      await _cameraController!.startVideoRecording();
      return false;
    }
  }
  
  /// 启动视频分割定时器
  void _startSegmentTimer() {
    _segmentTimer = Timer.periodic(
      Duration(minutes: _segmentDurationMinutes),
      (timer) async {
        if (_isRecording) {
          await _switchToNextSegment();
        }
      },
    );
  }
  
  /// 切换到下一个视频分割
  Future<void> _switchToNextSegment() async {
    try {
      _currentSegmentIndex++;
      
      // 生成新的文件名
      final now = DateTime.now();
      final roundedMinute = DateTime(now.year, now.month, now.day, now.hour, now.minute);
      final formatter = DateFormat('yyyy_MM_dd_HH_mm');
      final newFileName = '${formatter.format(roundedMinute)}_${_currentSegmentIndex.toString().padLeft(3, '0')}.mp4';
      
      final directory = await _getVideoDirectory();
      final newFilePath = '${directory.path}/$newFileName';
      
      // 调用原生方法切换到下一个文件
      await platform.invokeMethod('setNextOutputFile', {
        'filePath': newFilePath,
      });
      
      _customFileName = newFileName;
      print('已切换到下一个视频分割: $newFilePath');
      
    } catch (e) {
      print('切换视频分割失败: $e');
    }
  }
  
  /// 停止录制视频
  Future<void> stopVideoRecording() async {
    if (!_isRecording) {
      print('当前未在录制');
      return;
    }
    
    try {
      // 取消分割定时器
      _segmentTimer?.cancel();
      
      if (_isUsingNativeRecording) {
        // 停止原生录制
        await platform.invokeMethod('stopRecording');
      } else {
        // 停止Flutter Camera录制
        final video = await _cameraController!.stopVideoRecording();
        
        // 如果有自定义文件名，则重命名文件
        if (_customFileName != null) {
          try {
            final directory = await _getVideoDirectory();
            final newPath = '${directory.path}/$_customFileName';
            final originalFile = File(video.path);
            await originalFile.copy(newPath);
            await originalFile.delete();
            print('视频已保存为自定义文件名: $newPath');
          } catch (e) {
            print('重命名文件失败: $e，使用原文件名: ${video.path}');
          }
        }
      }
      
      _isUsingNativeRecording = false;
      _isRecording = false;
      _notifyRecordingState(false);
      _notifyMessage('录制已停止');
      
      // 禁用屏幕常亮
      await WakelockPlus.disable();
      print('已禁用屏幕常亮模式');
      
      // 恢复屏幕亮度
      await _restoreScreenBrightness();
      
      print('视频录制已停止');
      
      // 清除自定义文件名
      _customFileName = null;
      
    } catch (e) {
      print('停止录制失败: $e');
      await _handleRecordingError('停止录制失败: ${e.toString()}');
    }
  }
  
  /// 开始录制（公开方法）
  Future<void> startRecording() async {
    await startVideoRecording();
  }
  
  /// 停止录制（公开方法）
  Future<void> stopRecording() async {
    await stopVideoRecording();
  }
  
  /// 切换录制状态
  Future<void> toggleVideoRecording() async {
    if (_isRecording) {
      await stopVideoRecording();
    } else {
      await startVideoRecording();
    }
  }
  
  /// 调暗屏幕
  Future<void> dimScreen() async {
    try {
      if (!_isScreenDimmed) {
        _originalBrightness = await ScreenBrightness().current;
        await ScreenBrightness().setScreenBrightness(0.01);
        _isScreenDimmed = true;
        print('屏幕已调暗，原始亮度: $_originalBrightness');
      }
    } catch (e) {
      print('调暗屏幕失败: $e');
    }
  }
  
  /// 恢复屏幕亮度
  Future<void> _restoreScreenBrightness() async {
    try {
      if (_isScreenDimmed && _originalBrightness != null) {
        await ScreenBrightness().setScreenBrightness(_originalBrightness!);
        _isScreenDimmed = false;
        print('屏幕亮度已恢复: $_originalBrightness');
      }
    } catch (e) {
      print('恢复屏幕亮度失败: $e');
    }
  }
  
  /// 恢复屏幕亮度（公开方法）
  Future<void> restoreScreenBrightness() async {
    await _restoreScreenBrightness();
  }
  
  /// 处理录制错误
  Future<void> _handleRecordingError(String error) async {
    // 禁用屏幕常亮
    await WakelockPlus.disable();
    print('录制错误时已禁用屏幕常亮模式');
    
    // 恢复屏幕亮度
    await _restoreScreenBrightness();
    
    _isRecording = false;
    _notifyRecordingState(false);
    _notifyMessage('录制失败，正在重试...');
    
    print('录制错误: $error');
  }
  
  /// 获取VeloMemo专用视频存放目录
  Future<Directory> _getVideoDirectory() async {
    try {
      Directory baseDir;
      
      if (Platform.isAndroid) {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          final moviesDir = Directory('${externalDir.parent.parent.parent.parent.path}/Movies');
          if (await moviesDir.exists()) {
            baseDir = moviesDir;
          } else {
            final dcimDir = Directory('${externalDir.parent.parent.parent.parent.path}/DCIM');
            if (await dcimDir.exists()) {
              baseDir = dcimDir;
            } else {
              baseDir = await getApplicationDocumentsDirectory();
            }
          }
        } else {
          baseDir = await getApplicationDocumentsDirectory();
        }
      } else {
        baseDir = await getApplicationDocumentsDirectory();
      }
      
      final veloMemoDir = Directory('${baseDir.path}/VeloMemo');
      if (!await veloMemoDir.exists()) {
        await veloMemoDir.create(recursive: true);
        print('已创建VeloMemo视频目录: ${veloMemoDir.path}');
      }
      
      return veloMemoDir;
    } catch (e) {
      print('获取VeloMemo视频目录失败: $e，使用应用文档目录');
      final fallbackDir = await getApplicationDocumentsDirectory();
      final veloMemoDir = Directory('${fallbackDir.path}/VeloMemo');
      if (!await veloMemoDir.exists()) {
        await veloMemoDir.create(recursive: true);
      }
      return veloMemoDir;
    }
  }
  
  /// 添加录制状态监听器
  void addRecordingStateListener(Function(bool) listener) {
    _recordingStateListeners.add(listener);
  }
  
  /// 移除录制状态监听器
  void removeRecordingStateListener(Function(bool) listener) {
    _recordingStateListeners.remove(listener);
  }
  
  /// 添加录制消息监听器
  void addRecordingMessageListener(Function(String) listener) {
    _recordingMessageListeners.add(listener);
  }
  
  /// 移除录制消息监听器
  void removeRecordingMessageListener(Function(String) listener) {
    _recordingMessageListeners.remove(listener);
  }
  
  /// 通知录制状态变化
  void _notifyRecordingState(bool isRecording) {
    for (final listener in _recordingStateListeners) {
      try {
        listener(isRecording);
      } catch (e) {
        print('录制状态监听器回调失败: $e');
      }
    }
  }
  
  /// 通知录制消息
  void _notifyMessage(String message) {
    for (final listener in _recordingMessageListeners) {
      try {
        listener(message);
      } catch (e) {
        print('录制消息监听器回调失败: $e');
      }
    }
  }
  
  /// 释放资源
  Future<void> dispose() async {
    _segmentTimer?.cancel();
    
    // 如果正在录制，先停止录制
    if (_isRecording && _cameraController != null) {
      try {
        await stopVideoRecording();
      } catch (e) {
        print('停止录制时出错: $e');
      }
    }
    
    // 释放摄像头资源
    await _cameraController?.dispose();
    _cameraController = null;
    _isCameraInitialized = false;
    
    // 清空监听器
    _recordingStateListeners.clear();
    _recordingMessageListeners.clear();
    
    print('视频录制器已释放');
  }
  
  /// 获取录制统计信息
  Map<String, dynamic> getRecordingStats() {
    return {
      'isRecording': _isRecording,
      'isCameraInitialized': _isCameraInitialized,
      'isPermissionGranted': _isPermissionGranted,
      'currentFileName': _customFileName,
      'currentSegmentIndex': _currentSegmentIndex,
      'isUsingNativeRecording': _isUsingNativeRecording,
      'isScreenDimmed': _isScreenDimmed,
    };
  }
}