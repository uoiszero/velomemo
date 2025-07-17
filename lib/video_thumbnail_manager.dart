import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

/// 视频缩略图管理器
/// 负责生成、缓存和管理视频文件的缩略图
class VideoThumbnailManager {
  static VideoThumbnailManager? _instance;
  static VideoThumbnailManager get instance => _instance ??= VideoThumbnailManager._();
  
  VideoThumbnailManager._();
  
  Directory? _cacheDir;
  
  /// 初始化缓存目录
  Future<void> initialize() async {
    final appDir = await getApplicationDocumentsDirectory();
    _cacheDir = Directory(path.join(appDir.path, 'video_thumbnails'));
    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }
  }
  
  /// 生成缓存键
  /// 基于视频文件路径、修改时间和文件大小生成唯一标识
  String _generateCacheKey(File videoFile, FileStat stat) {
    final fileName = path.basenameWithoutExtension(videoFile.path);
    final modifiedTime = stat.modified.millisecondsSinceEpoch;
    final fileSize = stat.size;
    return '${fileName}_${modifiedTime}_$fileSize.jpg';
  }
  
  /// 获取视频缩略图
  /// 如果缓存存在则返回缓存文件，否则生成新的缩略图
  Future<File?> getThumbnail(File videoFile) async {
    try {
      if (_cacheDir == null) {
        await initialize();
      }
      
      final stat = await videoFile.stat();
      final cacheKey = _generateCacheKey(videoFile, stat);
      final cacheFile = File(path.join(_cacheDir!.path, cacheKey));
      
      // 检查缓存是否存在
      if (await cacheFile.exists()) {
        return cacheFile;
      }
      
      // 生成新的缩略图
      final thumbnailData = await VideoThumbnail.thumbnailData(
        video: videoFile.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 200,
        quality: 75,
      );
      
      if (thumbnailData != null) {
        await cacheFile.writeAsBytes(thumbnailData);
        return cacheFile;
      }
      
      return null;
    } catch (e) {
      print('生成缩略图失败: $e');
      return null;
    }
  }
  
  /// 清理过期的缓存文件
  /// 删除7天前的缓存文件
  Future<void> cleanExpiredCache() async {
    try {
      if (_cacheDir == null || !await _cacheDir!.exists()) {
        return;
      }
      
      final now = DateTime.now();
      final expiredTime = now.subtract(const Duration(days: 7));
      
      await for (final entity in _cacheDir!.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          if (stat.modified.isBefore(expiredTime)) {
            await entity.delete();
            print('删除过期缓存: ${entity.path}');
          }
        }
      }
    } catch (e) {
      print('清理缓存失败: $e');
    }
  }
  
  /// 清理所有缓存
  Future<void> clearAllCache() async {
    try {
      if (_cacheDir != null && await _cacheDir!.exists()) {
        await _cacheDir!.delete(recursive: true);
        await _cacheDir!.create(recursive: true);
      }
    } catch (e) {
      print('清理所有缓存失败: $e');
    }
  }
  
  /// 获取缓存大小
  Future<int> getCacheSize() async {
    try {
      if (_cacheDir == null || !await _cacheDir!.exists()) {
        return 0;
      }
      
      int totalSize = 0;
      await for (final entity in _cacheDir!.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          totalSize += stat.size;
        }
      }
      return totalSize;
    } catch (e) {
      print('获取缓存大小失败: $e');
      return 0;
    }
  }
}