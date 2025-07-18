# VeloMemo 测试指南

本文档介绍如何在 VeloMemo 项目中运行测试。

## 📋 测试概览

项目包含以下类型的测试：

- **单元测试**: 测试核心业务逻辑
  - `speed_calculator_test.dart` - 速度计算逻辑测试
  - `video_recorder_test.dart` - 视频录制功能测试
  - `video_thumbnail_manager_test.dart` - 视频缩略图管理测试

- **组件测试**: 测试 UI 组件
  - `speed_display_widget_test.dart` - 速度显示组件测试（47个测试用例）
  - `widget_test.dart` - 基本 UI 组件测试

- **集成测试**: 测试组件间交互
  - `integration_test.dart` - 基本集成测试

## 🚀 快速开始

### 方法一：使用测试脚本（推荐）

#### macOS/Linux:
```bash
# 运行所有测试
./run_tests.sh

# 或指定测试类型
./run_tests.sh --all          # 所有测试
./run_tests.sh --unit         # 单元测试
./run_tests.sh --widget       # 组件测试
./run_tests.sh --integration  # 集成测试
./run_tests.sh --coverage     # 生成覆盖率报告
```

#### Windows:
```cmd
# 运行所有测试
run_tests.bat

# 或指定测试类型
run_tests.bat -a    # 所有测试
run_tests.bat -u    # 单元测试
run_tests.bat -w    # 组件测试
run_tests.bat -i    # 集成测试
run_tests.bat -c    # 生成覆盖率报告
```

### 方法二：使用 Makefile（macOS/Linux）

```bash
# 查看所有可用命令
make help

# 运行测试
make test              # 所有测试
make test-unit         # 单元测试
make test-widget       # 组件测试
make test-integration  # 集成测试
make test-coverage     # 覆盖率报告

# 其他有用命令
make clean             # 清理项目
make deps              # 获取依赖
make analyze           # 代码分析
make format            # 代码格式化
```

### 方法三：直接使用 Flutter 命令

```bash
# 运行所有测试
flutter test

# 运行特定测试文件
flutter test test/speed_calculator_test.dart
flutter test test/speed_display_widget_test.dart

# 生成覆盖率报告
flutter test --coverage
```

## 📊 测试覆盖率

### 生成覆盖率报告

```bash
# 使用脚本（推荐）
./run_tests.sh --coverage

# 或使用 Makefile
make test-coverage

# 或直接使用 Flutter
flutter test --coverage
```

### 查看覆盖率报告

覆盖率文件会生成在 `coverage/lcov.info`。

**macOS 用户**（如果安装了 lcov）：
- HTML 报告会自动生成在 `coverage/html/index.html`
- 脚本会自动在浏览器中打开报告

**安装 lcov**：
```bash
# macOS
brew install lcov

# Ubuntu/Debian
sudo apt-get install lcov
```

## 🔧 测试配置

### 测试环境要求

- Flutter SDK
- Dart SDK
- 项目依赖已安装（`flutter pub get`）

### 测试文件结构

```
test/
├── integration_test.dart           # 集成测试
├── speed_calculator_test.dart      # 速度计算单元测试
├── speed_display_widget_test.dart  # 速度显示组件测试
├── test_utils.dart                 # 测试工具函数
├── video_recorder_test.dart        # 视频录制测试
├── video_recorder_test.mocks.dart  # Mock 文件
├── video_thumbnail_manager_test.dart # 缩略图管理测试
├── video_thumbnail_manager_test.mocks.dart # Mock 文件
└── widget_test.dart                # 基本组件测试
```

## 🐛 故障排除

### 常见问题

1. **权限错误（macOS/Linux）**
   ```bash
   chmod +x run_tests.sh
   ```

2. **Flutter 未找到**
   - 确保 Flutter 已安装并在 PATH 中
   - 运行 `flutter doctor` 检查环境

3. **依赖问题**
   ```bash
   flutter clean
   flutter pub get
   ```

4. **测试失败**
   - 检查是否在项目根目录
   - 确保所有依赖已安装
   - 查看具体错误信息

### 获取详细输出

```bash
# 使用 -v 参数获取详细输出
flutter test -v

# 或在脚本中查看完整日志
./run_tests.sh --verbose
```

## 📝 编写新测试

### 单元测试示例

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:velomemo/your_class.dart';

void main() {
  group('YourClass Tests', () {
    test('should do something', () {
      // Arrange
      final instance = YourClass();
      
      // Act
      final result = instance.doSomething();
      
      // Assert
      expect(result, equals(expectedValue));
    });
  });
}
```

### 组件测试示例

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:velomemo/your_widget.dart';

void main() {
  group('YourWidget Tests', () {
    testWidgets('should display correctly', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: YourWidget(),
        ),
      );
      
      // Assert
      expect(find.text('Expected Text'), findsOneWidget);
    });
  });
}
```

## 🎯 最佳实践

1. **运行测试前**：
   - 确保代码已保存
   - 运行 `flutter pub get` 更新依赖
   - 使用 `flutter analyze` 检查代码质量

2. **测试命名**：
   - 使用描述性的测试名称
   - 遵循 "should do something when condition" 格式

3. **测试组织**：
   - 使用 `group()` 组织相关测试
   - 每个文件测试一个类或功能模块

4. **持续集成**：
   ```bash
   # CI 流程
   make ci  # 包含依赖获取、代码分析和测试
   ```

## 📚 相关资源

- [Flutter 测试文档](https://docs.flutter.dev/testing)
- [Dart 测试包文档](https://pub.dev/packages/test)
- [Flutter 组件测试](https://docs.flutter.dev/testing/widget-tests)
- [Flutter 集成测试](https://docs.flutter.dev/testing/integration-tests)