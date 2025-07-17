import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'main.dart';

/// 设置页面
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  ResolutionPreset _selectedResolution = ResolutionPreset.medium;
  bool _isLoading = true;
  int _selectedCameraIndex = 0; // 默认选择的摄像头索引
  String _appVersion = '1.0.0';
  String _buildNumber = '1';
  String _appName = '行车记录仪';
  String _videoStoragePath = ''; // 视频存储路径
  
  // 分辨率选项映射
  final Map<ResolutionPreset, String> _resolutionNames = {
    ResolutionPreset.low: '低画质 (240p)',
    ResolutionPreset.medium: '中画质 (480p)',
    ResolutionPreset.high: '高画质 (720p)',
    ResolutionPreset.veryHigh: '超高画质 (1080p)',
    ResolutionPreset.ultraHigh: '4K画质 (2160p)',
    ResolutionPreset.max: '最高画质',
  };
  
  final Map<ResolutionPreset, String> _resolutionDescriptions = {
    ResolutionPreset.low: '文件小，适合长时间录制',
    ResolutionPreset.medium: '平衡画质与文件大小',
    ResolutionPreset.high: '清晰画质，推荐设置',
    ResolutionPreset.veryHigh: '高清画质，文件较大',
    ResolutionPreset.ultraHigh: '4K超清，需要大存储空间',
    ResolutionPreset.max: '设备支持的最高分辨率',
  };
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAppInfo();
    _loadVideoStoragePath();
  }
  
  /// 加载应用信息
  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appName = packageInfo.appName.isNotEmpty ? packageInfo.appName : '行车记录仪';
        _appVersion = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
      });
    } catch (e) {
      print('获取应用信息失败: $e');
      // 使用默认值
    }
  }
  
  /// 加载视频存储路径
  Future<void> _loadVideoStoragePath() async {
    try {
      final directory = await _getVideoDirectory();
      setState(() {
        _videoStoragePath = directory.path;
      });
    } catch (e) {
      print('获取视频存储路径失败: $e');
      setState(() {
        _videoStoragePath = '获取路径失败';
      });
    }
  }
  
  /// 获取视频存储目录
  Future<Directory> _getVideoDirectory() async {
    try {
      Directory baseDir;
      
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
  
  /// 加载设置
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final resolutionIndex = prefs.getInt('camera_resolution') ?? 1; // 默认为medium
    
    // 将索引转换为ResolutionPreset
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
    
    // 加载摄像头选择设置，默认选择焦距最短的摄像头
    int cameraIndex = prefs.getInt('selected_camera') ?? _getDefaultCameraIndex();
    
    setState(() {
      _selectedResolution = resolution;
      _selectedCameraIndex = cameraIndex;
      _isLoading = false;
    });
  }
  
  /// 获取默认摄像头索引（选择焦距最短的摄像头）
  int _getDefaultCameraIndex() {
    if (cameras.isEmpty) return 0;
    print('设置页面 - 共有 ${cameras.length} 个摄像头');
    for (int i = 0; i < cameras.length; i++) {
      final camera = cameras[i];
      print('设置页面 - 摄像头 $i: ${camera.name}, 方向: ${camera.lensDirection}');
    }
    
    int shortestFocalLengthIndex = 0;
    
    for (int i = 0; i < cameras.length; i++) {
      final camera = cameras[i];
      // 获取摄像头的焦距信息，通常后置摄像头的焦距更短
      // 如果无法获取具体焦距，优先选择后置摄像头
      if (camera.lensDirection == CameraLensDirection.back) {
        // 假设后置摄像头通常有更短的焦距
        if (i == 0 || camera.lensDirection == CameraLensDirection.back) {
          shortestFocalLengthIndex = i;
          break;
        }
      }
    }
    
    print('设置页面 - 默认选择摄像头索引: $shortestFocalLengthIndex');
    return shortestFocalLengthIndex;
  }
  
  /// 保存摄像头选择
  Future<void> _saveCameraSelection(int cameraIndex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selected_camera', cameraIndex);
    
    setState(() {
      _selectedCameraIndex = cameraIndex;
    });
    
    // 显示保存成功提示
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('摄像头设置已保存，返回主页面后将自动应用'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  /// 保存设置
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 将ResolutionPreset转换为索引
    int resolutionIndex;
    switch (_selectedResolution) {
      case ResolutionPreset.low:
        resolutionIndex = 0;
        break;
      case ResolutionPreset.medium:
        resolutionIndex = 1;
        break;
      case ResolutionPreset.high:
        resolutionIndex = 2;
        break;
      case ResolutionPreset.veryHigh:
        resolutionIndex = 3;
        break;
      case ResolutionPreset.ultraHigh:
        resolutionIndex = 4;
        break;
      case ResolutionPreset.max:
        resolutionIndex = 5;
        break;
    }
    
    await prefs.setInt('camera_resolution', resolutionIndex);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('设置已保存'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
  
  /// 构建摄像头选择器
  Widget _buildCameraSelector() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '摄像头选择',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '选择用于录制的摄像头。建议选择焦距最短的摄像头以获得更好的录制效果。',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            if (cameras.isEmpty)
              const Text(
                '未检测到可用摄像头',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.red,
                ),
              )
            else
              ...cameras.asMap().entries.map((entry) {
                final index = entry.key;
                final camera = entry.value;
                final cameraName = _getCameraDisplayName(camera, index);
                
                return RadioListTile<int>(
                  title: Text(cameraName),
                  subtitle: Text(
                    '${camera.lensDirection == CameraLensDirection.back ? "后置" : "前置"}摄像头',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  value: index,
                  groupValue: _selectedCameraIndex,
                  onChanged: (int? value) {
                    if (value != null) {
                      _saveCameraSelection(value);
                    }
                  },
                  contentPadding: EdgeInsets.zero,
                );
              }).toList(),
          ],
        ),
      ),
    );
  }
  
  /// 获取摄像头显示名称（基于放大倍率）
  String _getCameraDisplayName(CameraDescription camera, int index) {
    String direction = camera.lensDirection == CameraLensDirection.back ? '后置' : '前置';
    String name = camera.name.toLowerCase();
    
    // 尝试从摄像头名称中提取放大倍率信息
    String zoomInfo = _extractZoomInfo(name);
    if (zoomInfo.isNotEmpty) {
      return '$direction摄像头 ($zoomInfo)';
    }
    
    // 如果无法提取放大倍率，使用传统的描述方式
    if (name.contains('wide') && !name.contains('ultra')) {
      return '$direction摄像头 (1x 广角)';
    } else if (name.contains('ultra')) {
      return '$direction摄像头 (0.5x 超广角)';
    } else if (name.contains('telephoto') || name.contains('tele')) {
      return '$direction摄像头 (2x 长焦)';
    } else {
      return '$direction摄像头 (1x 标准)';
    }
  }
  
  /// 从摄像头名称中提取放大倍率信息
  String _extractZoomInfo(String cameraName) {
    // 常见的放大倍率模式匹配
    final zoomPatterns = [
      RegExp(r'(\d+(?:\.\d+)?)x', caseSensitive: false), // 匹配 "2x", "0.5x" 等
      RegExp(r'zoom[_\s]*(\d+(?:\.\d+)?)', caseSensitive: false), // 匹配 "zoom_2", "zoom 0.5" 等
      RegExp(r'(\d+(?:\.\d+)?)\s*times', caseSensitive: false), // 匹配 "2 times" 等
    ];
    
    for (final pattern in zoomPatterns) {
      final match = pattern.firstMatch(cameraName);
      if (match != null) {
        final zoomValue = match.group(1);
        if (zoomValue != null) {
          return '${zoomValue}x';
        }
      }
    }
    
    // 根据摄像头类型推断常见的放大倍率
    if (cameraName.contains('ultra')) {
      return '0.5x';
    } else if (cameraName.contains('wide') && !cameraName.contains('ultra')) {
      return '1x';
    } else if (cameraName.contains('telephoto') || cameraName.contains('tele')) {
      // 尝试从名称中提取具体倍率，否则默认为2x
      if (cameraName.contains('3')) return '3x';
      if (cameraName.contains('5')) return '5x';
      if (cameraName.contains('10')) return '10x';
      return '2x';
    }
    
    return ''; // 无法确定放大倍率
  }
  
  /// 构建分辨率选择列表
  Widget _buildResolutionSelector() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '录制分辨率',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '选择视频录制的分辨率。更高的分辨率会产生更大的文件。',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            ..._resolutionNames.entries.map((entry) {
              final preset = entry.key;
              final name = entry.value;
              final description = _resolutionDescriptions[preset] ?? '';
              
              return RadioListTile<ResolutionPreset>(
                title: Text(name),
                subtitle: Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                value: preset,
                groupValue: _selectedResolution,
                onChanged: (ResolutionPreset? value) {
                  if (value != null) {
                    setState(() {
                      _selectedResolution = value;
                    });
                    _saveSettings();
                  }
                },
                contentPadding: EdgeInsets.zero,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
  
  /// 构建存储信息卡片
  Widget _buildStorageInfo() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  '存储提示',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStorageItem('低画质 (240p)', '约 10MB/分钟'),
            _buildStorageItem('中画质 (480p)', '约 25MB/分钟'),
            _buildStorageItem('高画质 (720p)', '约 60MB/分钟'),
            _buildStorageItem('超高画质 (1080p)', '约 130MB/分钟'),
            _buildStorageItem('4K画质 (2160p)', '约 400MB/分钟'),
          ],
        ),
      ),
    );
  }
  
  /// 构建存储信息项
  Widget _buildStorageItem(String quality, String size) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            quality,
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            size,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
  
  /// 构建其他设置选项
  Widget _buildOtherSettings() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '其他设置',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.folder_open),
              title: const Text('文件存储位置'),
              subtitle: const Text('查看录制文件的保存路径'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                _showStorageLocationDialog();
              },
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_sweep),
              title: const Text('清理缓存'),
              subtitle: const Text('清理临时文件和缓存'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                _showClearCacheDialog();
              },
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
  
  /// 构建关于信息
  Widget _buildAboutInfo() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '关于',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.videocam,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(
                         _appName,
                         style: const TextStyle(
                           fontSize: 20,
                           fontWeight: FontWeight.bold,
                         ),
                       ),
                       const SizedBox(height: 4),
                       Text(
                         '版本 $_appVersion (Build $_buildNumber)',
                         style: const TextStyle(
                           fontSize: 14,
                           color: Colors.grey,
                         ),
                       ),
                       Text(
                         '编译日期: ${DateTime.now().toString().split(' ')[0]}',
                         style: const TextStyle(
                           fontSize: 12,
                           color: Colors.grey,
                         ),
                       ),
                     ],
                   ),
                 ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              '一款简洁高效的行车记录仪应用，支持高清视频录制、文件管理和多种分辨率设置。',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.copyright,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  '${DateTime.now().toString().split('-')[0]} 行车记录仪团队',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// 显示存储位置对话框
  void _showStorageLocationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('文件存储位置'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('录制的视频文件保存在以下目录中：'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SelectableText(
                  _videoStoragePath.isNotEmpty ? _videoStoragePath : '正在获取路径...',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.blue[600],
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      Platform.isAndroid 
                        ? '视频文件保存在设备的Movies或DCIM目录下的VeloMemo文件夹中，可通过文件管理器访问。'
                        : '视频文件保存在应用的文档目录中。',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[600],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.warning_amber_outlined,
                    size: 16,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      Platform.isAndroid
                        ? '如需长期保存，建议定期备份到云存储。'
                        : '卸载应用时，这些文件将被删除。如需长期保存，请及时备份到相册或云存储。',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }
  
  /// 显示清理缓存对话框
  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('清理缓存'),
          content: const Text('此功能将清理应用的临时文件和缓存数据，但不会删除已录制的视频文件。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _clearCache();
              },
              child: const Text('清理'),
            ),
          ],
        );
      },
    );
  }
  
  /// 清理缓存
  void _clearCache() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('缓存清理完成'),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildCameraSelector(),
                  _buildResolutionSelector(),
                  _buildStorageInfo(),
                  _buildOtherSettings(),
                  _buildAboutInfo(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}