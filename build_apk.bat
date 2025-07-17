@echo off
REM VeloMemo APK 打包脚本 (Windows版本)
REM 作者: Assistant
REM 用途: 自动化构建 Android APK 文件

setlocal enabledelayedexpansion

REM 设置变量
set "BUILD_MODE=debug"
set "SHOULD_CLEAN=false"
set "SHOULD_GET_DEPS=true"

REM 解析命令行参数
:parse_args
if "%~1"=="" goto start_build
if "%~1"=="-h" goto show_help
if "%~1"=="--help" goto show_help
if "%~1"=="-c" (
    set "SHOULD_CLEAN=true"
    shift
    goto parse_args
)
if "%~1"=="--clean" (
    set "SHOULD_CLEAN=true"
    shift
    goto parse_args
)
if "%~1"=="--no-deps" (
    set "SHOULD_GET_DEPS=false"
    shift
    goto parse_args
)
if "%~1"=="debug" (
    set "BUILD_MODE=debug"
    shift
    goto parse_args
)
if "%~1"=="profile" (
    set "BUILD_MODE=profile"
    shift
    goto parse_args
)
if "%~1"=="release" (
    set "BUILD_MODE=release"
    shift
    goto parse_args
)
echo [ERROR] 未知参数: %~1
goto show_help

:show_help
echo VeloMemo APK 打包脚本 (Windows版本)
echo.
echo 用法: %~nx0 [选项] [构建模式]
echo.
echo 构建模式:
echo   debug    - 构建调试版本 APK (默认)
echo   profile  - 构建性能分析版本 APK
echo   release  - 构建发布版本 APK
echo.
echo 选项:
echo   -h, --help     显示此帮助信息
echo   -c, --clean    构建前清理项目
echo   --no-deps      跳过依赖获取步骤
echo.
echo 示例:
echo   %~nx0                    # 构建 debug APK
echo   %~nx0 release            # 构建 release APK
echo   %~nx0 -c release         # 清理后构建 release APK
echo   %~nx0 --no-deps debug   # 跳过依赖获取，构建 debug APK
goto end

:start_build
echo [INFO] 开始构建 VeloMemo APK...
echo [INFO] 构建模式: %BUILD_MODE%

REM 检查Flutter是否安装
flutter --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Flutter 未安装或未添加到 PATH 中
    goto error_exit
)
echo [INFO] Flutter 已安装

REM 清理项目（如果需要）
if "%SHOULD_CLEAN%"=="true" (
    echo [INFO] 清理项目...
    flutter clean
    if errorlevel 1 (
        echo [ERROR] 项目清理失败
        goto error_exit
    )
    echo [SUCCESS] 项目清理完成
)

REM 获取依赖（如果需要）
if "%SHOULD_GET_DEPS%"=="true" (
    echo [INFO] 获取项目依赖...
    flutter pub get
    if errorlevel 1 (
        echo [ERROR] 依赖获取失败
        goto error_exit
    )
    echo [SUCCESS] 依赖获取完成
)

REM 构建APK
echo [INFO] 开始构建 %BUILD_MODE% APK...

if "%BUILD_MODE%"=="debug" (
    flutter build apk --debug
    set "APK_FILE=build\app\outputs\flutter-apk\app-debug.apk"
) else if "%BUILD_MODE%"=="profile" (
    flutter build apk --profile
    set "APK_FILE=build\app\outputs\flutter-apk\app-profile.apk"
) else if "%BUILD_MODE%"=="release" (
    flutter build apk --release
    set "APK_FILE=build\app\outputs\flutter-apk\app-release.apk"
) else (
    echo [ERROR] 无效的构建模式: %BUILD_MODE%
    goto error_exit
)

if errorlevel 1 (
    echo [ERROR] APK 构建失败
    goto error_exit
)

REM 检查APK文件是否存在
if not exist "%APK_FILE%" (
    echo [ERROR] APK 文件未找到: %APK_FILE%
    goto error_exit
)

REM 复制到项目根目录
set "OUTPUT_NAME=velomemo-%BUILD_MODE%.apk"
copy "%APK_FILE%" "%OUTPUT_NAME%" >nul
if errorlevel 1 (
    echo [ERROR] 复制APK文件失败
    goto error_exit
)

echo [SUCCESS] APK 构建完成!
echo [INFO] 文件位置: %APK_FILE%
echo [SUCCESS] APK 已复制到项目根目录: %OUTPUT_NAME%
echo [SUCCESS] 所有操作完成!
goto end

:error_exit
echo [ERROR] 构建过程中发生错误
exit /b 1

:end
endlocal