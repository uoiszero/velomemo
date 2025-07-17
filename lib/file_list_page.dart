import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 文件列表页面
class FileListPage extends StatefulWidget {
  const FileListPage({super.key});

  @override
  State<FileListPage> createState() => _FileListPageState();
}

class _FileListPageState extends State<FileListPage> {
  List<FileSystemEntity> _files = [];
  bool _isLoading = true;
  String _currentPath = '';
  
  // 显示模式：列表或网格
  bool _isGridView = false;
  
  // 排序相关
  SortField _sortField = SortField.name;
  bool _isAscending = true;
  
  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
    _loadFiles();
  }
  
  /// 加载用户偏好设置
  Future<void> _loadUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isGridView = prefs.getBool('file_list_grid_view') ?? false;
      _sortField = SortField.values[prefs.getInt('file_list_sort_field') ?? 0];
      _isAscending = prefs.getBool('file_list_sort_ascending') ?? true;
    });
  }
  
  /// 保存用户偏好设置
  Future<void> _saveUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('file_list_grid_view', _isGridView);
    await prefs.setInt('file_list_sort_field', _sortField.index);
    await prefs.setBool('file_list_sort_ascending', _isAscending);
  }
  
  /// 获取视频存储目录
  Future<Directory> _getVideoDirectory() async {
    try {
      // 优先尝试外部存储的 Movies 目录
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        final moviesDir = Directory('${externalDir.parent.parent.parent.parent.path}/Movies/VeloMemo');
        if (await moviesDir.exists() || await moviesDir.create(recursive: true).then((_) => true).catchError((_) => false)) {
          return moviesDir;
        }
        
        // 如果 Movies 目录不可用，尝试 DCIM 目录
        final dcimDir = Directory('${externalDir.parent.parent.parent.parent.path}/DCIM/VeloMemo');
        if (await dcimDir.exists() || await dcimDir.create(recursive: true).then((_) => true).catchError((_) => false)) {
          return dcimDir;
        }
      }
    } catch (e) {
      print('无法访问外部存储: $e');
    }
    
    // 回退到应用文档目录
    final appDir = await getApplicationDocumentsDirectory();
    final videoDir = Directory('${appDir.path}/VeloMemo');
    if (!await videoDir.exists()) {
      await videoDir.create(recursive: true);
    }
    return videoDir;
  }

  /// 加载文件列表
  Future<void> _loadFiles() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 获取视频存储目录
      final directory = await _getVideoDirectory();
      _currentPath = directory.path;
      
      // 获取目录下的所有文件
      if (await directory.exists()) {
        final entities = await directory.list().toList();
        
        // 过滤出视频文件
        _files = entities.where((entity) {
          if (entity is File) {
            final extension = entity.path.toLowerCase().split('.').last;
            return ['mp4', 'mov', 'avi', 'mkv'].contains(extension);
          }
          return false;
        }).toList();
        
        // 应用排序
        _sortFiles();
      }
    } catch (e) {
      print('加载文件失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  /// 排序文件
  void _sortFiles() {
    _files.sort((a, b) {
      int comparison = 0;
      
      switch (_sortField) {
        case SortField.name:
          comparison = a.path.split('/').last.compareTo(b.path.split('/').last);
          break;
        case SortField.size:
          if (a is File && b is File) {
            final sizeA = a.lengthSync();
            final sizeB = b.lengthSync();
            comparison = sizeA.compareTo(sizeB);
          }
          break;
        case SortField.date:
          if (a is File && b is File) {
            final dateA = a.lastModifiedSync();
            final dateB = b.lastModifiedSync();
            comparison = dateA.compareTo(dateB);
          }
          break;
      }
      
      return _isAscending ? comparison : -comparison;
    });
  }
  
  /// 格式化文件大小
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
  
  /// 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    return formatter.format(dateTime);
  }
  
  /// 构建排序选择器
  Widget _buildSortSelector() {
    return PopupMenuButton<SortOption>(
      icon: const Icon(Icons.sort, color: Colors.white),
      onSelected: (SortOption option) {
        setState(() {
          if (option.field == _sortField) {
            _isAscending = !_isAscending;
          } else {
            _sortField = option.field;
            _isAscending = option.ascending;
          }
          _sortFiles();
        });
        _saveUserPreferences();
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem(
          value: SortOption(SortField.name, true),
          child: Row(
            children: [
              Icon(
                _sortField == SortField.name && _isAscending
                    ? Icons.check
                    : Icons.sort_by_alpha,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text('按名称升序'),
            ],
          ),
        ),
        PopupMenuItem(
          value: SortOption(SortField.name, false),
          child: Row(
            children: [
              Icon(
                _sortField == SortField.name && !_isAscending
                    ? Icons.check
                    : Icons.sort_by_alpha,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text('按名称降序'),
            ],
          ),
        ),
        PopupMenuItem(
          value: SortOption(SortField.size, false),
          child: Row(
            children: [
              Icon(
                _sortField == SortField.size && !_isAscending
                    ? Icons.check
                    : Icons.data_usage,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text('按大小降序'),
            ],
          ),
        ),
        PopupMenuItem(
          value: SortOption(SortField.size, true),
          child: Row(
            children: [
              Icon(
                _sortField == SortField.size && _isAscending
                    ? Icons.check
                    : Icons.data_usage,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text('按大小升序'),
            ],
          ),
        ),
        PopupMenuItem(
          value: SortOption(SortField.date, false),
          child: Row(
            children: [
              Icon(
                _sortField == SortField.date && !_isAscending
                    ? Icons.check
                    : Icons.access_time,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text('按日期降序'),
            ],
          ),
        ),
        PopupMenuItem(
          value: SortOption(SortField.date, true),
          child: Row(
            children: [
              Icon(
                _sortField == SortField.date && _isAscending
                    ? Icons.check
                    : Icons.access_time,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text('按日期升序'),
            ],
          ),
        ),
      ],
    );
  }
  
  /// 构建列表视图
  Widget _buildListView() {
    return ListView.builder(
      itemCount: _files.length,
      itemBuilder: (context, index) {
        final file = _files[index] as File;
        final fileName = file.path.split('/').last;
        final fileSize = _formatFileSize(file.lengthSync());
        final fileDate = _formatDateTime(file.lastModifiedSync());
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: const Icon(
              Icons.video_file,
              color: Colors.blue,
              size: 40,
            ),
            title: Text(
              fileName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('大小: $fileSize'),
                Text('日期: $fileDate'),
              ],
            ),
            trailing: PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'play',
                  child: Row(
                    children: [
                      Icon(Icons.play_arrow),
                      SizedBox(width: 8),
                      Text('播放'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share),
                      SizedBox(width: 8),
                      Text('分享'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('删除', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) => _handleFileAction(value, file),
            ),
            onTap: () => _handleFileAction('play', file),
          ),
        );
      },
    );
  }
  
  /// 构建网格视图
  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: _files.length,
      itemBuilder: (context, index) {
        final file = _files[index] as File;
        final fileName = file.path.split('/').last;
        final fileSize = _formatFileSize(file.lengthSync());
        final fileDate = _formatDateTime(file.lastModifiedSync());
        
        return Card(
          child: InkWell(
            onTap: () => _handleFileAction('play', file),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.video_file,
                        size: 60,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    fileName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fileSize,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    fileDate,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  /// 处理文件操作
  void _handleFileAction(String action, File file) {
    switch (action) {
      case 'play':
        _showMessage('播放功能正在开发中...');
        break;
      case 'share':
        _showMessage('分享功能正在开发中...');
        break;
      case 'delete':
        _showDeleteConfirmDialog(file);
        break;
    }
  }
  
  /// 显示删除确认对话框
  void _showDeleteConfirmDialog(File file) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: Text('确定要删除文件 "${file.path.split('/').last}" 吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteFile(file);
              },
              child: const Text('删除', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
  
  /// 删除文件
  Future<void> _deleteFile(File file) async {
    try {
      await file.delete();
      _showMessage('文件删除成功');
      _loadFiles(); // 重新加载文件列表
    } catch (e) {
      _showMessage('删除文件失败: $e');
    }
  }
  
  /// 显示消息
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('录制文件列表'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
              _saveUserPreferences();
            },
            tooltip: _isGridView ? '列表视图' : '网格视图',
          ),
          _buildSortSelector(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFiles,
            tooltip: '刷新',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _files.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.video_library_outlined,
                        size: 80,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '暂无录制文件',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '文件保存路径: $_currentPath',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : _isGridView
                  ? _buildGridView()
                  : _buildListView(),
    );
  }
}

/// 排序字段枚举
enum SortField {
  name,
  size,
  date,
}

/// 排序选项
class SortOption {
  final SortField field;
  final bool ascending;
  
  SortOption(this.field, this.ascending);
}