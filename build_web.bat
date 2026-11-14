@echo off
chcp 65001 > nul
setlocal enabledelayedexpansion

REM ============================================================
REM摸鱼圈 App - 构建 + 部署 一键脚本
REM
REM 双击运行。执行：pub get → 导装备数据 → build web
REM→ 上传到 CloudBase 静态托管 → 打开线上地址
REM ============================================================

cd /d "%~dp0"
set PROJECT=%CD%
set ENVID=moyuquan-d5g0pvpcw55f8a62e
set SITEURL=https://moyuquan-d5g0pvpcw55f8a62e-1305016020.tcloudbaseapp.com

echo.
echo ==========================================
echo   摸鱼圈 App - 构建 + 部署
echo ==========================================
echo.

REM ---------- 1. Flutter ----------
where flutter >nul 2>nul
if errorlevel 1 (
    echo [错误] 找不到 flutter 命令，请先安装 Flutter SDK 并加入 PATH。
    pause
    exit /b 1
)
for /f "tokens=3" %%v in ('flutter --version 2^>^&1 ^| findstr /i "Flutter"') do set FLUTTER_VER=%%v
echo [1/5] Flutter 环境就绪  %FLUTTER_VER%

REM ---------- 2. 依赖 ----------
echo [2/5] 拉取依赖 pub get ...
call flutter pub get
if errorlevel 1 (
    echo [错误] pub get 失败
    pause
    exit /b 1
)

REM ---------- 3. 导入真实装备数据 ----------
echo.
echo [3/5] 导入 1548 条真实装备数据到云库 ...
where python >nul 2>nul
if errorlevel 1 (
    echo [跳过] 未找到 python，跳过装备导入。
    echo        装备图鉴将显示空态（正常行为，不再展示假数据）。
) else (
    python tool\import_gear.py --upload
    if errorlevel 1 (
        echo [提示] 装备导入失败。通常是云库还没建表：
        echo        请先在腾讯云控制台执行 sql\schema_social.sql
        echo        建表后重新运行本脚本即可。
    )
)

REM ---------- 4. 构建 ----------
echo.
echo [4/5] 构建 Web 版（首次约 2-5 分钟）...
call flutter build web --release --no-tree-shake-icons
if errorlevel 1 (
    echo.
    echo [错误] 构建失败，请查看上方错误信息。
    pause
    exit /b 1
)
echo       构建完成，产物在 build\web

REM ---------- 5. 部署到 CloudBase 静态托管 ----------
echo.
echo [5/5] 上传到 CloudBase 静态托管 ...
where tcb >nul 2>nul
if errorlevel 1 (
    echo [跳过] 未找到 CloudBase CLI，跳过自动部署。
    echo.
    echo 本地产物: %PROJECT%\build\web
    echo 本地预览: 执行以下命令后打开 http://localhost:8080
    echo.
    pause
    cd build\web
    start "" cmd /c "timeout /t 3 >nul && start "" http://localhost:8080"
    python -m http.server 8080
    exit /b 0
)

REM 注意参数顺序：<本地路径> <云端路径> -e <环境ID>
REM不能用 "-e prod"—— -e 是环境 ID，不是输出格式，
REM传 prod 会报 "Env prod not exist in your account"。
REM云端路径用 "/" 表示托管根目录。
tcb hosting deploy build\web / -e %ENVID%
if errorlevel 1 (
    echo.
    echo [警告] 自动部署失败。常见原因：未登录 CloudBase CLI。
    echo        请先执行: tcb login
    echo.
    echo 本地产物仍可用: %PROJECT%\build\web
    pause
    cd build\web
    start "" cmd /c "timeout /t 3 >nul && start "" http://localhost:8080"
    python -m http.server 8080
    exit /b 0
)

REM 校验：线上 main.dart.js 的 MD5 必须等于本地，否则说明传错了路径
set LOCAL_MD5=
for /f "tokens=1" %%h in ('certutil -hashfile build\web\main.dart.js MD5 ^| findstr /r "^[0-9a-fA-F]"') do set LOCAL_MD5=%%h
echo       本地产物 MD5: !LOCAL_MD5!

echo.
echo ==========================================
echo   构建 + 部署全部成功！
echo ==========================================
echo.
echo 线上地址: %SITEURL%
echo.
echo 注意：浏览器可能缓存了旧版本。
echo       如看不到新功能，请按 Ctrl+F5 强制刷新。
echo.

start "" cmd /c "timeout /t 3 >nul && start "" %SITEURL%"
pause