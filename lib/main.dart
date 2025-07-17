import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'file_list_page.dart';
import 'settings_page.dart';
import 'speed_calculator.dart';
import 'speed_display_widget.dart';

/// 全局摄像头列表
List<CameraDescription> cameras = [];

/// 应用程序入口点
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // 获取可用的摄像头列表
    cameras = await availableCameras();
    print('检测到 ${cameras.length} 个摄像头:');
    for (int i = 0; i < cameras.length; i++) {
      final camera = cameras[i];
      print('摄像头 $i: ${camera.name}, 方向: ${camera.lensDirection}, 传感器方向: ${camera.sensorOrientation}');
    }
  } catch (e) {
    print('获取摄像头失败: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: '行车记录仪'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isPermissionGranted = false;
  bool _isRecording = false; // 录制状态
  String _recordingMessage = '';
  String? _customFileName; // 存储自定义文件名
  bool _showUI = true; // 控制UI显示状态
  Timer? _uiHideTimer; // UI自动隐藏定时器
  
  // 录制动画相关
  late AnimationController _recordingAnimationController;
  late Animation<double> _recordingAnimation;
  
  // 录制时间相关
  Timer? _recordingTimer; // 录制时间更新定时器
  
  // 屏幕亮度控制相关
  Timer? _screenDimTimer; // 屏幕调暗定时器
  double? _originalBrightness; // 保存原始屏幕亮度
  bool _isScreenDimmed = false; // 屏幕是否已调暗
  
  // 存储空间和录制时长相关
  String _availableSpace = '计算中...';
  String _estimatedRecordingTime = '计算中...';
  Timer? _storageUpdateTimer; // 存储空间更新定时器
  
  // 视频分割相关变量
  Timer? _segmentTimer;
  bool _enableVideoSegmentation = true; // 是否启用视频分割
  int _segmentDurationMinutes = 1; // 分割时长（分钟）
  int _currentSegmentIndex = 0; // 当前分割索引
  bool _isUsingNativeRecording = false; // 是否正在使用原生录制
  
  // Platform Channel for native video segmentation
  static const platform = MethodChannel('com.example.velomemo/video_recorder');
  
  // 速度计算器
  SpeedCalculator? _speedCalculator;
  bool _isSpeedTrackingEnabled = false;

  @override
  void initState() {
    super.initState();
    
    // 初始化录制动画控制器
    _recordingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    // 创建闪烁动画
    _recordingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _recordingAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _initializeCamera();
    _startStorageMonitoring();
    _initializeSpeedCalculator();
  }

  @override
  void dispose() async {
    // 取消所有定时器
    _uiHideTimer?.cancel();
    _recordingTimer?.cancel();
    _screenDimTimer?.cancel();
    _storageUpdateTimer?.cancel();
    _segmentTimer?.cancel();
    
    // 停止速度跟踪
    _speedCalculator?.stop();
    
    // 禁用屏幕常亮，恢复正常锁屏行为
    await WakelockPlus.disable();
    print('应用退出时已禁用屏幕常亮模式');
    
    // 恢复屏幕亮度
    await _restoreScreenBrightness();
    
    // 释放动画控制器
    _recordingAnimationController.dispose();
    
    // 如果正在录制，先停止录制
    if (_isRecording && _cameraController != null) {
      try {
        await _cameraController!.stopVideoRecording();
      } catch (e) {
        print('停止录制时出错: $e');
      }
    }
    
    // 释放摄像头资源
    await _cameraController?.dispose();
    super.dispose();
  }

  /// 初始化摄像头
  Future<void> _initializeCamera() async {
    // 请求摄像头和录音权限
    final cameraStatus = await Permission.camera.request();
    final microphoneStatus = await Permission.microphone.request();
    final storageStatus = await Permission.storage.request();
    
    if (cameraStatus.isGranted && microphoneStatus.isGranted) {
      setState(() {
        _isPermissionGranted = true;
      });
      
      if (cameras.isNotEmpty) {
        await _setupCamera();
      }
    } else {
      print('权限被拒绝 - 摄像头: $cameraStatus, 麦克风: $microphoneStatus, 存储: $storageStatus');
    }
  }
  
  /// 初始化速度计算器
  Future<void> _initializeSpeedCalculator() async {
    try {
      _speedCalculator = SpeedCalculator.instance;
      final success = await _speedCalculator!.initialize();
      if (success) {
        print('速度计算器初始化成功');
      } else {
        print('速度计算器初始化失败');
      }
    } catch (e) {
      print('速度计算器初始化失败: $e');
    }
  }
  
  /// 保存当前屏幕亮度并调暗屏幕
  Future<void> _dimScreen() async {
    try {
      if (!_isScreenDimmed) {
        // 保存当前亮度
        _originalBrightness = await ScreenBrightness().current;
        // 将屏幕亮度设置为最低（但不完全关闭）
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

  /// 设置摄像头配置
  Future<void> _setupCamera() async {
    try {
      // 释放之前的摄像头资源
      await _cameraController?.dispose();
      
      // 从设置中加载分辨率和摄像头选择
      final prefs = await SharedPreferences.getInstance();
      final resolutionIndex = prefs.getInt('camera_resolution') ?? 1; // 默认为medium
      final cameraIndex = prefs.getInt('selected_camera') ?? _getDefaultCameraIndex();
      
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
        validCameraIndex = _getDefaultCameraIndex();
        // 保存正确的摄像头索引
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
      
      // 确保摄像头完全初始化后再更新状态
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      print('摄像头设置失败: $e');
      // 重试机制
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        await _setupCamera();
      }
    }
  }
  
  /// 获取默认摄像头索引（选择焦距最短的摄像头）
  int _getDefaultCameraIndex() {
    if (cameras.isEmpty) return 0;
    
    // 优先选择后置摄像头，因为通常后置摄像头有更好的录制效果
    for (int i = 0; i < cameras.length; i++) {
      if (cameras[i].lensDirection == CameraLensDirection.back) {
        return i;
      }
    }
    
    // 如果没有后置摄像头，返回第一个可用的摄像头
    return 0;
  }
  
  /// 重新初始化摄像头（当设置更改时调用）
  Future<void> reinitializeCamera() async {
    if (_isRecording) {
      // 如果正在录制，不允许切换摄像头
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('录制中无法切换摄像头'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    setState(() {
      _isCameraInitialized = false;
    });
    
    await _setupCamera();
    // 重新计算存储空间和录制时长
    await _updateStorageInfo();
  }
  
  /// 获取VeloMemo专用视频存放目录
  Future<Directory> _getVideoDirectory() async {
    try {
      Directory baseDir;
      
      // 在 Android 上，尝试获取外部存储的 Movies 目录
      if (Platform.isAndroid) {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          // 优先使用 Movies 目录
          final moviesDir = Directory('${externalDir.parent.parent.parent.parent.path}/Movies');
          if (await moviesDir.exists()) {
            baseDir = moviesDir;
          } else {
            // 如果 Movies 目录不存在，使用 DCIM 目录
            final dcimDir = Directory('${externalDir.parent.parent.parent.parent.path}/DCIM');
            if (await dcimDir.exists()) {
              baseDir = dcimDir;
            } else {
              // 最后备选方案：使用应用文档目录
              baseDir = await getApplicationDocumentsDirectory();
            }
          }
        } else {
          baseDir = await getApplicationDocumentsDirectory();
        }
      } else {
        // 使用应用文档目录
        baseDir = await getApplicationDocumentsDirectory();
      }
      
      // 在基础目录下创建 VeloMemo 子目录
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
  
  /// 启动存储空间监控
  void _startStorageMonitoring() {
    // 立即更新一次
    _updateStorageInfo();
    
    // 每30秒更新一次存储信息
    _storageUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _updateStorageInfo();
      }
    });
  }
  
  /// 更新存储空间信息
  Future<void> _updateStorageInfo() async {
    try {
      final directory = await _getVideoDirectory();
      final stat = await directory.stat();
      final freeSpace = await _getAvailableSpace(directory.path);
      
      final estimatedTime = await _calculateEstimatedRecordingTime(freeSpace);
      
      if (mounted) {
        setState(() {
          _availableSpace = _formatBytes(freeSpace);
          _estimatedRecordingTime = _formatDuration(estimatedTime);
        });
      }
    } catch (e) {
      print('更新存储信息失败: $e');
      if (mounted) {
        setState(() {
          _availableSpace = '未知';
          _estimatedRecordingTime = '未知';
        });
      }
    }
  }
  
  /// 获取可用存储空间（字节）
  Future<int> _getAvailableSpace(String path) async {
    try {
      // 使用df命令获取文件系统信息
      final result = await Process.run('df', ['-k', path]);
      if (result.exitCode == 0) {
        final lines = result.stdout.toString().split('\n');
        if (lines.length > 1) {
          final parts = lines[1].split(RegExp(r'\s+'));
          if (parts.length >= 4) {
            // df -k 返回的是KB，转换为字节
            final availableKB = int.tryParse(parts[3]) ?? 0;
            return availableKB * 1024;
          }
        }
      }
    } catch (e) {
      print('获取存储空间失败: $e');
    }
    
    // 如果无法获取准确信息，返回一个估算值
    return 1024 * 1024 * 1024; // 1GB 作为默认值
  }
  
  /// 计算预计录制时长（秒）
  Future<int> _calculateEstimatedRecordingTime(int availableBytes) async {
    try {
      // 获取当前录制分辨率设置
      final prefs = await SharedPreferences.getInstance();
      final resolutionIndex = prefs.getInt('camera_resolution') ?? 1;
      
      // 根据分辨率估算每秒视频文件大小（字节）
      int bytesPerSecond;
      switch (resolutionIndex) {
        case 0: // low (480p)
          bytesPerSecond = 1024 * 1024; // 1MB/s
          break;
        case 1: // medium (720p)
          bytesPerSecond = 2 * 1024 * 1024; // 2MB/s
          break;
        case 2: // high (1080p)
          bytesPerSecond = 4 * 1024 * 1024; // 4MB/s
          break;
        case 3: // veryHigh (1080p+)
          bytesPerSecond = 6 * 1024 * 1024; // 6MB/s
          break;
        case 4: // ultraHigh (4K)
          bytesPerSecond = 12 * 1024 * 1024; // 12MB/s
          break;
        case 5: // max
          bytesPerSecond = 20 * 1024 * 1024; // 20MB/s
          break;
        default:
          bytesPerSecond = 2 * 1024 * 1024; // 默认2MB/s
      }
      
      // 预留10%的空间作为缓冲
      final usableBytes = (availableBytes * 0.9).round();
      
      return max(0, usableBytes ~/ bytesPerSecond);
    } catch (e) {
      print('计算录制时长失败: $e');
      return 0;
    }
  }
  
  /// 格式化字节数为可读格式
  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '${bytes}B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)}KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
    }
  }
  
  /// 格式化时长为可读格式
  String _formatDuration(int seconds) {
    if (seconds < 60) {
      return '${seconds}秒';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;
      return '${minutes}分${remainingSeconds}秒';
    } else {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      return '${hours}小时${minutes}分钟';
    }
  }



  /// 更新系统UI显示状态
  void _updateSystemUI() {
    if (_showUI) {
      // 显示系统状态栏和导航栏
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
      );
    } else {
      // 隐藏系统状态栏和导航栏，实现全屏沉浸式体验
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.immersiveSticky,
      );
    }
  }

  /// 构建存储空间信息显示组件
  Widget _buildStorageInfo() {
    return Positioned(
      top: 60,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.storage,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  '剩余空间: $_availableSpace',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  '预计录制: $_estimatedRecordingTime',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建摄像头预览组件
  Widget _buildCameraPreview() {
    if (!_isPermissionGranted) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Text(
            '需要摄像头权限',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }
    
    if (!_isCameraInitialized || _cameraController == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }
    
    return AnimatedBuilder(
      animation: _recordingAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            // 摄像头预览
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _cameraController!.value.previewSize?.height ?? 0,
                  height: _cameraController!.value.previewSize?.width ?? 0,
                  child: CameraPreview(_cameraController!),
                ),
              ),
            ),
            // 红色边框覆盖层 - 录制指示灯（即使屏幕调暗也保持可见）
            if (_isRecording)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.red.withValues(alpha: _recordingAnimation.value),
                      width: _isScreenDimmed ? 12 : 8, // 屏幕调暗时边框更粗，更明显
                    ),
                  ),
                ),
              ),
            // 录制时间水印
            if (_isRecording)
              Positioned(
                top: 50,
                right: 20,
                child: Text(
                  _formatCurrentDateTime(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    shadows: [
                      Shadow(
                        offset: Offset(1, 1),
                        blurRadius: 2,
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// 构建文件列表按钮
  Widget _buildFileListButton() {
    return Container(
      width: 60,
      height: 60,
      decoration: const BoxDecoration(
        color: Color(0xFF333333),
        shape: BoxShape.circle,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: _showFileList,
          child: const Center(
            child: Icon(
              Icons.folder,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  /// 构建录制按钮
  Widget _buildCircularButton() {
    return AnimatedBuilder(
      animation: _recordingAnimation,
      builder: (context, child) {
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: _isRecording ? Colors.red : const Color(0xFF8B0000), // 录制时变为亮红色
            border: _isRecording ? Border.all(
              color: Colors.red.withValues(alpha: _recordingAnimation.value),
              width: 3,
            ) : null,
            shape: BoxShape.circle,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(40),
              onTap: () {
                // 按钮点击事件处理 - 录制视频功能
                _toggleVideoRecording();
              },
              child: Center(
                child: Icon(
                  _isRecording ? Icons.stop : Icons.videocam, // 录制时显示停止图标
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建设置按钮
  Widget _buildSettingsButton() {
    return Container(
      width: 60,
      height: 60,
      decoration: const BoxDecoration(
        color: Color(0xFF333333),
        shape: BoxShape.circle,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: _showSettings,
          child: const Center(
            child: Icon(
              Icons.settings,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  /// 处理屏幕点击事件
  void _handleScreenTap() {
    // 取消之前的定时器
    _uiHideTimer?.cancel();
    
    // 如果屏幕被调暗，恢复亮度
    if (_isScreenDimmed) {
      _restoreScreenBrightness();
    }
    
    setState(() {
      _showUI = !_showUI; // 切换UI显示状态
    });
    
    // 根据UI显示状态控制系统状态栏
    _updateSystemUI();
    
    // 如果正在录制且UI现在是显示状态，启动3秒后自动隐藏的定时器
    if (_isRecording && _showUI) {
      _uiHideTimer = Timer(const Duration(seconds: 3), () {
        if (mounted && _isRecording) {
          setState(() {
            _showUI = false;
          });
          _updateSystemUI();
          
          // 如果录制时间超过10秒，重新调暗屏幕
          if (!_isScreenDimmed) {
            _dimScreen();
          }
        }
      });
    }
  }

  /// 切换录制视频状态
  Future<void> _toggleVideoRecording() async {
    if (_cameraController == null || !_isCameraInitialized) {
      await _showErrorMessage('摄像头未准备就绪');
      return;
    }

    try {
      if (_isRecording) {
        await _stopVideoRecording();
      } else {
        await _startVideoRecording();
      }
    } catch (e) {
      print('录制操作失败: $e');
      await _handleRecordingError(e.toString());
    }
  }
  
  /// 开始录制视频
  Future<void> _startVideoRecording() async {
    try {
      // 确保摄像头状态正常
      if (!_cameraController!.value.isInitialized) {
        await _setupCamera();
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      // 重置分割索引
      _currentSegmentIndex = 0;
      
      // 生成基于当前时间的文件名（整点分钟）
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
      
      setState(() {
        _isRecording = true;
        _recordingMessage = '开始录制视频...';
      });
      
      // 启用屏幕常亮，防止锁屏
      await WakelockPlus.enable();
      print('已启用屏幕常亮模式');
      
      // 启动录制动画
      _recordingAnimationController.repeat(reverse: true);
      
      // 启动速度跟踪（速度计算器在初始化时已自动启动）
      if (_speedCalculator != null) {
        setState(() {
          _isSpeedTrackingEnabled = true;
        });
        print('速度跟踪已启动');
      }
      
      // 启动录制时间定时器
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_isRecording && mounted) {
          setState(() {
            // 触发UI更新以显示最新时间
          });
          // 每10秒更新一次存储信息（录制时）
          if (timer.tick % 10 == 0) {
            _updateStorageInfo();
          }
        }
      });
      
      // 只有在原生录制成功启动时才启动视频分割定时器
      if (_enableVideoSegmentation && _isUsingNativeRecording) {
        _startSegmentTimer();
      }
      

      
      print('开始录制视频，文件名: $_customFileName');
      
      // 3秒后清除录制开始提示信息并隐藏UI
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _isRecording) {
          setState(() {
            _recordingMessage = '';
            _showUI = false; // 隐藏UI元素
          });
          _updateSystemUI();
        }
      });
      
      // 10秒后调暗屏幕但继续录制
      _screenDimTimer = Timer(const Duration(seconds: 10), () {
        if (mounted && _isRecording) {
          _dimScreen();
          setState(() {
            _recordingMessage = '录制中 - 屏幕已调暗';
          });
          
          // 显示3秒提示信息后清除
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted && _isRecording) {
              setState(() {
                _recordingMessage = '';
              });
            }
          });
        }
      });
    } catch (e) {
      print('开始录制失败: $e');
      await _handleRecordingError('开始录制失败: ${e.toString()}');
    }
  }
  
  /// 启动原生视频录制（支持分割）
  Future<bool> _startNativeVideoRecording() async {
    try {
      final directory = await _getVideoDirectory();
      final filePath = '${directory.path}/$_customFileName';
      
      await platform.invokeMethod('startRecording', {
        'filePath': filePath,
        'maxDurationMs': _segmentDurationMinutes * 60 * 1000, // 转换为毫秒
      });
      
      print('原生录制已启动: $filePath');
      return true; // 原生录制启动成功
    } catch (e) {
      print('启动原生录制失败: $e');
      // 回退到Flutter Camera录制
      await _cameraController!.startVideoRecording();
      return false; // 原生录制启动失败，使用Flutter Camera
    }
  }
  
  /// 启动视频分割定时器
  void _startSegmentTimer() {
    _segmentTimer = Timer.periodic(
      Duration(minutes: _segmentDurationMinutes),
      (timer) async {
        if (_isRecording && mounted) {
          await _switchToNextSegment();
        }
      },
    );
  }
  
  /// 切换到下一个视频分割
  Future<void> _switchToNextSegment() async {
    try {
      _currentSegmentIndex++;
      
      // 生成新的文件名（基于当前整点分钟）
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
  Future<void> _stopVideoRecording() async {
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
            final newFile = await originalFile.copy(newPath);
            await originalFile.delete(); // 删除原文件
            print('视频已保存为自定义文件名: $newPath');
          } catch (e) {
            print('重命名文件失败: $e，使用原文件名: ${video.path}');
          }
        }
      }
      
      // 重置录制方式状态
      _isUsingNativeRecording = false;
      
      _uiHideTimer?.cancel(); // 停止录制时取消定时器
      _screenDimTimer?.cancel(); // 取消屏幕调暗定时器
      
      // 恢复屏幕亮度
      await _restoreScreenBrightness();
      
      // 停止速度跟踪
      if (_speedCalculator != null && _isSpeedTrackingEnabled) {
        _speedCalculator!.stop();
        setState(() {
          _isSpeedTrackingEnabled = false;
        });
        print('速度跟踪已停止');
      }
      
      setState(() {
        _isRecording = false;
        _recordingMessage = '录制已停止';
        _showUI = true; // 停止录制时重新显示UI
      });
      
      // 禁用屏幕常亮，恢复正常锁屏行为
      await WakelockPlus.disable();
      print('已禁用屏幕常亮模式');
      
      // 停止录制动画和定时器
      _recordingAnimationController.stop();
      _recordingAnimationController.reset();
      _recordingTimer?.cancel();
      
      // 停止录制时显示系统UI
      _updateSystemUI();
      
      print('视频录制已停止');
      
      // 清除自定义文件名
      _customFileName = null;
      
      // 更新存储信息
      _updateStorageInfo();
      
      // 3秒后清除提示信息
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _recordingMessage = '';
          });
        }
      });
    } catch (e) {
      print('停止录制失败: $e');
      await _handleRecordingError('停止录制失败: ${e.toString()}');
    }
  }
  
  /// 处理录制错误
  Future<void> _handleRecordingError(String error) async {
    _uiHideTimer?.cancel();
    _screenDimTimer?.cancel(); // 取消屏幕调暗定时器
    
    // 禁用屏幕常亮，恢复正常锁屏行为
    await WakelockPlus.disable();
    print('录制错误时已禁用屏幕常亮模式');
    
    // 恢复屏幕亮度
    await _restoreScreenBrightness();
    
    setState(() {
      _isRecording = false;
      _recordingMessage = '录制失败，正在重试...';
      _showUI = true;
    });
    
    // 停止录制动画和定时器
    _recordingAnimationController.stop();
    _recordingAnimationController.reset();
    _recordingTimer?.cancel();
    
    // 错误时显示系统UI
    _updateSystemUI();
    
    // 尝试重新初始化摄像头
    await Future.delayed(const Duration(seconds: 1));
    await _setupCamera();
    
    setState(() {
      _recordingMessage = '摄像头已重置，请重试';
    });
    
    // 3秒后清除错误信息
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _recordingMessage = '';
        });
      }
    });
  }
  
  /// 显示错误信息
  Future<void> _showErrorMessage(String message) async {
    setState(() {
      _recordingMessage = message;
      _showUI = true;
    });
    
    // 显示错误信息时显示系统UI
    _updateSystemUI();
    
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _recordingMessage = '';
        });
      }
    });
  }
  
  /// 格式化当前日期时间
  String _formatCurrentDateTime() {
    final now = DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    return formatter.format(now);
  }
  
  /// 显示文件列表
  void _showFileList() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const FileListPage(),
      ),
    );
  }
  
  /// 显示设置页面
  void _showSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsPage(),
      ),
    );
    
    // 从设置页面返回后，重新初始化摄像头以应用新设置
    await reinitializeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: _showUI ? AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
        ) : null,
        body: GestureDetector(
          onTap: _handleScreenTap,
          child: Stack(
            children: [
              // 摄像头预览作为背景
              _buildCameraPreview(),
              
              // 存储空间和录制时长信息
              if (_showUI)
                _buildStorageInfo(),

              // 速度显示组件（录制时显示）
              if (_isRecording && _isSpeedTrackingEnabled)
                Positioned(
                  top: 140,
                  right: 20,
                  child: SpeedDisplayWidget(
                    showDetailedInfo: false,
                    backgroundColor: Colors.black.withValues(alpha: 0.7),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),

              // 半透明遮罩层，使前景内容更清晰
              if (_showUI)
                Container(
                  color: Colors.black.withValues(alpha: 0.3),
                ),
              // 录制状态提示信息
              if (_recordingMessage.isNotEmpty && _showUI)
                Positioned(
                  top: 160,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                         if (_recordingMessage == '开始录制视频...') ...[
                           const Icon(Icons.fiber_manual_record, color: Colors.white, size: 20),
                           const SizedBox(width: 8),
                         ],
                        Text(
                          _recordingMessage,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

              // 在屏幕下方放置三个按钮：文件列表、录制、设置
              if (_showUI)
                Positioned(
                  bottom: 50,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildFileListButton(),
                      _buildCircularButton(),
                      _buildSettingsButton(),
                    ],
                  ),
                ),
            ],
          ),
        ),

    );
  }
}
