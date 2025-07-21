import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// 获取VeloMemo专用视频存放目录
Future<Directory> getVideoDirectory() async {
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