@echo off
chcp 65001 >nul
echo ========================================
echo    CÀI ĐẶT DD PROXY - BƯỚC 1/4
echo ========================================
echo.

REM Kiểm tra quyền Administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Cần chạy với quyền Administrator!
    echo.
    echo Cách chạy:
    echo 1. Nhấn chuột phải vào file này
    echo 2. Chọn "Run as administrator"
    echo.
    pause
    exit /b 1
)

echo [OK] Đã có quyền Administrator
echo.

REM Kiểm tra Python
echo [1/4] Kiểm tra Python...
python --version >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Chưa cài đặt Python!
    echo.
    echo Vui lòng cài đặt Python từ: https://www.python.org/downloads/
    echo Lưu ý: Tích chọn "Add Python to PATH" khi cài đặt
    echo.
    pause
    exit /b 1
)

for /f "tokens=2" %%i in ('python --version 2^>^&1') do set PYTHON_VERSION=%%i
echo [OK] Đã cài Python %PYTHON_VERSION%
echo.

REM Cài đặt mitmproxy
echo [2/4] Cài đặt mitmproxy...
echo Đang tải và cài đặt (có thể mất vài phút)...
python -m pip install --upgrade pip >nul 2>&1
python -m pip install mitmproxy
if %errorLevel% neq 0 (
    echo [ERROR] Không thể cài đặt mitmproxy!
    echo Vui lòng kiểm tra kết nối Internet
    pause
    exit /b 1
)
echo [OK] Đã cài đặt mitmproxy thành công
echo.

REM Tạo thư mục cho certificate
echo [3/4] Cấu hình certificate...
set CERT_DIR=%USERPROFILE%\.mitmproxy
if not exist "%CERT_DIR%" mkdir "%CERT_DIR%"

REM Chạy mitmproxy một lần để tạo certificate
echo Đang tạo certificate tự ký...
start /B python -m mitmproxy.tools.mitmdump --set confdir=%CERT_DIR% >nul 2>&1
timeout /t 3 /nobreak >nul
taskkill /F /IM mitmdump.exe >nul 2>&1

REM Cài đặt certificate vào Windows Trusted Root
if exist "%CERT_DIR%\mitmproxy-ca-cert.cer" (
    echo Đang cài đặt certificate vào Windows...
    certutil -addstore -f "Root" "%CERT_DIR%\mitmproxy-ca-cert.cer" >nul 2>&1
    if %errorLevel% equ 0 (
        echo [OK] Đã cài đặt certificate thành công
    ) else (
        echo [WARNING] Không thể tự động cài certificate
        echo Bạn có thể cài thủ công sau bằng cách:
        echo 1. Mở file: %CERT_DIR%\mitmproxy-ca-cert.cer
        echo 2. Chọn "Install Certificate"
        echo 3. Chọn "Local Machine" ^> "Trusted Root Certification Authorities"
    )
) else (
    echo [WARNING] Chưa tìm thấy certificate, sẽ tạo khi chạy lần đầu
)
echo.

REM Tạo Windows Service (tùy chọn)
echo [4/4] Hoàn tất cài đặt...
echo.
echo ========================================
echo         CÀI ĐẶT HOÀN TẤT!
echo ========================================
echo.
echo Các file đã được tạo tại: D:\Log\
echo - dd_proxy.py: Script proxy server
echo - start_dd_proxy.bat: Khởi động proxy
echo - stop_dd_proxy.bat: Dừng proxy
echo.
echo Bước tiếp theo:
echo 1. Chạy "start_dd_proxy.bat" để khởi động proxy
echo 2. Mở phần mềm DD để kiểm tra
echo.
pause
