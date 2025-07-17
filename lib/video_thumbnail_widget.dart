import 'dart:io';
import 'package:flutter/material.dart';
import 'video_thumbnail_manager.dart';

/// 视频缩略图显示组件
/// 异步加载并显示视频文件的缩略图，包含加载指示器和错误处理
class VideoThumbnailWidget extends StatefulWidget {
  final File videoFile;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool showPlayButton;
  final VoidCallback? onTap;
  
  const VideoThumbnailWidget({
    super.key,
    required this.videoFile,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.showPlayButton = true,
    this.onTap,
  });
  
  @override
  State<VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget> {
  File? _thumbnailFile;
  bool _isLoading = true;
  bool _hasError = false;
  
  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }
  
  @override
  void didUpdateWidget(VideoThumbnailWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoFile.path != widget.videoFile.path) {
      _loadThumbnail();
    }
  }
  
  /// 加载视频缩略图
  Future<void> _loadThumbnail() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _hasError = false;
      _thumbnailFile = null;
    });
    
    try {
      final thumbnailFile = await VideoThumbnailManager.instance.getThumbnail(widget.videoFile);
      
      if (!mounted) return;
      
      setState(() {
        _thumbnailFile = thumbnailFile;
        _isLoading = false;
        _hasError = thumbnailFile == null;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _hasError = true;
        _thumbnailFile = null;
      });
    }
  }
  
  /// 构建加载指示器
  Widget _buildLoadingIndicator() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
          ),
        ),
      ),
    );
  }
  
  /// 构建错误占位符
  Widget _buildErrorPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Icon(
          Icons.video_file,
          size: 48,
          color: Colors.grey,
        ),
      ),
    );
  }
  
  /// 构建缩略图内容
  Widget _buildThumbnailContent() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        image: DecorationImage(
          image: FileImage(_thumbnailFile!),
          fit: widget.fit,
        ),
      ),
      child: widget.showPlayButton
          ? Center(
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            )
          : null,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    Widget content;
    
    if (_isLoading) {
      content = _buildLoadingIndicator();
    } else if (_hasError || _thumbnailFile == null) {
      content = _buildErrorPlaceholder();
    } else {
      content = _buildThumbnailContent();
    }
    
    if (widget.onTap != null) {
      return GestureDetector(
        onTap: widget.onTap,
        child: content,
      );
    }
    
    return content;
  }
}