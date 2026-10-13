import json
import os
import socket
from http.server import BaseHTTPRequestHandler, HTTPServer

PORT = int(os.environ.get("PORT", "8080"))


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/healthz":
            body, ctype = b"ok", "text/plain"
        else:
            body = json.dumps({
                "app": "hello-python",
                "message": "Hello from Python on GKE",
                "path": self.path,
                "pod": socket.gethostname(),
                "version": os.environ.get("APP_VERSION", "dev"),
            }).encode()
            ctype = "application/json"
        self.send_response(200)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


if __name__ == "__main__":
    print(f"hello-python listening on {PORT}", flush=True)
    HTTPServer(("", PORT), Handler).serve_forever()
