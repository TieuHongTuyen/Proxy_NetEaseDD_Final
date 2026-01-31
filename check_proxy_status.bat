@echo off
chcp 65001 >nul
title DD Proxy - Status Check

echo ========================================
echo      KIỂM TRA TRẠNG THÁI DD PROXY
echo ========================================
echo.

REM Kiểm tra proxy có đang chạy không
echo [1] Kiểm tra Proxy Server...
netstat -ano | findstr ":8888" | findstr "LISTENING" >nul 2>&1
if %errorLevel% equ 0 (
    echo [✓] Proxy đang chạy trên port 8888
    for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":8888" ^| findstr "LISTENING"') do (
        echo     PID: %%a
    )
) else (
    echo [✗] Proxy KHÔNG chạy
)
echo.

REM Kiểm tra Windows proxy settings
echo [2] Kiểm tra Windows Proxy Settings...
for /f "tokens=3" %%a in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable 2^>nul ^| findstr "ProxyEnable"') do (
    if "%%a"=="0x1" (
        echo [✓] Windows proxy đã BẬT
        for /f "tokens=3" %%b in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyServer 2^>nul ^| findstr "ProxyServer"') do (
            echo     Server: %%b
        )
    ) else (
        echo [✗] Windows proxy đã TẮT
    )
)
echo.

REM Kiểm tra certificate
echo [3] Kiểm tra Certificate...
certutil -store Root | findstr "mitmproxy" >nul 2>&1
if %errorLevel% equ 0 (
    echo [✓] Certificate mitmproxy đã cài đặt
) else (
    echo [✗] Certificate mitmproxy CHƯA cài đặt
    echo     Chạy install_proxy.bat để cài đặt
)
echo.

REM Kiểm tra log file
echo [4] Log Files...
if exist "%~dp0dd_proxy.log" (
    echo [✓] Log file: %~dp0dd_proxy.log
    echo     Kích thước: 
    for %%A in ("%~dp0dd_proxy.log") do echo     %%~zA bytes
) else (
    echo [i] Chưa có log file (proxy chưa chạy lần nào)
)
echo.

echo ========================================
echo          KẾT THÚC KIỂM TRA
echo ========================================
echo.
pause
