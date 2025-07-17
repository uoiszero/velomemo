// VeloMemo 应用主要组件测试
//
// 测试应用的基本功能和UI组件

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velomemo/main.dart';

void main() {
  group('VeloMemo App Tests', () {
    testWidgets('应用启动测试', (WidgetTester tester) async {
      // 构建应用并触发一帧
      await tester.pumpWidget(const MyApp());
      
      // 验证应用标题
      expect(find.text('VeloMemo'), findsOneWidget);
      
      // 等待应用完全加载
      await tester.pumpAndSettle();
    });
    
    testWidgets('底部导航按钮存在性测试', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      
      // 验证底部按钮存在
      expect(find.byIcon(Icons.folder), findsOneWidget); // 文件列表按钮
      expect(find.byIcon(Icons.videocam), findsOneWidget); // 录制按钮
      expect(find.byIcon(Icons.settings), findsOneWidget); // 设置按钮
    });
    
    testWidgets('速度显示组件存在性测试', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      
      // 验证速度显示相关文本存在
      expect(find.textContaining('km/h'), findsWidgets);
    });
  });
}
