# VeloMemo

一款基于 Flutter 开发的智能行车记录仪应用，专为移动设备设计，提供专业的视频录制和管理功能。

## 🚗 应用简介

VeloMemo 是一款功能强大的行车记录仪应用，将您的手机或平板电脑转变为专业的行车记录设备。应用采用现代化的 Material Design 设计语言，提供直观易用的用户界面和丰富的功能特性。

## ✨ 核心功能

### 🎨 专业图标设计
- **行车记录仪主题**：专为行车记录仪应用设计的专业图标
- **摄像头元素**：突出的摄像头主体设计，强化应用功能识别
- **速度表盘**：集成速度表盘元素，体现行车监控特性
- **录制指示灯**：红色录制指示灯，直观表达录制功能
- **多分辨率支持**：完整的 Android 图标规范支持（hdpi、xhdpi、xxhdpi、xxxhdpi）
- **自适应图标**：支持 Android 8.0+ 的 Adaptive Icon 特性
- **SVG 矢量格式**：使用 SVG 源文件，便于修改和维护

### 📹 智能视频录制
- **多分辨率支持**：从 240p 到 4K 超清画质，满足不同存储和画质需求
- **自动视频分割**：支持按时间自动分割视频文件，避免单个文件过大
- **实时录制指示**：录制时显示红色边框和时间水印，状态一目了然
- **智能文件命名**：基于录制时间自动生成有序的文件名
- **后台录制优化**：录制过程中自动调暗屏幕，延长电池续航


### 🎥 摄像头管理
- **多摄像头支持**：自动检测并支持设备上的所有摄像头
- **智能摄像头选择**：优先选择后置摄像头，提供最佳录制效果
- **实时预览**：全屏摄像头预览，所见即所录
- **动态切换**：支持在设置中切换不同摄像头

### 📁 文件管理系统
- **专用存储目录**：在设备的 Movies/VeloMemo 目录下统一管理视频文件
- **多种显示模式**：支持列表视图和网格视图
- **灵活排序选项**：按文件名、大小、日期进行升序或降序排列
- **详细文件信息**：显示文件大小、创建时间等详细信息
- **批量操作**：支持文件的查看、分享和删除操作

### ⚙️ 智能设置系统
- **画质调节**：6 档画质设置，从节省空间到超清画质
- **摄像头配置**：支持选择和配置不同的摄像头
- **存储监控**：实时显示可用存储空间和预计录制时长
- **用户偏好保存**：自动保存用户的设置偏好

### 🔋 电源优化
- **屏幕亮度控制**：录制时自动调暗屏幕，节省电量
- **智能 UI 隐藏**：录制过程中自动隐藏界面元素，减少干扰
- **沉浸式体验**：支持全屏录制模式，最大化录制区域

### 🛡️ 权限管理
- **智能权限请求**：自动请求摄像头、麦克风和存储权限
- **权限状态检测**：实时检测权限状态，确保功能正常
- **友好错误处理**：权限被拒绝时提供清晰的提示信息

## 🏗️ 技术架构

### 开发框架
- **Flutter 3.8.1+**：跨平台移动应用开发框架
- **Dart 语言**：现代化的编程语言，提供出色的性能

### 核心依赖
- **camera: ^0.10.5+9**：摄像头控制和视频录制
- **permission_handler: ^11.3.1**：权限管理
- **path_provider: ^2.1.2**：文件路径管理
- **shared_preferences: ^2.2.2**：本地数据存储
- **screen_brightness: ^0.2.2+1**：屏幕亮度控制
- **package_info_plus: ^4.2.0**：应用信息获取
- **intl: ^0.19.0**：国际化和日期格式化
- **sensors_plus: ^6.0.1**：加速度计和陀螺仪传感器访问，用于增强速度计算精度


### 平台支持
- **Android**：完整功能支持，包括原生视频分割
- **iOS**：基础功能支持（计划中）

## 📱 用户界面

### 主录制界面
- 全屏摄像头预览
- 浮动录制控制按钮
- 实时存储空间显示
- 录制状态指示器
- 智能 UI 自动隐藏


### 文件管理界面
- 清晰的文件列表展示
- 多种排序和显示选项
- 文件详细信息显示
- 便捷的操作菜单

### 设置界面
- 分类清晰的设置选项
- 实时设置预览
- 详细的功能说明
- 应用信息展示

