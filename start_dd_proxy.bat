@echo off
chcp 65001 >nul
title DD Proxy - Starting...

REM Kiểm tra proxy đã chạy chưa
echo Đang kiểm tra proxy...
netstat -ano | findstr ":8888" | findstr "LISTENING" >nul 2>&1
if %errorLevel% equ 0 (
    echo [OK] Proxy đã đang chạy
    goto :configure_system
)

REM Khởi động proxy server
echo [1/3] Đang khởi động DD Proxy Server...
cd /d "%~dp0"

REM Chạy proxy ở background
start /B pythonw -u dd_proxy.py > dd_proxy_output.log 2>&1

REM Đợi một chút để process khởi động
timeout /t 1 /nobreak >nul

REM Lưu PID của proxy process
for /f "tokens=2 delims==" %%a in ('wmic process where "name='pythonw.exe' and commandline like '%%dd_proxy.py%%'" get processid /format:list 2^>nul ^| findstr "="') do (
    echo %%a > dd_proxy.pid
    echo [INFO] Đã lưu PID: %%a
)

REM Retry logic: kiểm tra proxy có khởi động thành công không
echo Đang đợi proxy khởi động...
set RETRY_COUNT=0
:check_proxy
netstat -ano | findstr ":8888" | findstr "LISTENING" >nul 2>&1
if %errorLevel% equ 0 goto proxy_started

set /a RETRY_COUNT+=1
if %RETRY_COUNT% geq 20 (
    echo [ERROR] Không thể khởi động proxy sau 10 giây!
    echo Vui lòng kiểm tra file dd_proxy_output.log để xem lỗi
    if exist dd_proxy.pid del dd_proxy.pid
    pause
    exit /b 1
)

timeout /t 1 /nobreak >nul
goto check_proxy

:proxy_started

echo [OK] Proxy đã khởi động thành công trên port 8888
echo.

:configure_system
REM Cấu hình Windows proxy settings
echo [2/3] Đang cấu hình Windows proxy...

REM Bật proxy cho HTTP và HTTPS
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyServer /t REG_SZ /d "127.0.0.1:8888" /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyOverride /t REG_SZ /d "<local>" /f >nul

echo [OK] Đã cấu hình Windows proxy
echo.

REM Refresh proxy settings
echo [3/3] Đang áp dụng cấu hình...
rundll32.exe inetcpl.cpl,LaunchConnectionDialog >nul 2>&1
timeout /t 1 /nobreak >nul

echo.
echo ========================================
echo      DD PROXY ĐÃ SẴN SÀNG!
echo ========================================
echo.
echo Proxy đang chạy tại: 127.0.0.1:8888
echo Log file: %~dp0dd_proxy.log
echo.
echo Bây giờ bạn có thể mở phần mềm DD
echo.
echo Để dừng proxy, chạy: stop_dd_proxy.bat
echo.

REM Tùy chọn: Tự động mở phần mềm DD
REM Bỏ comment dòng dưới nếu muốn tự động mở DD
REM start "" "C:\Path\To\DD.exe"

pause
