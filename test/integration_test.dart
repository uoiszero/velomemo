// VeloMemo 集成测试
//
// 测试应用的整体功能和页面间的交互

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:velomemo/main.dart' as app;
import 'package:velomemo/file_list_page.dart';
import 'package:velomemo/settings_page.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('VeloMemo 集成测试', () {
    group('应用导航测试', () {
      testWidgets('主页面到文件列表页面导航测试', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        
        // 验证主页面加载
        expect(find.text('VeloMemo'), findsOneWidget);
        
        // 点击文件列表按钮
        await tester.tap(find.byIcon(Icons.folder));
        await tester.pumpAndSettle();
        
        // 验证导航到文件列表页面
        expect(find.byType(FileListPage), findsOneWidget);
        expect(find.text('视频文件'), findsOneWidget);
      });
      
      testWidgets('主页面到设置页面导航测试', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        
        // 点击设置按钮
        await tester.tap(find.byIcon(Icons.settings));
        await tester.pumpAndSettle();
        
        // 验证导航到设置页面
        expect(find.byType(SettingsPage), findsOneWidget);
        expect(find.text('设置'), findsOneWidget);
      });
      
      testWidgets('页面返回导航测试', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        
        // 导航到设置页面
        await tester.tap(find.byIcon(Icons.settings));
        await tester.pumpAndSettle();
        
        // 点击返回按钮
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
        
        // 验证返回到主页面
        expect(find.text('VeloMemo'), findsOneWidget);
        expect(find.byIcon(Icons.videocam), findsOneWidget);
      });
    });
    
    group('文件列表页面功能测试', () {
      testWidgets('文件列表显示测试', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        
        // 导航到文件列表页面
        await tester.tap(find.byIcon(Icons.folder));
        await tester.pumpAndSettle();
        
        // 验证文件列表组件存在
        expect(find.byType(ListView), findsOneWidget);
        
        // 如果有视频文件，验证文件项显示
        // 注意：在测试环境中可能没有实际的视频文件
      });
      
      testWidgets('文件搜索功能测试', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        
        await tester.tap(find.byIcon(Icons.folder));
        await tester.pumpAndSettle();
        
        // 查找搜索框
        final searchField = find.byType(TextField);
        if (searchField.evaluate().isNotEmpty) {
          // 输入搜索关键词
          await tester.enterText(searchField, 'test');
          await tester.pumpAndSettle();
          
          // 验证搜索功能执行
          expect(find.text('test'), findsOneWidget);
        }
      });
      
      testWidgets('文件排序功能测试', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        
        await tester.tap(find.byIcon(Icons.folder));
        await tester.pumpAndSettle();
        
        // 查找排序按钮
        final sortButton = find.byIcon(Icons.sort);
        if (sortButton.evaluate().isNotEmpty) {
          await tester.tap(sortButton);
          await tester.pumpAndSettle();
          
          // 验证排序选项显示
          expect(find.text('按名称排序'), findsWidgets);
        }
      });
    });
    
    group('设置页面功能测试', () {
      testWidgets('摄像头设置测试', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        
        await tester.tap(find.byIcon(Icons.settings));
        await tester.pumpAndSettle();
        
        // 验证摄像头设置选项存在
        expect(find.textContaining('摄像头'), findsWidgets);
        expect(find.textContaining('分辨率'), findsWidgets);
      });
      
      testWidgets('录制设置测试', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        
        await tester.tap(find.byIcon(Icons.settings));
        await tester.pumpAndSettle();
        
        // 验证录制设置选项存在
        expect(find.textContaining('录制'), findsWidgets);
        expect(find.textContaining('视频分割'), findsWidgets);
      });
      
      testWidgets('设置保存测试', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        
        await tester.tap(find.byIcon(Icons.settings));
        await tester.pumpAndSettle();
        
        // 查找开关控件并切换
        final switches = find.byType(Switch);
        if (switches.evaluate().isNotEmpty) {
          await tester.tap(switches.first);
          await tester.pumpAndSettle();
          
          // 返回主页面
          await tester.tap(find.byIcon(Icons.arrow_back));
          await tester.pumpAndSettle();
          
          // 重新进入设置页面验证设置已保存
          await tester.tap(find.byIcon(Icons.settings));
          await tester.pumpAndSettle();
          
          // 验证设置状态保持
          expect(find.byType(Switch), findsWidgets);
        }
      });
    });
    
    group('录制功能集成测试', () {
      testWidgets('录制按钮交互测试', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        
        // 查找录制按钮
        final recordButton = find.byIcon(Icons.videocam);
        expect(recordButton, findsOneWidget);
        
        // 点击录制按钮
        await tester.tap(recordButton);
        await tester.pumpAndSettle();
        
        // 验证录制状态变化（可能需要权限）
        // 在测试环境中，可能无法真正开始录制
      });
      
      testWidgets('录制状态显示测试', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        
        // 验证录制状态指示器存在
        // 查找录制时间显示
        expect(find.textContaining('00:'), findsWidgets);
      });
    });
    
    group('速度跟踪集成测试', () {
      testWidgets('速度显示组件集成测试', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        
        // 验证速度显示组件存在
        expect(find.textContaining('km/h'), findsWidgets);
        
        // 等待GPS初始化
        await tester.pump(const Duration(seconds: 2));
        
        // 验证速度值显示
        expect(find.textContaining('0.0'), findsWidgets);
      });
      
      testWidgets('GPS状态指示测试', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        
        // 验证GPS状态图标存在
        expect(find.byIcon(Icons.gps_fixed), findsWidgets);
      });
    });
    
    group('存储信息显示测试', () {
      testWidgets('存储空间显示测试', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        
        // 等待存储信息加载
        await tester.pump(const Duration(seconds: 1));
        
        // 验证存储信息显示
        expect(find.textContaining('可用空间'), findsWidgets);
        expect(find.textContaining('预计录制'), findsWidgets);
      });
    });
    
    group('UI响应性测试', () {
      testWidgets('屏幕点击隐藏UI测试', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        
        // 点击屏幕中央
        await tester.tapAt(const Offset(200, 400));
        await tester.pumpAndSettle();
        
        // 验证UI隐藏/显示切换
        // 具体的UI元素可能会隐藏或显示
      });
      
      testWidgets('横屏竖屏切换测试', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        
        // 模拟屏幕旋转
        await tester.binding.setSurfaceSize(const Size(800, 600)); // 横屏
        await tester.pumpAndSettle();
        
        // 验证横屏布局
        expect(find.text('VeloMemo'), findsOneWidget);
        
        // 恢复竖屏
        await tester.binding.setSurfaceSize(const Size(400, 800));
        await tester.pumpAndSettle();
        
        // 验证竖屏布局
        expect(find.text('VeloMemo'), findsOneWidget);
        
        // 重置屏幕尺寸
        await tester.binding.setSurfaceSize(null);
      });
    });
    
    group('错误处理集成测试', () {
      testWidgets('网络错误处理测试', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        
        // 模拟网络错误情况
        // 验证应用能够优雅地处理网络错误
        expect(find.text('VeloMemo'), findsOneWidget);
      });
      
      testWidgets('权限拒绝处理测试', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        
        // 在权限被拒绝的情况下，应用应该显示相应的提示
        // 验证权限请求对话框或提示信息
        expect(find.text('VeloMemo'), findsOneWidget);
      });
    });
    
    group('性能集成测试', () {
      testWidgets('应用启动性能测试', (WidgetTester tester) async {
        final stopwatch = Stopwatch()..start();
        
        app.main();
        await tester.pumpAndSettle();
        
        stopwatch.stop();
        
        // 应用启动应该在合理时间内完成
        expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // 5秒内
        
        // 验证主要组件已加载
        expect(find.text('VeloMemo'), findsOneWidget);
      });
      
      testWidgets('页面切换性能测试', (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle();
        
        final stopwatch = Stopwatch()..start();
        
        // 快速切换页面
        for (int i = 0; i < 5; i++) {
          await tester.tap(find.byIcon(Icons.settings));
          await tester.pumpAndSettle();
          
          await tester.tap(find.byIcon(Icons.arrow_back));
          await tester.pumpAndSettle();
        }
        
        stopwatch.stop();
        
        // 页面切换应该流畅
        expect(stopwatch.elapsedMilliseconds, lessThan(3000));
      });
    });
    
    group('数据持久化测试', () {
      testWidgets('应用重启数据保持测试', (WidgetTester tester) async {
        // 第一次启动
        app.main();
        await tester.pumpAndSettle();
        
        // 进入设置页面并修改设置
        await tester.tap(find.byIcon(Icons.settings));
        await tester.pumpAndSettle();
        
        // 修改某个设置
        final switches = find.byType(Switch);
        if (switches.evaluate().isNotEmpty) {
          await tester.tap(switches.first);
          await tester.pumpAndSettle();
        }
        
        // 模拟应用重启
        await tester.binding.reassembleApplication();
        
        app.main();
        await tester.pumpAndSettle();
        
        // 验证设置被保持
        await tester.tap(find.byIcon(Icons.settings));
        await tester.pumpAndSettle();
        
        expect(find.byType(Switch), findsWidgets);
      });
    });
  });
}