"""Receive the iPhone's sonar stream on the Mac and count reps live.

  python phone_receiver.py [--port 5005] [--min-depth 15] [--record take.wav] [--display]

--display also serves the live demo screen on http://localhost:8765.

Network tip: university Wi-Fi often blocks device-to-device traffic. Turn on
Personal Hotspot on the iPhone and join it from the Mac; the Mac's address
is then usually 172.20.10.2 (check with: ipconfig getifaddr en0).
"""

import argparse
import socket
import struct
import sys
import time

import numpy as np

from live_display import Display
from sonar_core import RepCounter, RepCounterConfig, SonarConfig, SonarTracker


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", type=int, default=5005)
    ap.add_argument("--min-depth", type=float, default=15.0)
    ap.add_argument("--tones", default="18500,19100,19700")
    ap.add_argument("--record", default="")
    ap.add_argument("--display", type=int, nargs="?", const=8765, default=0, metavar="PORT",
                    help="serve the live demo screen (default port 8765)")
    a = ap.parse_args()

    cfg = SonarConfig(tones_hz=tuple(float(f) for f in a.tones.split(",")))
    tracker = SonarTracker(cfg)
    rep_cfg = RepCounterConfig(min_depth_cm=a.min_depth)
    counter = RepCounter(tracker.rate_hz, rep_cfg)
    display = None
    if a.display:
        display = Display(a.min_depth, "iPhone", port=a.display)
        display.start()
    writer = None
    if a.record:
        import soundfile as sf
        writer = sf.SoundFile(a.record, "w", samplerate=cfg.fs, channels=1, subtype="FLOAT")

    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind(("0.0.0.0", a.port))
    print(f"Listening on UDP {a.port}. Start sonar on the phone.")
    expected = None
    lost = 0
    blocked = 0
    last_print = 0.0
    try:
        while True:
            pkt, _ = sock.recvfrom(65536)
            seq, flags = struct.unpack("<II", pkt[:8])
            x = np.frombuffer(pkt[8:], dtype="<f4").astype(np.float64)
            if expected is not None and seq != expected:
                gap = (seq - expected) & 0xFFFFFFFF
                if gap < 1000:
                    # Packets all carry the same number of samples, so step
                    # over the hole to keep the tone phase lined up.
                    lost += gap
                    skipped = gap * len(x)
                    for t in tracker.trackers:
                        t.n += skipped
                    if writer:
                        writer.write(np.zeros(skipped, dtype=np.float32))
                else:
                    # The phone restarted its stream: a new set, from zero.
                    tracker = SonarTracker(cfg)
                    counter = RepCounter(tracker.rate_hz, rep_cfg)
                    if display:
                        display.reset_requested = True
            expected = (seq + 1) & 0xFFFFFFFF
            if writer:
                writer.write(x.astype(np.float32))
            pos = tracker.process(x)
            if display and display.take_reset():
                counter = RepCounter(tracker.rate_hz, rep_cfg)
            phone_moving = bool(flags & 1)
            if phone_moving:
                # Anti-cheat: while the phone itself moves, nothing counts,
                # and the counter starts again from wherever the chest is.
                blocked += 1
                counter.state = "up"
                counter.y = None
            else:
                for r in counter.process(pos):
                    mark = "REP" if r.valid else "NO REP (too shallow)"
                    print(f"\n  {mark}  depth {r.depth_cm:.1f} cm   total {counter.count}")
                    if display:
                        display.rep(r, counter.count)
            if display:
                display.state(counter, phone_moving, lost)
            now = time.time()
            if now - last_print > 0.05 and len(pos):
                last_print = now
                depth = (counter.y - counter.top) if counter.y is not None else 0.0
                bar = int(np.clip(depth * 2, 0, 60))
                sys.stdout.write(f"\r  depth {depth:5.1f} cm |{'#'*bar:<60}| reps {counter.count}  lost {lost}  ")
                sys.stdout.flush()
    except KeyboardInterrupt:
        pass
    if writer:
        writer.close()
    print(f"\nFinal: {counter.count} valid, {sum(not r.valid for r in counter.reps)} too shallow, "
          f"{lost} packets lost, {blocked} blocks ignored while the phone moved")


if __name__ == "__main__":
    main()
