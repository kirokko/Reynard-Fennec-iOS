# GPL-3.0. Local-only deterministic fixture server, never proxies user traffic.
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from time import sleep
from urllib.parse import urlsplit
import base64

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        path = urlsplit(self.path).path
        if path.startswith('/port/'):
            content_type = 'text/plain; charset=utf-8'
            body = ('REACHED_SERVER:' + path).encode()
            if path == '/port/index.html':
                content_type = 'text/html; charset=utf-8'
                body = b'''<!doctype html><html><head><title>uBO port fixture</title></head>
<body><div class="port-ad">Synthetic advertisement</div><div id="kept">Keep ordinary content</div>
<script id="html-filter-target">window.__htmlMarker = 'reynard-never-remove';</script></body></html>'''
            elif path in ('/port/control.png', '/port/image-only.txt'):
                content_type = 'image/png'
                body = base64.b64decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGP4z8DwHwAFAAH/iZk9HQAAAABJRU5ErkJggg==')
            self.send_response(200)
            self.send_header('Content-Type', content_type)
            self.send_header('Content-Length', str(len(body)))
            self.send_header('Cache-Control', 'no-store')
            self.end_headers()
            try:
                self.wfile.write(body)
            except (BrokenPipeError, ConnectionResetError):
                pass
            return
        if self.path == '/slow':
            self.send_response(200)
            self.send_header('Content-Type', 'text/html; charset=utf-8')
            self.send_header('Cache-Control', 'no-store')
            self.end_headers()
            try:
                self.wfile.write(b'<!doctype html><html><head><title>Slow</title></head><body>' + b' ' * 8192)
                self.wfile.flush()
                sleep(12)
                self.wfile.write(b'Complete</body></html>')
            except (BrokenPipeError, ConnectionResetError):
                pass
            return
        title = 'Two' if self.path == '/two.html' else 'One'
        body = f'<!doctype html><html><head><title>{title}</title></head><body>{title}</body></html>'.encode()
        self.send_response(200)
        self.send_header('Content-Type', 'text/html; charset=utf-8')
        self.send_header('Content-Length', str(len(body)))
        self.send_header('Cache-Control', 'no-store')
        self.end_headers()
        try:
            self.wfile.write(body)
        except (BrokenPipeError, ConnectionResetError):
            pass

ThreadingHTTPServer(('127.0.0.1', 8765), Handler).serve_forever()
