@echo off
chcp 65001 >nul
title DD Proxy - Stopping...

echo ========================================
echo       ĐANG DỪNG DD PROXY
echo ========================================
echo.

REM Tắt Windows proxy settings
echo [1/2] Đang tắt Windows proxy...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 0 /f >nul
echo [OK] Đã tắt Windows proxy
echo.

REM Dừng proxy process
echo [2/2] Đang dừng proxy server...

REM Đọc PID từ file nếu có
set PID=
if exist "%~dp0dd_proxy.pid" (
    set /p PID=<"%~dp0dd_proxy.pid"
    if defined PID (
        taskkill /F /PID %PID% >nul 2>&1
        if %errorLevel% equ 0 (
            echo [OK] Đã dừng proxy server (PID: %PID%)
            del "%~dp0dd_proxy.pid" >nul 2>&1
        ) else (
            echo [WARNING] Không thể dừng process (PID: %PID%)
        )
    )
) else (
    REM Fallback: tìm bằng wmic nếu không có PID file
    echo [INFO] Không tìm thấy PID file, đang tìm process...
    for /f "tokens=2 delims==" %%a in ('wmic process where "name='pythonw.exe' and commandline like '%%dd_proxy.py%%'" get processid /format:list 2^>nul ^| findstr "="') do (
        set PID=%%a
    )
    
    if defined PID (
        taskkill /F /PID %PID% >nul 2>&1
        if %errorLevel% equ 0 (
            echo [OK] Đã dừng proxy server (PID: %PID%)
        ) else (
            echo [WARNING] Không thể dừng process
        )
    ) else (
        echo [INFO] Proxy không chạy
    )
)

REM Dừng tất cả mitmdump nếu có
taskkill /F /IM mitmdump.exe >nul 2>&1
taskkill /F /IM python.exe /FI "WINDOWTITLE eq dd_proxy*" >nul 2>&1

echo.
echo ========================================
echo      ĐÃ DỪNG DD PROXY
echo ========================================
echo.
echo Proxy đã được dừng và cấu hình đã được khôi phục
echo.
pause
