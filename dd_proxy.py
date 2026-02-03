"""
DD Proxy - Lightweight HTTPS Proxy for DD Software
Sử dụng mitmproxy để thay thế Fiddler
"""

from mitmproxy import http
from mitmproxy.tools.main import mitmdump
import sys
import os
import logging

class DDProxyAddon:
    """Addon để xử lý các request của phần mềm DD"""
    
    def __init__(self):
        self.request_count = 0
        
    def request(self, flow: http.HTTPFlow) -> None:
        """Xử lý mỗi request"""
        self.request_count += 1
        # Log request để debug (có thể tắt sau khi hoạt động ổn định)
        logging.info(f"[{self.request_count}] {flow.request.method} {flow.request.pretty_url}")
        
    def response(self, flow: http.HTTPFlow) -> None:
        """Xử lý response"""
        # Log response status
        logging.info(f"Response: {flow.response.status_code} for {flow.request.pretty_url}")

def main():
    """Khởi động proxy server"""
    # Cấu hình logging - Chỉ ghi ra màn hình console, không ghi file
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s',
        handlers=[
            logging.StreamHandler(sys.stdout)
        ]
    )
    
    logging.info("=" * 60)
    logging.info("DD Proxy Server Starting...")
    logging.info("=" * 60)
    
    # Khởi động mitmproxy programmatically
    from mitmproxy.tools.dump import DumpMaster
    from mitmproxy.options import Options
    import asyncio

    async def run_proxy():
        opts = Options(
            listen_host="127.0.0.1",
            listen_port=8888,
            ssl_insecure=True,
        )
        
        try:
            m = DumpMaster(opts, with_termlog=False, with_dumper=False)
            m.addons.add(DDProxyAddon())
            logging.info("Proxy server is listening on 127.0.0.1:8888")
            await m.run()
        except Exception as e:
            if "Address already in use" in str(e):
                logging.error("LỖI: Port 8888 đã bị sử dụng bởi ứng dụng khác!")
            else:
                logging.error(f"Error in DumpMaster: {e}")
            if 'm' in locals():
                m.shutdown()

    try:
        asyncio.run(run_proxy())
    except Exception as e:
        if "Address already in use" not in str(e):
            logging.error(f"Asyncio run error: {e}")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        logging.info("Proxy server stopped by user")
    except Exception as e:
        logging.error(f"Proxy server error: {e}")
        sys.exit(1)
