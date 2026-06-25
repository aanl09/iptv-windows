#!/usr/bin/env python3
"""Multi-threaded IPTV server: static files + CORS proxy on ONE port"""
from http.server import HTTPServer, SimpleHTTPRequestHandler
from socketserver import ThreadingMixIn
from urllib.parse import urlparse, parse_qs, quote
import urllib.request, ssl, os, sys, gzip, io

PORT = 8099
WEB_DIR = os.path.dirname(os.path.abspath(__file__))

class ThreadingHTTPServer(ThreadingMixIn, HTTPServer):
    daemon_threads = True

class CombinedHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=WEB_DIR, **kwargs)
    
    def do_GET(self):
        if self.path.startswith('/proxy'):
            self._handle_proxy()
            return
        # Default: serve static files
        super().do_GET()
    
    def do_OPTIONS(self):
        if self.path.startswith('/proxy'):
            self._send_cors_headers(200)
        else:
            super().do_OPTIONS()
    
    def do_HEAD(self):
        super().do_HEAD()
    
    def _handle_proxy(self):
        parsed = urlparse(self.path)
        params = parse_qs(parsed.query)
        target_url = params.get('url', [None])[0]
        
        if not target_url:
            self.send_error(400, 'Missing ?url=')
            return
        
        custom_referer = params.get('referer', [None])[0]
        custom_origin = params.get('origin', [None])[0]
        
        try:
            ctx = ssl.create_default_context()
            ctx.check_hostname = False
            ctx.verify_mode = ssl.CERT_NONE
            
            req_headers = {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36',
                'Accept': '*/*',
                'Accept-Encoding': 'identity',  # No compression for streaming
            }
            if custom_origin or custom_referer:
                req_headers['Origin'] = custom_origin or custom_referer or ''
                req_headers['Referer'] = custom_referer or custom_origin or ''
            else:
                req_headers['Origin'] = 'https://shoof.alkass.net'
                req_headers['Referer'] = 'https://shoof.alkass.net/'
            
            req = urllib.request.Request(target_url, headers=req_headers)
            
            with urllib.request.urlopen(req, timeout=20, context=ctx) as resp:
                content = resp.read()
                ct = resp.headers.get('Content-Type', 'application/octet-stream')
                
                # Rewrite M3U8 relative URLs to proxy URLs
                is_m3u8 = ('mpegurl' in ct or 'x-mpegurl' in ct) or target_url.endswith('.m3u8')
                if is_m3u8:
                    content_str = content.decode('utf-8', errors='ignore')
                    proxy_base = target_url.rsplit('/', 1)[0]
                    extra_params = ''
                    if custom_referer:
                        extra_params += f'&referer={quote(custom_referer, safe="")}'
                    if custom_origin:
                        extra_params += f'&origin={quote(custom_origin, safe="")}'
                    
                    new_lines = []
                    for line in content_str.split('\n'):
                        line_s = line.strip()
                        if line_s and not line_s.startswith('#') and not line_s.startswith('http'):
                            full_target = f'{proxy_base}/{line_s}'
                            new_lines.append(f'/proxy?url={quote(full_target, safe="")}{extra_params}')
                        else:
                            new_lines.append(line)
                    content = '\n'.join(new_lines).encode('utf-8')
                
                self.send_response(200)
                self.send_header('Content-Type', ct)
                self.send_header('Content-Length', len(content))
                self.send_header('Access-Control-Allow-Origin', '*')
                self.send_header('Access-Control-Allow-Methods', 'GET, OPTIONS')
                self.send_header('Access-Control-Allow-Headers', '*')
                self.send_header('Cache-Control', 'public, max-age=2')
                self.send_header('Connection', 'keep-alive')
                self.end_headers()
                self.wfile.write(content)
        except Exception as e:
            self.send_error(502, str(e))
    
    def _send_cors_headers(self, code):
        self.send_response(code)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', '*')
        self.end_headers()
    
    def log_message(self, format, *args):
        if '/proxy' in str(args):
            return  # Silent for proxy
        super().log_message(format, *args)

if __name__ == '__main__':
    server = ThreadingHTTPServer(('0.0.0.0', PORT), CombinedHandler)
    print(f'🔓 Multi-threaded IPTV server on :{PORT}')
    print(f'   Web: http://localhost:{PORT}/')
    print(f'   Proxy: http://localhost:{PORT}/proxy?url=STREAM_URL')
    server.serve_forever()