## 🚀 快速开始

### 环境要求
- Flutter SDK 3.8.1 或更高版本
- Dart SDK 3.0.0 或更高版本
- Android Studio 或 VS Code
- Android 设备或模拟器（API 21+）

### 安装步骤

1. **克隆项目**
   ```bash
   git clone <repository-url>
   cd velomemo
   ```

2. **安装依赖**
   ```bash
   flutter pub get
   ```

3. **运行应用**
   ```bash
   flutter run
   ```

### 构建发布版本

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release
```

## 📋 使用说明

### 首次使用
1. 启动应用后，系统会自动请求必要的权限
2. 授予摄像头、麦克风和存储权限
3. 应用会自动检测并配置最佳的摄像头设置

### 开始录制
1. 点击红色录制按钮开始录制
2. 录制过程中会显示红色边框指示
3. 再次点击按钮停止录制
4. 视频文件会自动保存到专用目录

### 查看录制文件
1. 点击文件夹图标进入文件管理
2. 浏览已录制的视频文件
3. 支持播放、分享和删除操作

### 调整设置
1. 点击设置图标进入设置页面
2. 根据需要调整画质和摄像头
3. 设置会自动保存并立即生效

## 🧪 测试

### 测试覆盖
项目包含完整的测试套件，确保代码质量和功能稳定性：

- **单元测试**：50+ 测试用例，覆盖核心业务逻辑
  - 速度计算器测试
  - 视频录制功能测试
  - 视频缩略图管理测试
- **组件测试**：UI 组件功能验证
  - 速度显示组件测试（47个测试用例）
  - 基本 UI 组件测试
- **集成测试**：组件间交互验证

### 快速测试命令

#### 使用测试脚本（推荐）
```bash
# macOS/Linux
./run_tests.sh              # 运行所有测试
./run_tests.sh --unit       # 单元测试
./run_tests.sh --widget     # 组件测试
./run_tests.sh --coverage   # 生成覆盖率报告

# Windows
run_tests.bat -a            # 运行所有测试
run_tests.bat -u            # 单元测试
run_tests.bat -c            # 生成覆盖率报告
```

#### 使用 Makefile（macOS/Linux）
```bash
make test                    # 运行所有测试
make test-unit              # 单元测试
make test-widget            # 组件测试
make test-coverage          # 覆盖率报告
```

#### 直接使用 Flutter 命令
```bash
flutter test                # 运行所有测试
flutter test --coverage     # 生成覆盖率报告
```

## 🎨 图标管理

### 图标特性
- **专业设计**：专为行车记录仪应用设计的图标
- **摄像头主体**：突出的摄像头元素，放大50%以增强视觉效果
- **速度表盘**：集成的速度监控元素
- **录制指示灯**：红色指示灯表达录制功能
- **简洁设计**：移除文字元素，保持图标简洁性

### 快速更新图标

#### 使用图标管理脚本（推荐）
```bash
# 完整更新（生成+应用）
./update_icons.sh

# 仅生成 PNG 图标
./update_icons.sh --generate

# 仅应用到项目
./update_icons.sh --apply

