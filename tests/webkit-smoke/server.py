# GPL-3.0. Local-only deterministic fixture server, never proxies user traffic.
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from time import sleep

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/slow':
            sleep(8)
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
