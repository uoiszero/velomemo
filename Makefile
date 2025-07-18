# VeloMemo Makefile
# 提供便捷的开发和测试命令

.PHONY: help test test-all test-unit test-widget test-integration test-coverage clean build install deps doctor

# 默认目标
help:
	@echo "VeloMemo 开发工具"
	@echo "=================="
	@echo ""
	@echo "测试命令:"
	@echo "  make test              - 运行所有测试"
	@echo "  make test-unit         - 运行单元测试"
	@echo "  make test-widget       - 运行组件测试"
	@echo "  make test-integration  - 运行集成测试"
	@echo "  make test-coverage     - 生成测试覆盖率报告"
	@echo ""
	@echo "构建命令:"
	@echo "  make build             - 构建应用"
	@echo "  make build-apk         - 构建 APK"
	@echo "  make build-ios         - 构建 iOS 应用"
	@echo ""
	@echo "安装和运行:"
	@echo "  make install           - 安装到设备"
	@echo "  make run               - 运行应用"
	@echo "  make run-release       - 运行发布版本"
	@echo ""
	@echo "依赖管理:"
	@echo "  make deps              - 获取依赖"
	@echo "  make upgrade           - 升级依赖"
	@echo ""
	@echo "代码质量:"
	@echo "  make format            - 格式化代码"
	@echo "  make analyze           - 分析代码"
	@echo "  make lint              - 代码检查"
	@echo ""
	@echo "图标管理:"
	@echo "  make icon-update       - 更新应用图标"
	@echo "  make icon-generate     - 生成图标文件"
	@echo "  make icon-apply        - 应用图标"
	@echo "  make icon-help         - 图标帮助"
	@echo ""
	@echo "清理:"
	@echo "  make clean             - 清理构建文件"
	@echo ""
	@echo "环境:"
	@echo "  make doctor            - 检查 Flutter 环境"
	@echo ""
	@echo "开发工具:"
	@echo "  make dev-tools         - 安装开发工具"
	@echo "  make devtools          - 启动 DevTools"

# 测试相关命令
test: test-all

test-all:
	@echo "🧪 运行所有测试..."
	./run_tests.sh --all

test-unit:
	@echo "🔬 运行单元测试..."
	./run_tests.sh --unit

test-widget:
	@echo "🎨 运行组件测试..."
	./run_tests.sh --widget

test-integration:
	@echo "🔗 运行集成测试..."
	./run_tests.sh --integration

test-coverage:
	@echo "📊 运行测试并生成覆盖率报告..."
	./run_tests.sh --coverage

# 构建相关命令
build:
	@echo "🔨 构建应用..."
	flutter build

build-apk:
	@echo "📱 构建 Android APK..."
	flutter build apk --release

build-ios:
	@echo "🍎 构建 iOS 应用..."
	flutter build ios --release

# 安装和运行
install:
	@echo "📲 安装到设备..."
	flutter install

run:
	@echo "🚀 运行应用..."
	flutter run

run-release:
	@echo "🚀 运行发布版本..."
	flutter run --release

# 依赖管理
deps:
	@echo "📦 获取依赖..."
	flutter pub get

upgrade:
	@echo "⬆️ 升级依赖..."
	flutter pub upgrade

# 代码质量
format:
	@echo "✨ 格式化代码..."
	dart format .

analyze:
	@echo "🔍 分析代码..."
	flutter analyze

lint: analyze

# 清理
clean:
	@echo "🧹 清理构建文件..."
	flutter clean
	flutter pub get

# 环境检查
doctor:
	@echo "🩺 检查 Flutter 环境..."
	flutter doctor -v

# 开发工具
devtools:
	@echo "🛠️ 启动 Flutter DevTools..."
	flutter pub global run devtools

dev-tools:
	@echo "🛠️ 安装开发工具..."
	flutter pub global activate flutter_launcher_icons
	flutter pub global activate build_runner

# 图标管理
icon-update:
	@echo "🎨 更新应用图标..."
	./update_icons.sh

icon-generate:
	@echo "🎯 生成图标文件..."
	./update_icons.sh --generate

icon-apply:
	@echo "🚀 应用图标..."
	./update_icons.sh --apply

icon-help:
	@echo "📖 显示图标帮助..."
	./update_icons.sh --help

# 生成代码
generate:
	@echo "⚙️ 生成代码..."
	flutter packages pub run build_runner build

generate-watch:
	@echo "👀 监听并生成代码..."
	flutter packages pub run build_runner watch

# 完整的开发流程
dev-setup: clean deps doctor
	@echo "✅ 开发环境设置完成"

ci: deps analyze test
	@echo "✅ CI 流程完成"

# 发布准备
release-check: clean deps analyze test build-apk
	@echo "✅ 发布检查完成"