import 'package:flutter/material.dart';
import 'lib/video_recorder.dart';

/// 视频分割功能使用示例
/// 展示如何配置和使用视频分割功能
class VideoSegmentationExample {
  final VideoRecorder _videoRecorder = VideoRecorder.instance;
  
  /// 初始化视频分割功能
  /// 检查设备支持情况并配置分割参数
  Future<void> initializeVideoSegmentation() async {
    // 1. 检查设备是否支持视频分割功能
    final isSupported = await _videoRecorder.checkVideoSegmentationSupport();
    
    if (isSupported) {
      print('✅ 设备支持视频分割功能');
      
      // 2. 配置视频分割功能
      _videoRecorder.setVideoSegmentationEnabled(true);
      _videoRecorder.setSegmentDuration(2); // 设置为2分钟分割
      
      print('📹 视频分割功能已启用，分割时长：${_videoRecorder.segmentDurationMinutes}分钟');
    } else {
      print('❌ 设备不支持视频分割功能（需要Android 8.0+）');
      
      // 3. 禁用分割功能，使用普通录制
      _videoRecorder.setVideoSegmentationEnabled(false);
      
      print('📹 已切换到普通录制模式');
    }
  }
  
  /// 开始录制视频
  /// 根据设备支持情况自动选择录制模式
  Future<void> startRecording() async {
    try {
      // 添加消息监听器以接收录制状态更新
      _videoRecorder.addRecordingMessageListener(_onRecordingMessage);
      
      // 开始录制
      await _videoRecorder.startRecording();
      
      // 显示当前录制状态
      _printRecordingStatus();
      
    } catch (e) {
      print('❌ 录制启动失败: $e');
    }
  }
  
  /// 停止录制视频
  Future<void> stopRecording() async {
    try {
      await _videoRecorder.stopRecording();
      
      // 移除消息监听器
      _videoRecorder.removeRecordingMessageListener(_onRecordingMessage);
      
      print('⏹️ 录制已停止');
      
    } catch (e) {
      print('❌ 停止录制失败: $e');
    }
  }
  
  /// 动态调整分割设置
  /// 在录制过程中可以调整分割时长（下次录制生效）
  void adjustSegmentationSettings({
    bool? enabled,
    int? durationMinutes,
  }) {
    if (enabled != null) {
      _videoRecorder.setVideoSegmentationEnabled(enabled);
      print('🔧 视频分割功能已${enabled ? "启用" : "禁用"}');
    }
    
    if (durationMinutes != null && durationMinutes > 0) {
      _videoRecorder.setSegmentDuration(durationMinutes);
      print('🔧 分割时长已设置为${durationMinutes}分钟');
    }
  }
  
  /// 获取当前录制状态信息
  void _printRecordingStatus() {
    final stats = _videoRecorder.getRecordingStats();
    
    print('📊 录制状态信息:');
    print('   - 正在录制: ${stats['isRecording']}');
    print('   - 使用原生录制: ${stats['isUsingNativeRecording']}');
    print('   - 分割功能启用: ${stats['isVideoSegmentationEnabled']}');
    print('   - 分割功能支持: ${stats['isVideoSegmentationSupported']}');
    print('   - 当前分割索引: ${stats['currentSegmentIndex']}');
    print('   - 分割时长: ${stats['segmentDurationMinutes']}分钟');
    print('   - 当前文件名: ${stats['currentFileName'] ?? "未设置"}');
  }
  
  /// 录制消息回调
  /// 处理录制过程中的状态更新和错误信息
  void _onRecordingMessage(String message) {
    print('📢 录制消息: $message');
    
    // 根据消息内容进行相应处理
    if (message.contains('切换到第')) {
      print('🔄 视频分割成功');
    } else if (message.contains('分割切换失败')) {
      print('⚠️ 分割功能出现问题，但录制继续');
    } else if (message.contains('不支持视频分割')) {
      print('ℹ️ 已自动切换到普通录制模式');
    }
  }
  
  /// 检查并显示设备兼容性信息
  Future<void> checkDeviceCompatibility() async {
    print('🔍 检查设备兼容性...');
    
    final isSupported = await _videoRecorder.checkVideoSegmentationSupport();
    final stats = _videoRecorder.getRecordingStats();
    
    print('📱 设备信息:');
    print('   - 视频分割支持: ${isSupported ? "✅ 支持" : "❌ 不支持"}');
    print('   - 摄像头初始化: ${stats['isCameraInitialized'] ? "✅ 已初始化" : "❌ 未初始化"}');
    print('   - 权限状态: ${stats['isPermissionGranted'] ? "✅ 已授权" : "❌ 未授权"}');
    
    if (!isSupported) {
      print('💡 建议: 设备需要Android 8.0+才能使用视频分割功能');
    }
  }
}

/// 使用示例
void main() async {
  final example = VideoSegmentationExample();
  
  // 1. 检查设备兼容性
  await example.checkDeviceCompatibility();
  
  // 2. 初始化视频分割功能
  await example.initializeVideoSegmentation();
  
  // 3. 调整分割设置（可选）
  example.adjustSegmentationSettings(
    enabled: true,
    durationMinutes: 3, // 3分钟分割
  );
  
  // 4. 开始录制
  await example.startRecording();
  
  // 5. 模拟录制一段时间后停止
  await Future.delayed(Duration(seconds: 10));
  await example.stopRecording();
}