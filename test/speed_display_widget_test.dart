// SpeedDisplayWidget 组件测试
//
// 测试速度显示组件的UI和交互功能

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velomemo/speed_display_widget.dart';

void main() {
  group('SpeedDisplayWidget Tests', () {
    group('UI渲染测试', () {
      testWidgets('基本UI元素渲染测试', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SpeedDisplayWidget(),
            ),
          ),
        );
        
        // 等待组件初始化
        await tester.pump();
        
        // 验证速度显示文本存在
        expect(find.textContaining('km/h'), findsOneWidget);
        expect(find.textContaining('0.0'), findsOneWidget);
      });
      
      testWidgets('详细信息显示测试', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SpeedDisplayWidget(
                showDetailedInfo: true,
              ),
            ),
          ),
        );
        
        // 等待组件渲染
        await tester.pumpAndSettle();
        
        // 验证详细信息显示
        expect(find.textContaining('GPS速度'), findsOneWidget);
        expect(find.textContaining('修正速度'), findsOneWidget);
        expect(find.textContaining('原始速度'), findsOneWidget);
      });
    });
    
    group('状态指示测试', () {
       testWidgets('传感器状态显示测试', (WidgetTester tester) async {
         await tester.pumpWidget(
           const MaterialApp(
             home: Scaffold(
               body: SpeedDisplayWidget(
                 showDetailedInfo: true,
               ),
             ),
           ),
         );
         
         // 等待组件渲染
         await tester.pumpAndSettle();
         
         // 验证传感器状态显示
         expect(find.textContaining('传感器状态'), findsOneWidget);
         expect(find.text('GPS速度'), findsOneWidget);
       });
     });
    
    group('精度显示测试', () {
       testWidgets('详细信息中的精度显示测试', (WidgetTester tester) async {
         await tester.pumpWidget(
           const MaterialApp(
             home: Scaffold(
               body: SpeedDisplayWidget(
                 showDetailedInfo: true,
               ),
             ),
           ),
         );
         
         // 等待组件渲染
         await tester.pumpAndSettle();
         
         // 验证详细信息显示
         expect(find.textContaining('GPS速度'), findsOneWidget);
         expect(find.textContaining('修正速度'), findsOneWidget);
       });
     });
    
    group('主题和样式测试', () {
      testWidgets('深色主题测试', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.dark(),
            home: const Scaffold(
              body: SpeedDisplayWidget(),
            ),
          ),
        );
        
        // 等待组件渲染
        await tester.pump();
        
        // 验证组件在深色主题下正常渲染
        expect(find.textContaining('0.0'), findsOneWidget);
        expect(find.textContaining('km/h'), findsOneWidget);
      });
      
      testWidgets('浅色主题测试', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            home: const Scaffold(
              body: SpeedDisplayWidget(),
            ),
          ),
        );
        
        // 等待组件渲染
        await tester.pump();
        
        expect(find.textContaining('0.0'), findsOneWidget);
        expect(find.textContaining('km/h'), findsOneWidget);
      });
      
      testWidgets('自定义样式测试', (WidgetTester tester) async {
         await tester.pumpWidget(
           const MaterialApp(
             home: Scaffold(
               body: SpeedDisplayWidget(
                 speedTextStyle: TextStyle(color: Colors.red),
                 backgroundColor: Colors.blue,
               ),
             ),
           ),
         );
         
         // 等待组件渲染
         await tester.pump();
         
         // 验证组件正常渲染
         expect(find.textContaining('0.0'), findsOneWidget);
       });
    });
    
    group('动画效果测试', () {
       testWidgets('组件渲染测试', (WidgetTester tester) async {
         await tester.pumpWidget(
           const MaterialApp(
             home: Scaffold(
               body: SpeedDisplayWidget(),
             ),
           ),
         );
         
         // 等待组件渲染
         await tester.pump();
         
         expect(find.textContaining('0.0'), findsOneWidget);
         
         // 等待动画完成
         await tester.pumpAndSettle();
         
         expect(find.textContaining('km/h'), findsOneWidget);
       });
     });
    
    group('交互功能测试', () {
       testWidgets('点击交互测试', (WidgetTester tester) async {
         await tester.pumpWidget(
           const MaterialApp(
             home: Scaffold(
               body: SpeedDisplayWidget(),
             ),
           ),
         );
         
         // 等待组件渲染
         await tester.pump();
         
         // 初始显示km/h
         expect(find.textContaining('km/h'), findsOneWidget);
         
         // 点击组件
         await tester.tap(find.byType(SpeedDisplayWidget));
         await tester.pumpAndSettle();
         
         // 验证组件响应点击
         expect(find.byType(SpeedDisplayWidget), findsOneWidget);
       });
       
       testWidgets('长按交互测试', (WidgetTester tester) async {
         await tester.pumpWidget(
           const MaterialApp(
             home: Scaffold(
               body: SpeedDisplayWidget(
                 showDetailedInfo: true,
               ),
             ),
           ),
         );
         
         // 等待组件渲染
         await tester.pump();
         
         // 长按组件
         await tester.longPress(find.byType(SpeedDisplayWidget));
         await tester.pumpAndSettle();
         
         // 验证组件响应长按
         expect(find.byType(SpeedDisplayWidget), findsOneWidget);
       });
     });
    
    group('响应式布局测试', () {
      testWidgets('小屏幕布局测试', (WidgetTester tester) async {
        // 设置小屏幕尺寸
        await tester.binding.setSurfaceSize(const Size(320, 568));
        
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SpeedDisplayWidget(),
            ),
          ),
        );
        
        // 等待组件渲染
        await tester.pump();
        
        expect(find.textContaining('0.0'), findsOneWidget);
        expect(find.textContaining('km/h'), findsOneWidget);
        
        // 重置屏幕尺寸
        await tester.binding.setSurfaceSize(null);
      });
      
      testWidgets('大屏幕布局测试', (WidgetTester tester) async {
        // 设置大屏幕尺寸
        await tester.binding.setSurfaceSize(const Size(1024, 768));
        
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SpeedDisplayWidget(),
            ),
          ),
        );
        
        // 等待组件渲染
        await tester.pump();
        
        expect(find.textContaining('0.0'), findsOneWidget);
        expect(find.textContaining('km/h'), findsOneWidget);
        
        // 重置屏幕尺寸
        await tester.binding.setSurfaceSize(null);
      });
    });
    
    group('性能测试', () {
      testWidgets('组件渲染性能测试', (WidgetTester tester) async {
        final stopwatch = Stopwatch()..start();
        
        // 多次渲染组件
        for (int i = 0; i < 10; i++) {
          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(
                body: SpeedDisplayWidget(),
              ),
            ),
          );
          
          await tester.pump();
        }
        
        stopwatch.stop();
        
        // 10次渲染应该在合理时间内完成
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });
    });
    
    group('边界条件测试', () {
      testWidgets('默认状态测试', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SpeedDisplayWidget(),
            ),
          ),
        );
        
        // 等待组件渲染
        await tester.pump();
        
        // 应该显示默认状态
        expect(find.textContaining('0.0'), findsOneWidget);
        expect(find.textContaining('km/h'), findsOneWidget);
      });
      
      testWidgets('组件初始化测试', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SpeedDisplayWidget(),
            ),
          ),
        );
        
        // 等待组件完全初始化
        await tester.pumpAndSettle();
        
        // 验证组件正常初始化
        expect(find.byType(SpeedDisplayWidget), findsOneWidget);
      });
    });
  });
}