@echo off
REM VeloMemo 测试运行脚本 (Windows版本)
REM 提供多种测试运行选项，方便开发者快速执行测试

setlocal enabledelayedexpansion

REM 设置颜色代码
set "RED=[91m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "NC=[0m"

REM 打印带颜色的消息函数
:print_info
echo %BLUE%[INFO]%NC% %~1
goto :eof

:print_success
echo %GREEN%[SUCCESS]%NC% %~1
goto :eof

:print_warning
echo %YELLOW%[WARNING]%NC% %~1
goto :eof

:print_error
echo %RED%[ERROR]%NC% %~1
goto :eof

REM 显示帮助信息
:show_help
echo VeloMemo 测试运行脚本 (Windows版本)
echo.
echo 用法: %~nx0 [选项]
echo.
echo 选项:
echo   -a, --all           运行所有测试
echo   -u, --unit          运行单元测试
echo   -w, --widget        运行组件测试
echo   -i, --integration   运行集成测试
echo   -c, --coverage      运行测试并生成覆盖率报告
echo   -h, --help          显示此帮助信息
echo.
echo 示例:
echo   %~nx0 -a               # 运行所有测试
echo   %~nx0 -u               # 只运行单元测试
echo   %~nx0 -c               # 运行测试并生成覆盖率报告
goto :eof

REM 检查Flutter环境
:check_flutter
flutter --version >nul 2>&1
if errorlevel 1 (
    call :print_error "Flutter 未安装或不在 PATH 中"
    exit /b 1
)
call :print_info "检查 Flutter 环境..."
goto :eof

REM 运行所有测试
:run_all_tests
call :print_info "运行所有测试..."
flutter test
if errorlevel 1 (
    call :print_error "测试失败！"
    exit /b 1
) else (
    call :print_success "所有测试通过！"
)
goto :eof

REM 运行单元测试
:run_unit_tests
call :print_info "运行单元测试..."

set "unit_tests=../test/speed_calculator_test.dart ../test/video_recorder_test.dart ../test/video_thumbnail_manager_test.dart"

for %%t in (%unit_tests%) do (
    if exist "%%t" (
        call :print_info "运行 %%t"
        flutter test "%%t"
        if errorlevel 1 (
            call :print_error "%%t 测试失败！"
            exit /b 1
        )
    ) else (
        call :print_warning "测试文件 %%t 不存在"
    )
)

call :print_success "单元测试全部通过！"
goto :eof

REM 运行组件测试
:run_widget_tests
call :print_info "运行组件测试..."

set "widget_tests=../test/speed_display_widget_test.dart ../test/widget_test.dart"

for %%t in (%widget_tests%) do (
    if exist "%%t" (
        call :print_info "运行 %%t"
        flutter test "%%t"
        if errorlevel 1 (
            call :print_error "%%t 测试失败！"
            exit /b 1
        )
    ) else (
        call :print_warning "测试文件 %%t 不存在"
    )
)

call :print_success "组件测试全部通过！"
goto :eof

REM 运行集成测试
:run_integration_tests
call :print_info "运行集成测试..."

if exist "../test/integration_test.dart" (
    flutter test ../test/integration_test.dart
    if errorlevel 1 (
        call :print_error "集成测试失败！"
        exit /b 1
    ) else (
        call :print_success "集成测试通过！"
    )
) else (
    call :print_warning "集成测试文件不存在"
)
goto :eof

REM 运行测试并生成覆盖率报告
:run_coverage
call :print_info "运行测试并生成覆盖率报告..."

REM 运行测试并生成覆盖率
flutter test --coverage

if errorlevel 1 (
    call :print_error "测试失败！"
    exit /b 1
) else (
    call :print_success "测试完成，覆盖率文件已生成: coverage/lcov.info"
    call :print_info "要生成 HTML 报告，请安装 lcov 或使用在线工具查看 lcov.info 文件"
)
goto :eof

REM 主函数
:main
REM 检查是否在项目根目录
if not exist "..\pubspec.yaml" (
    call :print_error "请在 Flutter 项目根目录下运行此脚本"
    exit /b 1
)

REM 检查 Flutter 环境
call :check_flutter
if errorlevel 1 exit /b 1

REM 解析命令行参数
if "%~1"=="" (
    call :print_info "未指定参数，运行所有测试..."
    call :run_all_tests
) else if "%~1"=="-a" (
    call :run_all_tests
) else if "%~1"=="--all" (
    call :run_all_tests
) else if "%~1"=="-u" (
    call :run_unit_tests
) else if "%~1"=="--unit" (
    call :run_unit_tests
) else if "%~1"=="-w" (
    call :run_widget_tests
) else if "%~1"=="--widget" (
    call :run_widget_tests
) else if "%~1"=="-i" (
    call :run_integration_tests
) else if "%~1"=="--integration" (
    call :run_integration_tests
) else if "%~1"=="-c" (
    call :run_coverage
) else if "%~1"=="--coverage" (
    call :run_coverage
) else if "%~1"=="-h" (
    call :show_help
) else if "%~1"=="--help" (
    call :show_help
) else (
    call :print_error "未知参数: %~1"
    call :show_help
    exit /b 1
)

goto :eof

REM 运行主函数
call :main %*