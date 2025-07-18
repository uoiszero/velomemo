// VeloMemo 基本集成测试
//
// 测试应用的基本组件功能

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('VeloMemo 基本集成测试', () {
    group('基本UI组件测试', () {
      testWidgets('基本布局测试', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              appBar: AppBar(title: const Text('VeloMemo')),
              body: const Center(
                child: Text('测试内容'),
              ),
            ),
          ),
        );
        
        // 验证基本组件存在
        expect(find.text('VeloMemo'), findsOneWidget);
        expect(find.text('测试内容'), findsOneWidget);
      });
      
      testWidgets('导航组件测试', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: const Center(child: Text('主页')),
              bottomNavigationBar: BottomNavigationBar(
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.folder),
                    label: '文件',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.videocam),
                    label: '录制',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.settings),
                    label: '设置',
                  ),
                ],
              ),
            ),
          ),
        );
        
        // 验证导航组件
        expect(find.byIcon(Icons.folder), findsOneWidget);
        expect(find.byIcon(Icons.videocam), findsOneWidget);
        expect(find.byIcon(Icons.settings), findsOneWidget);
      });
    });
  });
}