# 查看帮助
./update_icons.sh --help
```

#### 使用 Makefile（macOS/Linux）
```bash
make icon-update            # 完整更新图标
make icon-generate          # 生成 PNG 图标
make icon-apply             # 应用到项目
make icon-help              # 查看帮助
```

### 自定义图标

1. **替换源文件**：
   - 替换 `assets/icons/app_icon.svg`（主图标）
   - 替换 `assets/icons/app_icon_adaptive.svg`（自适应图标）
   - 运行 `./update_icons.sh` 更新

2. **修改配置**：
   - 编辑 `pubspec.yaml` 中的 `flutter_launcher_icons` 配置
   - 运行 `flutter packages pub run flutter_launcher_icons:main`

### 图标文件结构
```
assets/icons/
├── app_icon.svg              # 主图标源文件
├── app_icon.png              # 主图标 PNG
├── app_icon_adaptive.svg     # 自适应图标源文件
├── app_icon_adaptive.png     # 自适应图标 PNG
└── app_icon_foreground.png   # 前景图标 PNG
```

### 开发工具

项目提供了完整的开发工具链：

- **`run_tests.sh`** / **`run_tests.bat`**：跨平台测试脚本
- **`Makefile`**：便捷的开发命令集合
- **`update_icons.sh`**：图标更新和管理脚本
- **`TESTING.md`**：详细的测试指南和最佳实践
- **`ICON_GUIDE.md`**：图标设计指南和更新说明

更多测试相关信息请参阅 [TESTING.md](TESTING.md)。
更多图标相关信息请参阅 [ICON_GUIDE.md](ICON_GUIDE.md)。

## 🔧 开发说明

### 项目结构
```
velomemo/
├── .gitignore              # Git 忽略文件配置
├── .metadata               # Flutter 元数据
├── LICENSE                 # MIT 许可证文件
├── Makefile               # 开发命令集合
├── README.md              # 英文项目说明
├── analysis_options.yaml   # Dart 代码分析配置
├── devtools_options.yaml   # Flutter DevTools 配置
├── pubspec.yaml           # 项目依赖配置
├── pubspec.lock           # 依赖版本锁定文件
├── example_video_segmentation_usage.dart # 视频分割使用示例
│
├── android/               # Android 平台配置
│   ├── app/
│   │   ├── build.gradle.kts
│   │   └── src/
│   ├── build.gradle.kts
│   ├── gradle/
│   ├── gradle.properties
│   ├── gradlew
│   ├── gradlew.bat
│   ├── local.properties
│   └── settings.gradle.kts
│
├── assets/                # 应用资源文件
│   └── icons/             # 应用图标资源
│       ├── app_icon.svg   # 主图标源文件
│       ├── app_icon.png   # 主图标 PNG
│       ├── app_icon_adaptive.svg # 自适应图标源文件
│       ├── app_icon_adaptive.png # 自适应图标 PNG
│       └── app_icon_foreground.png # 前景图标 PNG
│
├── docs/                  # 项目文档
│   ├── BUILD_GUIDE.md     # 构建指南
│   ├── ICON_GUIDE.md      # 图标设计指南
│   ├── README_zh.md       # 中文项目说明
│   └── TESTING.md         # 测试指南
│
├── lib/                   # 主要源代码
│   ├── main.dart          # 应用入口和主录制界面
│   ├── file_list_page.dart # 文件管理页面
│   ├── settings_page.dart  # 设置页面
│   ├── speed_calculator.dart # 速度计算器
│   ├── speed_display_widget.dart # 速度显示组件

│   ├── video_recorder.dart # 视频录制器
│   ├── video_thumbnail_manager.dart # 视频缩略图管理
│   ├── video_thumbnail_widget.dart # 视频缩略图组件
│   └── utils.dart         # 工具函数
│
├── scripts/               # 构建和开发脚本
│   ├── build_apk.bat      # Windows APK 构建脚本
│   ├── build_apk.sh       # macOS/Linux APK 构建脚本
│   ├── run_tests.bat      # Windows 测试脚本
│   ├── run_tests.sh       # macOS/Linux 测试脚本
│   └── update_icons.sh    # 图标更新脚本
│
└── test/                  # 测试文件
    ├── integration_test.dart # 集成测试
    ├── speed_calculator_test.dart # 速度计算器测试
    ├── speed_display_widget_test.dart # 速度显示组件测试
    ├── video_recorder_test.dart # 视频录制器测试
    ├── video_recorder_test.mocks.dart # 视频录制器模拟对象
    ├── video_thumbnail_manager_test.dart # 缩略图管理测试
    ├── video_thumbnail_manager_test.mocks.dart # 缩略图管理模拟对象
    ├── test_utils.dart     # 测试工具函数
    └── widget_test.dart    # 基本组件测试
```

### 关键特性实现
- **视频录制**：使用 Camera 插件实现高质量视频录制
- **文件管理**：自定义文件浏览器，支持多种操作
- **设置持久化**：使用 SharedPreferences 保存用户偏好
- **权限处理**：智能的权限请求和状态管理

- **UI 优化**：响应式设计，适配不同屏幕尺寸
- **测试覆盖**：完整的单元测试、组件测试和集成测试

## 📄 许可证

本项目采用 MIT 许可证，详情请参阅 [LICENSE](LICENSE) 文件。

## 🤝 贡献

欢迎提交 Issue 和 Pull Request 来帮助改进这个项目！

## 📞 联系方式

如有问题或建议，请通过以下方式联系：
- 提交 GitHub Issue
- 发送邮件至项目维护者

---

**VeloMemo** - 让每一次行程都有记录 🚗📹
