# VeloMemo APK 构建指南

本项目提供了自动化的APK构建脚本，支持macOS/Linux和Windows平台。

## 快速开始

### macOS/Linux 用户

```bash
# 构建调试版本APK（默认）
./build_apk.sh

# 构建发布版本APK
./build_apk.sh release

# 清理后构建发布版本APK
./build_apk.sh -c release
```

### Windows 用户

```cmd
REM 构建调试版本APK（默认）
build_apk.bat

REM 构建发布版本APK
build_apk.bat release

REM 清理后构建发布版本APK
build_apk.bat -c release
```

## 构建模式说明

| 模式 | 说明 | 用途 |
|------|------|------|
| `debug` | 调试版本 | 开发测试，包含调试信息，文件较大 |
| `profile` | 性能分析版本 | 性能测试，优化但保留分析工具 |
| `release` | 发布版本 | 生产环境，完全优化，文件最小 |

## 脚本选项

### 通用选项

- `-h, --help`: 显示帮助信息
- `-c, --clean`: 构建前清理项目
- `--no-deps`: 跳过依赖获取步骤

### 使用示例

```bash
# macOS/Linux
./build_apk.sh --help                    # 查看帮助
./build_apk.sh debug                     # 构建调试版本
./build_apk.sh release                   # 构建发布版本
./build_apk.sh -c profile                # 清理后构建性能分析版本
./build_apk.sh --no-deps release         # 跳过依赖获取，直接构建发布版本
```

```cmd
REM Windows
build_apk.bat --help                     REM 查看帮助
build_apk.bat debug                      REM 构建调试版本
build_apk.bat release                    REM 构建发布版本
build_apk.bat -c profile                 REM 清理后构建性能分析版本
build_apk.bat --no-deps release          REM 跳过依赖获取，直接构建发布版本
```

## 输出文件

构建完成后，APK文件会保存在以下位置：

1. **Flutter默认位置**: `build/app/outputs/flutter-apk/`
2. **项目根目录**: `velomemo-{模式}.apk`（脚本自动复制）

例如：
- `velomemo-debug.apk`
- `velomemo-profile.apk`
- `velomemo-release.apk`

## 前置要求

### 必需环境

1. **Flutter SDK**: 确保已安装并添加到PATH
2. **Android SDK**: 通过Android Studio或命令行工具安装
3. **Java JDK**: 版本8或更高

### 验证环境

```bash
# 检查Flutter环境
flutter doctor

# 检查可用设备
flutter devices

# 检查Android许可证
flutter doctor --android-licenses
```

## 常见问题

### 1. 权限错误（macOS/Linux）

```bash
# 给脚本添加执行权限
chmod +x build_apk.sh
```

### 2. Flutter未找到

确保Flutter已正确安装并添加到PATH：

```bash
# 检查Flutter是否在PATH中
which flutter

# 如果未找到，添加到PATH（示例）
export PATH="$PATH:/path/to/flutter/bin"
```

### 3. Android SDK问题

```bash
# 检查Android SDK配置
flutter doctor -v

# 接受Android许可证
flutter doctor --android-licenses
```

### 4. 构建失败

```bash
# 清理项目后重试
flutter clean
flutter pub get
flutter build apk --release
```

### 5. 依赖问题

```bash
# 更新依赖
flutter pub upgrade

# 重新获取依赖
flutter pub get
```

## 手动构建（备选方案）

如果脚本无法正常工作，可以手动执行以下命令：

```bash
# 1. 清理项目
flutter clean

# 2. 获取依赖
flutter pub get

# 3. 构建APK
flutter build apk --release  # 发布版本
# 或
flutter build apk --debug    # 调试版本
```

## 签名配置（发布版本）

对于正式发布，需要配置APK签名：

1. 创建密钥库文件
2. 在`android/app/build.gradle`中配置签名
3. 创建`android/key.properties`文件

详细步骤请参考[Flutter官方文档](https://docs.flutter.dev/deployment/android#signing-the-app)。

## 技术支持

如果遇到问题，请检查：

1. Flutter环境是否正确配置（`flutter doctor`）
2. Android SDK是否正确安装
3. 项目依赖是否完整（`flutter pub get`）
4. 是否有足够的磁盘空间

---

**注意**: 首次构建可能需要较长时间，因为需要下载Gradle和其他依赖。后续构建会更快。