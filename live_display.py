"""Live demo screen: one local web page fed by Server-Sent Events.

    display = Display(min_depth_cm=15.0, source="iPhone")
    display.start()                      # http://localhost:8765
    display.state(counter, moving=False, lost=0)
    display.rep(rep, counter.count)

The page is display.html next to this file. It needs no internet and nothing
leaves the machine. Used by phone_receiver.py and probe_live.py (--display).
"""

import json
import queue
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

PAGE = Path(__file__).parent / "display.html"


class Display:
    def __init__(self, min_depth_cm: float, source: str, port: int = 8765, rate_hz: float = 30.0):
        self.hello = {"min_depth": float(min_depth_cm), "source": source}
        self.port = port
        self.period = 1.0 / rate_hz
        self.clients: list = []
        self.lock = threading.Lock()
        self.last_sent = 0.0
        self.reset_requested = False

    def _send(self, event: str, data: dict):
        msg = f"event: {event}\ndata: {json.dumps(data)}\n\n".encode()
        with self.lock:
            for q in self.clients:
                try:
                    q.put_nowait(msg)
                except queue.Full:
                    pass  # a stalled browser tab must never block the audio loop

    def state(self, counter, moving: bool = False, lost: int = 0):
        """Call after every block. Sends at most rate_hz updates a second."""
        # Depth below the counter's own top. It snaps back to zero when a rep
        # closes, which reads on the gauge as the rep finishing.
        depth = 0.0 if moving or counter.y is None else max(0.0, counter.y - counter.top)
        now = time.time()
        if now - self.last_sent < self.period:
            return
        self.last_sent = now
        self._send("state", {
            "depth": round(float(depth), 2),
            "count": int(counter.count),
            "shallow": int(sum(not r.valid for r in counter.reps)),
            "moving": bool(moving),
            "lost": int(lost),
        })

    def rep(self, rep, count: int):
        self._send("rep", {"valid": bool(rep.valid), "depth": float(rep.depth_cm), "count": int(count)})

    def take_reset(self) -> bool:
        """True once after the Reset button on the page was pressed."""
        asked, self.reset_requested = self.reset_requested, False
        if asked:
            self._send("reset", {})
        return asked

    def start(self):
        display = self

        class Handler(BaseHTTPRequestHandler):
            def log_message(self, *args):
                pass

            def do_GET(self):
                if self.path.split("?")[0] != "/events":
                    body = PAGE.read_bytes()
                    self.send_response(200)
                    self.send_header("Content-Type", "text/html; charset=utf-8")
                    self.send_header("Content-Length", str(len(body)))
                    self.send_header("Cache-Control", "no-store")
                    self.end_headers()
                    self.wfile.write(body)
                    return
                self.send_response(200)
                self.send_header("Content-Type", "text/event-stream")
                self.send_header("Cache-Control", "no-store")
                self.end_headers()
                q: queue.Queue = queue.Queue(maxsize=300)
                with display.lock:
                    display.clients.append(q)
                try:
                    self.wfile.write(f"event: hello\ndata: {json.dumps(display.hello)}\n\n".encode())
                    while True:
                        try:
                            msg = q.get(timeout=2.0)
                        except queue.Empty:
                            msg = b": still here\n\n"
                        self.wfile.write(msg)
                        self.wfile.flush()
                except (BrokenPipeError, ConnectionResetError):
                    pass
                finally:
                    with display.lock:
                        display.clients.remove(q)

            def do_POST(self):
                if self.path == "/reset":
                    display.reset_requested = True
                self.send_response(204)
                self.end_headers()

        server = ThreadingHTTPServer(("127.0.0.1", self.port), Handler)
        server.daemon_threads = True
        threading.Thread(target=server.serve_forever, daemon=True).start()
        print(f"Live display: http://localhost:{self.port}")
