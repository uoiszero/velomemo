import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wakelock_plus/wakelock_plus.dart';
import 'file_list_page.dart';
import 'settings_page.dart';
import 'speed_calculator.dart';
import 'speed_display_widget.dart';
import 'video_recorder.dart';
import 'utils.dart';


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

/// 自定义圆角边框绘制器
/// 用于绘制具有内侧圆角的录制指示边框
class RoundedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double borderRadius;

  /// 构造函数
  /// [color] 边框颜色
  /// [strokeWidth] 边框宽度
  /// [borderRadius] 圆角半径
  RoundedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    // 创建圆角矩形路径，四边向内收缩12像素
    const inset = 12.0; // 内收缩像素
    final rect = Rect.fromLTWH(
      strokeWidth / 2 + inset,
      strokeWidth / 2 + inset,
      size.width - strokeWidth - (inset * 2),
      size.height - strokeWidth - (inset * 2),
    );

    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(borderRadius),
    );

    // 绘制圆角边框
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is RoundedBorderPainter) {
      return oldDelegate.color != color ||
          oldDelegate.strokeWidth != strokeWidth ||
          oldDelegate.borderRadius != borderRadius;
    }
    return true;
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
  // 视频录制器
  late VideoRecorder _videoRecorder;
  
  // UI控制相关
  bool _showUI = true; // 控制UI显示状态
  Timer? _uiHideTimer; // UI自动隐藏定时器
  Timer? _screenDimTimer; // 屏幕调暗定时器
  
  // 录制状态
  bool _isRecording = false;
  String _recordingMessage = '';
  
  // 录制动画相关
  late AnimationController _recordingAnimationController;
  late Animation<double> _recordingAnimation;
  
  // 录制时间相关
  Timer? _recordingTimer; // 录制时间更新定时器
  
  // 存储空间和录制时长相关
  String _availableSpace = '计算中...';
  String _estimatedRecordingTime = '计算中...';
  Timer? _storageUpdateTimer; // 存储空间更新定时器
  
  // 速度计算器
  SpeedCalculator? _speedCalculator;
  bool _isSpeedTrackingEnabled = false;

  @override
  void initState() {
    super.initState();
    
    // 初始化视频录制器
    _videoRecorder = VideoRecorder.instance;
    
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
    _setupVideoRecorderListeners();
  }

  @override
  void dispose() async {
    // 取消所有定时器
    _uiHideTimer?.cancel();
    _recordingTimer?.cancel();
    _screenDimTimer?.cancel();
    _storageUpdateTimer?.cancel();
    
    // 停止速度跟踪
    _speedCalculator?.stop();
    
    // 禁用屏幕常亮，恢复正常锁屏行为
    await WakelockPlus.disable();
    print('应用退出时已禁用屏幕常亮模式');
    
    // 释放动画控制器
    _recordingAnimationController.dispose();
    
    // 释放视频录制器资源
    await _videoRecorder.dispose();
    
    super.dispose();
  }

  /// 初始化摄像头
  Future<void> _initializeCamera() async {
    // 请求摄像头和录音权限
    final cameraStatus = await Permission.camera.request();
    final microphoneStatus = await Permission.microphone.request();
    final storageStatus = await Permission.storage.request();
    
    if (cameraStatus.isGranted && microphoneStatus.isGranted) {
      _videoRecorder.setPermissionGranted(true);
      
      if (cameras.isNotEmpty) {
        await _videoRecorder.initializeCamera(cameras);
        
        // 检查视频分割功能支持状态
        await _videoRecorder.checkVideoSegmentationSupport();
        
        // 触发UI更新以显示最新状态
        if (mounted) {
          setState(() {});
        }
      }
    } else {
      print('权限被拒绝 - 摄像头: $cameraStatus, 麦克风: $microphoneStatus, 存储: $storageStatus');
      _videoRecorder.setPermissionGranted(false);
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
  
  /// 设置视频录制器监听器
  void _setupVideoRecorderListeners() {
    // 监听录制状态变化
    _videoRecorder.addRecordingStateListener((isRecording) {
      if (mounted) {
        setState(() {
          _isRecording = isRecording;
        });
        
        if (isRecording) {
          // 开始录制时启动动画和定时器
          _recordingAnimationController.repeat(reverse: true);
          _startRecordingTimer();
          _startUIHideTimer();
          _startScreenDimTimer();
          
          // 启动速度跟踪
          if (_speedCalculator != null) {
            setState(() {
              _isSpeedTrackingEnabled = true;
            });
            print('速度跟踪已启动');
          }
        } else {
          // 停止录制时停止动画和定时器
          _recordingAnimationController.stop();
          _recordingAnimationController.reset();
          _recordingTimer?.cancel();
          _uiHideTimer?.cancel();
          _screenDimTimer?.cancel();
          
          // 停止速度跟踪
          if (_speedCalculator != null && _isSpeedTrackingEnabled) {
            _speedCalculator!.stop();
            setState(() {
              _isSpeedTrackingEnabled = false;
            });
            print('速度跟踪已停止');
          }
          
          // 恢复屏幕亮度
          _videoRecorder.restoreScreenBrightness();
          
          // 显示UI
          setState(() {
            _showUI = true;
          });
          _updateSystemUI();
          
          // 更新存储信息
          _updateStorageInfo();
        }
      }
    });
    
    // 监听录制消息变化
    _videoRecorder.addRecordingMessageListener((message) {
      if (mounted) {
        setState(() {
          _recordingMessage = message;
        });
        
        // 3秒后清除消息
        if (message.isNotEmpty) {
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _recordingMessage = '';
              });
            }
          });
        }
      }
    });
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
    
    // 重新初始化VideoRecorder
    await _videoRecorder.reinitializeCamera();
    
    // 检查视频分割功能支持状态
    await _videoRecorder.checkVideoSegmentationSupport();
    
    // 重新计算存储空间和录制时长
    await _updateStorageInfo();
    
    // 触发UI更新以显示最新状态
    if (mounted) {
      setState(() {});
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
      final directory = await getVideoDirectory();
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
            const SizedBox(height: 6),
            _buildVideoSegmentationStatus(),
          ],
        ),
      ),
    );
  }

  /// 构建视频分割状态显示组件
  Widget _buildVideoSegmentationStatus() {
    // 获取视频分割状态信息
    final isEnabled = _videoRecorder.isVideoSegmentationEnabled;
    final isSupported = _videoRecorder.isVideoSegmentationSupported;
    final segmentDuration = _videoRecorder.segmentDurationMinutes;
    
    // 确定状态文本和颜色
    String statusText;
    Color statusColor;
    IconData statusIcon;
    
    if (!isSupported) {
      statusText = '视频分割: 设备不支持';
      statusColor = Colors.orange;
      statusIcon = Icons.warning;
    } else if (isEnabled) {
      statusText = '视频分割: 已启用 (${segmentDuration}分钟)';
      statusColor = Colors.green;
      statusIcon = Icons.video_library;
    } else {
      statusText = '视频分割: 已禁用';
      statusColor = Colors.grey;
      statusIcon = Icons.video_library_outlined;
    }
    
    return Row(
      children: [
        Icon(
          statusIcon,
          color: statusColor,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          statusText,
          style: TextStyle(
            color: statusColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// 构建摄像头预览组件
  Widget _buildCameraPreview() {
    if (!_videoRecorder.isPermissionGranted) {
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
    
    if (!_videoRecorder.isCameraInitialized) {
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
                  width: _videoRecorder.cameraController?.value.previewSize?.height ?? 0,
                  height: _videoRecorder.cameraController?.value.previewSize?.width ?? 0,
                  child: CameraPreview(_videoRecorder.cameraController!),
                ),
              ),
            ),

            // 红色边框覆盖层 - 录制指示灯（即使屏幕调暗也保持可见）
            if (_isRecording)
              Positioned.fill(
                child: CustomPaint(
                  painter: RoundedBorderPainter(
                    color: Colors.red.withValues(alpha: _recordingAnimation.value),
                    strokeWidth: _videoRecorder.isScreenDimmed ? 12 : 8,
                    borderRadius: 24.0, // 内侧圆角半径
                  ),
                ),
              ),
            // 录制时间水印
            if (_isRecording)
              Positioned(
                top: 62,
                right: 32,
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
    _videoRecorder.restoreScreenBrightness();
    
    setState(() {
      _showUI = !_showUI; // 切换UI显示状态
    });
    
    // 根据UI显示状态控制系统状态栏
    _updateSystemUI();
    
    // 如果正在录制且UI现在是显示状态，启动3秒后自动隐藏的定时器
    if (_isRecording && _showUI) {
      _startUIHideTimer();
    }
  }

  /// 切换录制视频状态
  Future<void> _toggleVideoRecording() async {
    if (!_videoRecorder.isCameraInitialized) {
      await _showErrorMessage('摄像头未准备就绪');
      return;
    }

    try {
      if (_isRecording) {
        await _videoRecorder.stopRecording();
      } else {
        await _videoRecorder.startRecording();
      }
    } catch (e) {
      print('录制操作失败: $e');
      await _showErrorMessage('录制操作失败: ${e.toString()}');
    }
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
  
  /// 启动UI隐藏定时器
  void _startUIHideTimer() {
    _uiHideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isRecording) {
        setState(() {
          _showUI = false;
        });
        _updateSystemUI();
        
        // 如果录制时间超过10秒，重新调暗屏幕
        _videoRecorder.dimScreen();
      }
    });
  }
  
  /// 启动录制定时器
  void _startRecordingTimer() {
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
  }
  
  /// 启动屏幕调暗定时器
  void _startScreenDimTimer() {
    _screenDimTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && _isRecording) {
        _videoRecorder.dimScreen();
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
                  top: 152,
                  right: 32,
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
