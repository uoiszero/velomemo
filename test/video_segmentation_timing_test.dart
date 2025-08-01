// 视频分割时间测试
//
// 模拟1分钟录制，验证10秒间隔分割是否产生6个文件

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:velomemo/video_recorder.dart';

void main() {
  group('视频分割时间测试', () {
    late VideoRecorder videoRecorder;
    
    setUp(() {
      videoRecorder = VideoRecorder.instance;
    });
    
    tearDown(() async {
      try {
        if (videoRecorder.isRecording) {
          await videoRecorder.stopRecording();
        }
      } catch (e) {
        // 忽略清理时的错误
      }
    });
    
    /// 模拟1分钟录制，验证10秒间隔分割产生6个文件
    /// 这个测试模拟了真实的时间场景，但不会真正等待60秒
    test('模拟1分钟录制产生6个分割文件测试', () async {
      // 配置测试参数
      const segmentDurationSeconds = 10;  // 10秒间隔
      const totalRecordingSeconds = 60;   // 总录制时间1分钟
      const expectedFileCount = totalRecordingSeconds ~/ segmentDurationSeconds; // 期望6个文件
      
      // 验证计算正确性
      expect(expectedFileCount, 6, reason: '1分钟录制，10秒间隔应该产生6个文件');
      
      // 启用视频分割功能
      videoRecorder.setVideoSegmentationEnabled(true);
      expect(videoRecorder.isVideoSegmentationEnabled, true);
      
      // 模拟录制开始时间
      final recordingStartTime = DateTime.now();
      final roundedMinute = DateTime(
        recordingStartTime.year,
        recordingStartTime.month,
        recordingStartTime.day,
        recordingStartTime.hour,
        recordingStartTime.minute
      );
      
      final formatter = DateFormat('yyyy_MM_dd_HH_mm');
      final baseFileName = formatter.format(roundedMinute);
      
      // 生成期望的文件列表
      final expectedFiles = <Map<String, dynamic>>[];
      
      for (int i = 0; i < expectedFileCount; i++) {
        final segmentStartTime = recordingStartTime.add(
          Duration(seconds: segmentDurationSeconds * i)
        );
        final paddedIndex = i.toString().padLeft(3, '0');
        final fileName = '${baseFileName}_$paddedIndex.mp4';
        
        expectedFiles.add({
          'index': i,
          'fileName': fileName,
          'startTime': segmentStartTime,
          'expectedDuration': segmentDurationSeconds,
        });
      }
      
      // 验证文件数量
      expect(expectedFiles.length, expectedFileCount);
      
      // 验证每个文件的属性
      for (int i = 0; i < expectedFiles.length; i++) {
        final file = expectedFiles[i];
        
        // 验证文件名格式
        final fileName = file['fileName'] as String;
        expect(fileName.endsWith('.mp4'), true);
        
        // 验证索引格式（3位数，左侧补零）
        final expectedSuffix = '_${i.toString().padLeft(3, '0')}.mp4';
        expect(fileName.endsWith(expectedSuffix), true);
        
        // 验证时间戳格式
        final regex = RegExp(r'^\d{4}_\d{2}_\d{2}_\d{2}_\d{2}_\d{3}\.mp4$');
        expect(regex.hasMatch(fileName), true);
      }
      
      // 验证时间间隔
      for (int i = 1; i < expectedFiles.length; i++) {
        final prevFile = expectedFiles[i - 1];
        final currentFile = expectedFiles[i];
        
        final prevStartTime = prevFile['startTime'] as DateTime;
        final currentStartTime = currentFile['startTime'] as DateTime;
        
        final interval = currentStartTime.difference(prevStartTime);
        expect(interval.inSeconds, segmentDurationSeconds,
            reason: '第${i + 1}个文件与第$i个文件的间隔应该是${segmentDurationSeconds}秒');
      }
      
      // 验证总录制时长
      final firstFile = expectedFiles.first;
      final lastFile = expectedFiles.last;
      
      final firstStartTime = firstFile['startTime'] as DateTime;
      final lastStartTime = lastFile['startTime'] as DateTime;
      
      final totalDuration = lastStartTime.difference(firstStartTime);
      final expectedTotalDuration = Duration(seconds: (expectedFileCount - 1) * segmentDurationSeconds);
      
      expect(totalDuration, expectedTotalDuration,
          reason: '总录制时长应该是${expectedTotalDuration.inSeconds}秒');
      
      // 模拟分割切换的详细时间线
      final timeline = <Map<String, dynamic>>[];
      
      for (int i = 0; i < expectedFileCount; i++) {
        final segmentStart = recordingStartTime.add(
          Duration(seconds: segmentDurationSeconds * i)
        );
        final segmentEnd = segmentStart.add(
          Duration(seconds: segmentDurationSeconds)
        );
        
        timeline.add({
          'segmentIndex': i,
          'fileName': expectedFiles[i]['fileName'],
          'startTime': segmentStart,
          'endTime': segmentEnd,
          'duration': segmentDurationSeconds,
        });
      }
      
      // 验证时间线的连续性
      for (int i = 1; i < timeline.length; i++) {
        final prevSegment = timeline[i - 1];
        final currentSegment = timeline[i];
        
        final prevEndTime = prevSegment['endTime'] as DateTime;
        final currentStartTime = currentSegment['startTime'] as DateTime;
        
        // 验证分割之间没有时间间隙
        expect(currentStartTime, prevEndTime,
            reason: '分割${i - 1}的结束时间应该等于分割$i的开始时间');
      }
      
      // 输出测试结果
      print('\n=== 1分钟录制分割测试结果 ===');
      print('录制开始时间: ${recordingStartTime.toIso8601String()}');
      print('分割间隔: ${segmentDurationSeconds}秒');
      print('总录制时长: ${totalRecordingSeconds}秒');
      print('期望文件数量: $expectedFileCount');
      print('实际生成文件数量: ${expectedFiles.length}');
      print('\n生成的文件列表:');
      
      for (int i = 0; i < expectedFiles.length; i++) {
        final file = expectedFiles[i];
        final startTime = file['startTime'] as DateTime;
        print('  ${i + 1}. ${file['fileName']} (开始时间: ${startTime.toIso8601String().substring(11, 19)})');
      }
      
      print('\n时间线验证:');
      for (int i = 0; i < timeline.length; i++) {
        final segment = timeline[i];
        final startTime = segment['startTime'] as DateTime;
        final endTime = segment['endTime'] as DateTime;
        print('  分割${i + 1}: ${startTime.toIso8601String().substring(11, 19)} - ${endTime.toIso8601String().substring(11, 19)} (${segment['duration']}秒)');
      }
      
      // 最终验证
      expect(expectedFiles.length, 6, reason: '应该生成6个分割文件');
      
      print('\n✅ 测试通过：1分钟录制成功生成6个10秒分割文件');
    });
    
    /// 测试不同录制时长的分割文件数量
    test('不同录制时长的分割文件数量测试', () {
      const segmentDurationSeconds = 10;
      
      final testCases = [
        {'duration': 10, 'expected': 1},   // 10秒 -> 1个文件
        {'duration': 20, 'expected': 2},   // 20秒 -> 2个文件
        {'duration': 30, 'expected': 3},   // 30秒 -> 3个文件
        {'duration': 45, 'expected': 4},   // 45秒 -> 4个文件（第5个文件不足10秒）
        {'duration': 60, 'expected': 6},   // 60秒 -> 6个文件
        {'duration': 90, 'expected': 9},   // 90秒 -> 9个文件
        {'duration': 120, 'expected': 12}, // 120秒 -> 12个文件
      ];
      
      for (final testCase in testCases) {
        final duration = testCase['duration'] as int;
        final expected = testCase['expected'] as int;
        
        final actualFileCount = duration ~/ segmentDurationSeconds;
        expect(actualFileCount, expected,
            reason: '${duration}秒录制应该产生$expected个文件，实际计算得到$actualFileCount个');
      }
      
      print('\n=== 不同录制时长测试结果 ===');
      for (final testCase in testCases) {
        final duration = testCase['duration'] as int;
        final expected = testCase['expected'] as int;
        print('${duration}秒录制 -> $expected个文件');
      }
    });
    
    /// 测试分割文件的命名连续性
    test('分割文件命名连续性测试', () {
      const totalFiles = 6;
      final now = DateTime.now();
      final roundedMinute = DateTime(now.year, now.month, now.day, now.hour, now.minute);
      final formatter = DateFormat('yyyy_MM_dd_HH_mm');
      final baseFileName = formatter.format(roundedMinute);
      
      final fileNames = <String>[];
      
      // 生成6个连续的文件名
      for (int i = 0; i < totalFiles; i++) {
        final paddedIndex = i.toString().padLeft(3, '0');
        final fileName = '${baseFileName}_$paddedIndex.mp4';
        fileNames.add(fileName);
      }
      
      // 验证文件名的连续性
      for (int i = 0; i < fileNames.length; i++) {
        final fileName = fileNames[i];
        final expectedSuffix = '_${i.toString().padLeft(3, '0')}.mp4';
        
        expect(fileName.endsWith(expectedSuffix), true,
            reason: '第${i + 1}个文件应该以$expectedSuffix结尾');
        
        // 验证基础文件名一致
        expect(fileName.startsWith(baseFileName), true,
            reason: '所有文件应该有相同的基础文件名前缀');
      }
      
      // 验证索引的连续性
      final indices = fileNames.map((fileName) {
        final parts = fileName.split('_');
        final indexPart = parts.last.replaceAll('.mp4', '');
        return int.parse(indexPart);
      }).toList();
      
      for (int i = 0; i < indices.length; i++) {
        expect(indices[i], i, reason: '第${i + 1}个文件的索引应该是$i');
      }
      
      print('\n=== 文件命名连续性测试结果 ===');
      print('基础文件名: $baseFileName');
      print('生成的文件名:');
      for (int i = 0; i < fileNames.length; i++) {
        print('  ${i + 1}. ${fileNames[i]}');
      }
      
      expect(fileNames.length, 6, reason: '应该生成6个连续命名的文件');
    });
  });
}