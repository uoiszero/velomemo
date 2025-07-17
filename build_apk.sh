#!/bin/bash

# VeloMemo APK 打包脚本
# 作者: Assistant
# 用途: 自动化构建 Android APK 文件

set -e  # 遇到错误时退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查Flutter是否安装
check_flutter() {
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter 未安装或未添加到 PATH 中"
        exit 1
    fi
    print_info "Flutter 版本: $(flutter --version | head -n 1)"
}

# 清理项目
clean_project() {
    print_info "清理项目..."
    flutter clean
    print_success "项目清理完成"
}

# 获取依赖
get_dependencies() {
    print_info "获取项目依赖..."
    flutter pub get
    print_success "依赖获取完成"
}

# 构建APK
build_apk() {
    local build_mode=$1
    local output_dir="build/app/outputs/flutter-apk"
    
    print_info "开始构建 ${build_mode} APK..."
    
    case $build_mode in
        "debug")
            flutter build apk --debug
            local apk_file="${output_dir}/app-debug.apk"
            ;;
        "profile")
            flutter build apk --profile
            local apk_file="${output_dir}/app-profile.apk"
            ;;
        "release")
            flutter build apk --release
            local apk_file="${output_dir}/app-release.apk"
            ;;
        *)
            print_error "无效的构建模式: $build_mode"
            exit 1
            ;;
    esac
    
    if [ -f "$apk_file" ]; then
        local file_size=$(du -h "$apk_file" | cut -f1)
        print_success "APK 构建完成!"
        print_info "文件位置: $apk_file"
        print_info "文件大小: $file_size"
        
        # 复制到项目根目录
        local output_name="velomemo-${build_mode}.apk"
        cp "$apk_file" "$output_name"
        print_success "APK 已复制到项目根目录: $output_name"
    else
        print_error "APK 构建失败"
        exit 1
    fi
}

# 显示帮助信息
show_help() {
    echo "VeloMemo APK 打包脚本"
    echo ""
    echo "用法: $0 [选项] [构建模式]"
    echo ""
    echo "构建模式:"
    echo "  debug    - 构建调试版本 APK (默认)"
    echo "  profile  - 构建性能分析版本 APK"
    echo "  release  - 构建发布版本 APK"
    echo ""
    echo "选项:"
    echo "  -h, --help     显示此帮助信息"
    echo "  -c, --clean    构建前清理项目"
    echo "  --no-deps      跳过依赖获取步骤"
    echo ""
    echo "示例:"
    echo "  $0                    # 构建 debug APK"
    echo "  $0 release            # 构建 release APK"
    echo "  $0 -c release         # 清理后构建 release APK"
    echo "  $0 --no-deps debug   # 跳过依赖获取，构建 debug APK"
}

# 主函数
main() {
    local build_mode="debug"
    local should_clean=false
    local should_get_deps=true
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -c|--clean)
                should_clean=true
                shift
                ;;
            --no-deps)
                should_get_deps=false
                shift
                ;;
            debug|profile|release)
                build_mode=$1
                shift
                ;;
            *)
                print_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    print_info "开始构建 VeloMemo APK..."
    print_info "构建模式: $build_mode"
    
    # 检查Flutter环境
    check_flutter
    
    # 清理项目（如果需要）
    if [ "$should_clean" = true ]; then
        clean_project
    fi
    
    # 获取依赖（如果需要）
    if [ "$should_get_deps" = true ]; then
        get_dependencies
    fi
    
    # 构建APK
    build_apk "$build_mode"
    
    print_success "所有操作完成!"
}

# 运行主函数
main "$@"