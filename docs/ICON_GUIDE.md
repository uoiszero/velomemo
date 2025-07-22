# VeloMemo 图标设计指南

本指南将帮助您自定义 VeloMemo 应用的图标。

## 📱 当前图标

项目已配置了专业的 VeloMemo 图标，包含以下元素：
- 🎥 行车记录仪摄像头
- 📊 速度表盘
- 🚗 汽车轮廓
- 🔴 录制指示灯（带动画效果）
- 🎨 现代化的 Material Design 风格

## 🛠️ 快速更新图标

### 使用更新脚本（推荐）

```bash
# 生成并应用默认图标
./update_icons.sh

# 仅生成图标文件
./update_icons.sh --generate

# 仅应用现有图标
./update_icons.sh --apply

# 查看帮助
./update_icons.sh --help
```

### 手动更新

```bash
# 1. 安装依赖
flutter pub get

# 2. 生成图标
dart run flutter_launcher_icons

# 3. 重新构建应用
flutter clean
flutter build apk
```

## 🎨 自定义图标

### 方法一：替换源文件

1. **准备您的图标文件**：
   - 推荐格式：SVG（矢量格式，可无限缩放）
   - 备选格式：PNG（至少 1024x1024 像素）
   - 文件名：`custom_icon.svg` 或 `custom_icon.png`

2. **放置文件**：
   ```
   assets/icons/
   ├── custom_icon.svg    # 您的自定义图标
   └── ...
   ```

3. **运行更新脚本**：
   ```bash
   ./update_icons.sh
   ```

### 方法二：修改配置文件

1. **编辑 `pubspec.yaml`**：
   ```yaml
   flutter_launcher_icons:
     android: "launcher_icon"
     ios: false
     image_path: "path/to/your/icon.png"  # 修改这里
     min_sdk_android: 21
     adaptive_icon_background: "#YOUR_COLOR"  # 修改背景色
     adaptive_icon_foreground: "path/to/your/foreground.png"
   ```

2. **运行生成命令**：
   ```bash
   dart run flutter_launcher_icons
   ```

## 📐 设计规范

### Android 图标要求

#### 传统图标（Legacy Icon）
- **尺寸**：48dp × 48dp（各种密度）
- **格式**：PNG
- **背景**：可以有背景
- **形状**：任意形状

#### 自适应图标（Adaptive Icon）
- **前景层**：108dp × 108dp，安全区域 72dp × 72dp
- **背景层**：108dp × 108dp，纯色或简单图案
- **格式**：PNG（前景层建议透明背景）
- **兼容性**：Android 8.0 (API 26) 及以上

### 设计建议

1. **保持简洁**：图标应该在小尺寸下仍然清晰可辨
2. **品牌一致性**：使用与应用主题一致的颜色和风格
3. **功能表达**：图标应该能够表达应用的核心功能
4. **测试多种尺寸**：确保图标在不同设备和密度下都显示良好

## 🎯 当前图标设计说明

### 设计元素

- **主色调**：蓝色 (#2196F3) - 代表科技和可靠性
- **摄像头**：深灰色 (#37474F) - 突出录制功能
- **录制指示**：红色 (#F44336) - 清晰的录制状态
- **速度表盘**：白色背景 - 提供清晰的信息显示
- **汽车元素**：灰蓝色 (#607D8B) - 体现行车应用特性

### 文件结构

```
assets/icons/
├── app_icon.svg              # 完整图标设计（带背景）
├── app_icon.png              # 主图标 PNG 版本
├── app_icon_adaptive.svg     # 自适应图标前景设计
└── app_icon_adaptive.png     # 自适应图标前景 PNG
```

## 🔧 故障排除

### 常见问题

1. **图标没有更新**
   - 卸载应用后重新安装
   - 清理构建缓存：`flutter clean`
   - 重新构建：`flutter build apk`

2. **ImageMagick 未安装**
   ```bash
   # macOS
   brew install imagemagick
   
   # Ubuntu/Debian
   sudo apt-get install imagemagick
   ```

3. **权限错误**
   ```bash
   chmod +x update_icons.sh
   ```

4. **图标模糊或失真**
   - 确保源图标至少 1024x1024 像素
   - 使用 SVG 格式获得最佳质量
   - 检查图标设计是否适合小尺寸显示

### 调试命令

```bash
# 检查生成的图标文件
ls -la android/app/src/main/res/mipmap-*/

# 查看图标配置
cat android/app/src/main/res/mipmap-anydpi-v26/launcher_icon.xml

# 检查颜色配置
cat android/app/src/main/res/values/colors.xml
```

## 📚 参考资源

- [Android 图标设计指南](https://developer.android.com/guide/practices/ui_guidelines/icon_design)
- [Material Design 图标](https://material.io/design/iconography/)
- [Flutter Launcher Icons 插件](https://pub.dev/packages/flutter_launcher_icons)
- [自适应图标设计](https://developer.android.com/guide/practices/ui_guidelines/icon_design_adaptive)

## 💡 提示

- 定期备份您的自定义图标文件
- 在不同设备上测试图标显示效果
- 考虑为不同的应用版本（开发版、测试版、正式版）使用不同的图标
- 遵循平台设计规范以获得最佳用户体验