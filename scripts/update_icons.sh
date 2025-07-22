#!/bin/bash

# VeloMemo 图标更新脚本
# 用于快速更新应用图标

set -e

echo "🎨 VeloMemo 图标更新工具"
echo "================================"

# 检查必要的工具
if ! command -v magick &> /dev/null; then
    echo "❌ 错误: 需要安装 ImageMagick"
    echo "   请运行: brew install imagemagick"
    exit 1
fi

if ! command -v flutter &> /dev/null; then
    echo "❌ 错误: 需要安装 Flutter SDK"
    exit 1
fi

# 创建图标目录
mkdir -p assets/icons

# 函数：生成默认图标
generate_default_icon() {
    echo "🎯 生成默认 VeloMemo 图标..."
    
    # 检查是否存在自定义图标源文件
    if [ -f "assets/icons/custom_icon.svg" ]; then
        echo "📁 发现自定义图标: custom_icon.svg"
        SOURCE_ICON="assets/icons/custom_icon.svg"
    elif [ -f "assets/icons/custom_icon.png" ]; then
        echo "📁 发现自定义图标: custom_icon.png"
        SOURCE_ICON="assets/icons/custom_icon.png"
    else
        echo "📁 使用默认图标设计"
        SOURCE_ICON="assets/icons/app_icon.svg"
    fi
    
    # 生成主图标
    echo "🔄 转换主图标..."
    magick "$SOURCE_ICON" -resize 1024x1024 assets/icons/app_icon.png
    
    # 生成 Adaptive Icon 前景
    echo "🔄 转换 Adaptive Icon 前景..."
    if [ -f "assets/icons/app_icon_adaptive.svg" ]; then
        magick assets/icons/app_icon_adaptive.svg -background transparent -resize 1024x1024 assets/icons/app_icon_adaptive.png
    else
        # 如果没有专门的 adaptive 图标，使用主图标
        cp assets/icons/app_icon.png assets/icons/app_icon_adaptive.png
    fi
}

# 函数：应用图标
apply_icons() {
    echo "🚀 应用图标到项目..."
    
    # 获取依赖
    echo "📦 更新依赖..."
    flutter pub get
    
    # 生成启动器图标
    echo "🎨 生成启动器图标..."
    dart run flutter_launcher_icons
    
    echo "✅ 图标更新完成！"
    echo ""
    echo "📱 新图标已应用到:"
    echo "   • Android 应用图标"
    echo "   • Android Adaptive 图标"
    echo ""
    echo "💡 提示:"
    echo "   • 运行 'flutter clean && flutter build apk' 重新构建应用"
    echo "   • 卸载并重新安装应用以查看新图标"
}

# 函数：显示帮助
show_help() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help     显示此帮助信息"
    echo "  -g, --generate 仅生成图标文件，不应用"
    echo "  -a, --apply    仅应用现有图标文件"
    echo "  (无参数)       生成并应用图标"
    echo ""
    echo "自定义图标:"
    echo "  将您的图标文件放在 assets/icons/ 目录下:"
    echo "  • custom_icon.svg (推荐，矢量格式)"
    echo "  • custom_icon.png (至少 1024x1024 像素)"
    echo ""
    echo "示例:"
    echo "  $0                # 生成并应用默认图标"
    echo "  $0 --generate     # 仅生成图标文件"
    echo "  $0 --apply        # 仅应用现有图标"
}

# 解析命令行参数
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    -g|--generate)
        generate_default_icon
        echo "✅ 图标文件生成完成！"
        echo "💡 运行 '$0 --apply' 来应用图标"
        ;;
    -a|--apply)
        apply_icons
        ;;
    "")
        generate_default_icon
        apply_icons
        ;;
    *)
        echo "❌ 未知选项: $1"
        echo "运行 '$0 --help' 查看帮助"
        exit 1
        ;;
esac