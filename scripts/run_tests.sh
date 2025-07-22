#!/bin/bash

# VeloMemo 测试运行脚本
# 提供多种测试运行选项，方便开发者快速执行测试

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

# 显示帮助信息
show_help() {
    echo "VeloMemo 测试运行脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -a, --all           运行所有测试"
    echo "  -u, --unit          运行单元测试"
    echo "  -w, --widget        运行组件测试"
    echo "  -i, --integration   运行集成测试"
    echo "  -c, --coverage      运行测试并生成覆盖率报告"
    echo "  -v, --verbose       详细输出"
    echo "  -h, --help          显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 -a               # 运行所有测试"
    echo "  $0 -u               # 只运行单元测试"
    echo "  $0 -c               # 运行测试并生成覆盖率报告"
}

# 检查Flutter环境
check_flutter() {
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter 未安装或不在 PATH 中"
        exit 1
    fi
    
    print_info "检查 Flutter 环境..."
    flutter doctor --android-licenses > /dev/null 2>&1 || true
}

# 运行所有测试
run_all_tests() {
    print_info "运行所有测试..."
    flutter test
    if [ $? -eq 0 ]; then
        print_success "所有测试通过！"
    else
        print_error "测试失败！"
        exit 1
    fi
}

# 运行单元测试
run_unit_tests() {
    print_info "运行单元测试..."
    
    local unit_tests=(
        "../test/speed_calculator_test.dart"
        "../test/video_recorder_test.dart"
        "../test/video_thumbnail_manager_test.dart"
    )
    
    for test in "${unit_tests[@]}"; do
        if [ -f "$test" ]; then
            print_info "运行 $test"
            flutter test "$test"
            if [ $? -ne 0 ]; then
                print_error "$test 测试失败！"
                exit 1
            fi
        else
            print_warning "测试文件 $test 不存在"
        fi
    done
    
    print_success "单元测试全部通过！"
}

# 运行组件测试
run_widget_tests() {
    print_info "运行组件测试..."
    
    local widget_tests=(
        "../test/speed_display_widget_test.dart"
        "../test/widget_test.dart"
    )
    
    for test in "${widget_tests[@]}"; do
        if [ -f "$test" ]; then
            print_info "运行 $test"
            flutter test "$test"
            if [ $? -ne 0 ]; then
                print_error "$test 测试失败！"
                exit 1
            fi
        else
            print_warning "测试文件 $test 不存在"
        fi
    done
    
    print_success "组件测试全部通过！"
}

# 运行集成测试
run_integration_tests() {
    print_info "运行集成测试..."
    
    if [ -f "../test/integration_test.dart" ]; then
        flutter test ../test/integration_test.dart
        if [ $? -eq 0 ]; then
            print_success "集成测试通过！"
        else
            print_error "集成测试失败！"
            exit 1
        fi
    else
        print_warning "集成测试文件不存在"
    fi
}

# 运行测试并生成覆盖率报告
run_coverage() {
    print_info "运行测试并生成覆盖率报告..."
    
    # 检查是否安装了 lcov
    if ! command -v lcov &> /dev/null; then
        print_warning "lcov 未安装，将只生成 coverage/lcov.info 文件"
        print_info "要生成 HTML 报告，请安装 lcov: brew install lcov (macOS)"
    fi
    
    # 运行测试并生成覆盖率
    flutter test --coverage
    
    if [ $? -eq 0 ]; then
        print_success "测试完成，覆盖率文件已生成: coverage/lcov.info"
        
        # 如果安装了 lcov，生成 HTML 报告
        if command -v lcov &> /dev/null; then
            print_info "生成 HTML 覆盖率报告..."
            genhtml coverage/lcov.info -o coverage/html
            print_success "HTML 覆盖率报告已生成: coverage/html/index.html"
            
            # 在 macOS 上自动打开报告
            if [[ "$OSTYPE" == "darwin"* ]]; then
                open coverage/html/index.html
            fi
        fi
    else
        print_error "测试失败！"
        exit 1
    fi
}

# 主函数
main() {
    # 检查是否在项目根目录
    if [ ! -f "../pubspec.yaml" ]; then
        print_error "请在 Flutter 项目根目录下运行此脚本"
        exit 1
    fi
    
    # 检查 Flutter 环境
    check_flutter
    
    # 解析命令行参数
    case "${1:-}" in
        -a|--all)
            run_all_tests
            ;;
        -u|--unit)
            run_unit_tests
            ;;
        -w|--widget)
            run_widget_tests
            ;;
        -i|--integration)
            run_integration_tests
            ;;
        -c|--coverage)
            run_coverage
            ;;
        -h|--help)
            show_help
            ;;
        "")
            print_info "未指定参数，运行所有测试..."
            run_all_tests
            ;;
        *)
            print_error "未知参数: $1"
            show_help
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"