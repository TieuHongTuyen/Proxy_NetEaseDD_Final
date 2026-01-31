@echo off
chcp 65001 >nul
title DD Quick Launcher - Khởi động nhanh

echo ========================================
echo      DD QUICK LAUNCHER
echo ========================================
echo.

REM Lưu thư mục hiện tại
set "SCRIPT_DIR=%~dp0"
set "DD_PATH=D:\NetEaseDD\Start.exe"

REM Kiểm tra phần mềm DD có tồn tại không
if not exist "%DD_PATH%" (
    echo [ERROR] Không tìm thấy phần mềm DD tại: %DD_PATH%
    echo.
    echo Vui lòng kiểm tra đường dẫn trong file quick_run_dd.bat
    echo.
    pause
    exit /b 1
)

REM Bước 1: Kiểm tra proxy đã chạy chưa
echo [1/3] Kiểm tra proxy...
netstat -ano | findstr ":8888" | findstr "LISTENING" >nul 2>&1
if %errorLevel% equ 0 (
    echo [OK] Proxy đã đang chạy
) else (
    echo [INFO] Proxy chưa chạy, đang khởi động...
    
    REM Khởi động proxy
    cd /d "%SCRIPT_DIR%"
    start /B pythonw -u dd_proxy.py > dd_proxy_output.log 2>&1
    
    REM Đợi proxy khởi động
    echo Đang đợi proxy khởi động...
    timeout /t 3 /nobreak >nul
    
    REM Kiểm tra lại
    netstat -ano | findstr ":8888" | findstr "LISTENING" >nul 2>&1
    if %errorLevel% neq 0 (
        echo [ERROR] Không thể khởi động proxy!
        echo Vui lòng kiểm tra file dd_proxy_output.log
        pause
        exit /b 1
    )
    
    echo [OK] Proxy đã khởi động thành công
)
echo.

REM Bước 2: Cấu hình Windows proxy
echo [2/3] Cấu hình Windows proxy...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 1 /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyServer /t REG_SZ /d "127.0.0.1:8888" /f >nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyOverride /t REG_SZ /d "<local>" /f >nul
echo [OK] Đã cấu hình Windows proxy
echo.

REM Bước 3: Khởi động phần mềm DD
echo [3/3] Đang khởi động phần mềm DD...
echo Đường dẫn: %DD_PATH%
start "" "%DD_PATH%"
echo [OK] Đã khởi động phần mềm DD
echo.

echo ========================================
echo      HOÀN TẤT!
echo ========================================
echo.
echo ✅ Proxy đang chạy: 127.0.0.1:8888
echo ✅ Windows proxy đã cấu hình
echo ✅ Phần mềm DD đã khởi động
echo.
echo 📝 LƯU Ý:
echo    - Proxy sẽ TIẾP TỤC chạy sau khi đóng cửa sổ này
echo    - Khi không dùng DD nữa, chạy: stop_dd_proxy.bat
echo.
echo Bạn có thể đóng cửa sổ này ngay bây giờ.
echo.
pause
