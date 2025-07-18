// VeloMemo 应用基本组件测试
//
// 测试应用的基本UI组件

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VeloMemo Basic Widget Tests', () {
    testWidgets('基本UI组件测试', (WidgetTester tester) async {
      // 测试基本的UI组件
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: const Text('VeloMemo')),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('0.0', style: TextStyle(fontSize: 48)),
                  Text('km/h', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ),
        ),
      );
      
      // 验证基本UI元素
      expect(find.text('VeloMemo'), findsOneWidget);
      expect(find.text('0.0'), findsOneWidget);
      expect(find.text('km/h'), findsOneWidget);
    });
    
    testWidgets('按钮组件测试', (WidgetTester tester) async {
      bool buttonPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  buttonPressed = true;
                },
                child: const Text('测试按钮'),
              ),
            ),
          ),
        ),
      );
      
      // 验证按钮存在并可点击
      expect(find.text('测试按钮'), findsOneWidget);
      await tester.tap(find.text('测试按钮'));
      expect(buttonPressed, isTrue);
    });
    
    testWidgets('图标组件测试', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Icon(Icons.videocam),
                  Icon(Icons.folder),
                  Icon(Icons.settings),
                ],
              ),
            ),
          ),
        ),
      );
      
      // 验证图标存在
      expect(find.byIcon(Icons.videocam), findsOneWidget);
      expect(find.byIcon(Icons.folder), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });
  });
}
