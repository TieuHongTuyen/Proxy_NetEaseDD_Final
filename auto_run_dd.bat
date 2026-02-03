@echo off
chcp 65001 >nul
title DD Auto Launcher - Khởi động tự động

echo ========================================
echo      DD AUTO LAUNCHER
echo ========================================
echo.

REM Lưu thư mục hiện tại
set "SCRIPT_DIR=%~dp0"
set "DD_PATH=D:\NetEaseDD\Start.exe"

REM Kiểm tra phần mềm DD có tồn tại không
if not exist "%DD_PATH%" (
    echo [ERROR] Không tìm thấy phần mềm DD tại: %DD_PATH%
    echo.
    echo Vui lòng kiểm tra đường dẫn trong file auto_run_dd.bat
    echo.
    pause
    exit /b 1
)

REM Bước 1: Kiểm tra proxy đã chạy chưa
echo [1/4] Kiểm tra proxy...
netstat -ano | findstr ":8888" | findstr "LISTENING" >nul 2>&1
if %errorLevel% equ 0 (
    echo [OK] Proxy đã đang chạy
    set PROXY_ALREADY_RUNNING=1
    goto step2
)

echo [INFO] Proxy chưa chạy, đang khởi động...
set PROXY_ALREADY_RUNNING=0

REM Bước 1a: Dọn dẹp các tiến trình proxy cũ nếu có (để tránh xung đột)
echo Đang dọn dẹp tiến trình cũ...
for /f "tokens=2" %%a in ('tasklist /FI "IMAGENAME eq pythonw.exe" /NH /FO TABLE 2^>nul ^| findstr /I "pythonw.exe"') do (
    taskkill /F /PID %%a >nul 2>&1
)

REM Khởi động proxy (ghi log ra file để debug nếu lỗi)
cd /d "%SCRIPT_DIR%"
start /B pythonw -u dd_proxy.py > proxy_last_run.log 2>&1

REM Bước 1b: Vòng lặp chờ proxy khởi động (tối đa 30 giây)
echo Đang đợi proxy khởi động (tối đa 30s)...
set RETRY_COUNT=0

:check_loop
netstat -ano | findstr ":8888" | findstr "LISTENING" >nul 2>&1
if %errorLevel% equ 0 (
    echo.
    echo [OK] Proxy đã khởi động thành công
    goto step2
)

set /a RETRY_COUNT+=1
if %RETRY_COUNT% geq 30 (
    echo.
    echo [ERROR] Không thể khởi động proxy sau 30 giây!
    echo.
    echo Nội dung lỗi gần nhất (proxy_last_run.log):
    if exist proxy_last_run.log type proxy_last_run.log
    echo.
    echo Vui lòng kiểm tra xem Python đã được cài đặt chưa.
    pause
    exit /b 1
)

<nul set /p "=."
timeout /t 1 /nobreak >nul
goto check_loop

:step2
echo.
REM Bước 2: Cấu hình Windows proxy
echo [2/4] Cấu hình Windows proxy...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyServer /t REG_SZ /d "127.0.0.1:8888" /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyOverride /t REG_SZ /d "<local>" /f >nul
echo [OK] Đã cấu hình Windows proxy
echo.

REM Bước 3: Khởi động phần mềm DD
echo [3/4] Đang khởi động phần mềm DD...
echo Đường dẫn: %DD_PATH%
start "" "%DD_PATH%"

REM Đợi DD khởi động
echo Đang đợi phần mềm DD khởi động...
timeout /t 3 /nobreak >nul

REM Kiểm tra DD có chạy không
tasklist /FI "IMAGENAME eq Start.exe" 2>nul | find /I "Start.exe" >nul
if %errorLevel% equ 0 (
    echo [OK] Phần mềm DD đã khởi động
) else (
    echo [WARNING] Chưa phát hiện process Start.exe
    echo [INFO] Phần mềm có thể đang khởi động, vui lòng đợi...
)
echo.

REM Bước 4: Giám sát phần mềm DD
echo [4/4] Đang giám sát phần mềm DD...
echo.
echo ========================================
echo      PHẦN MỀM DD ĐANG CHẠY
echo ========================================
echo.
echo Proxy: 127.0.0.1:8888 [ACTIVE]
echo Phần mềm: Start.exe
echo.
echo Khi bạn đóng phần mềm DD, proxy sẽ tự động tắt
echo Hoặc nhấn Ctrl+C để thoát mà không tắt proxy
echo.

REM Đợi process Start.exe kết thúc
:wait_loop
timeout /t 2 /nobreak >nul
tasklist /FI "IMAGENAME eq Start.exe" 2>nul | find /I "Start.exe" >nul
if %errorLevel% equ 0 (
    goto wait_loop
)

REM Phần mềm DD đã đóng
echo.
echo ========================================
echo      PHẦN MỀM DD ĐÃ ĐÓNG
echo ========================================
echo.

REM Chỉ tắt proxy nếu script này đã khởi động nó
if %PROXY_ALREADY_RUNNING% equ 0 (
    echo Đang dừng proxy...
    
    REM Tắt Windows proxy
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 0 /f >nul
    
    REM Dừng proxy process
    for /f "tokens=2" %%a in ('tasklist /FI "IMAGENAME eq pythonw.exe" /FO LIST ^| findstr "PID:"') do (
        set PID=%%a
    )
    
    if defined PID (
        taskkill /F /PID %PID% >nul 2>&1
        echo [OK] Đã dừng proxy
    )
    
    echo [OK] Đã khôi phục cấu hình Windows proxy
) else (
    echo [INFO] Proxy đã chạy từ trước, giữ nguyên trạng thái
)

echo.
echo Hoàn tất!
echo.
pause
