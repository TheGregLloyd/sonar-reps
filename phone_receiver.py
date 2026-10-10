"""Receive the iPhone's sonar stream on the Mac and count reps live.

  python phone_receiver.py [--port 5005] [--min-depth 15] [--record take.wav]

Network tip: university Wi-Fi often blocks device-to-device traffic. Turn on
Personal Hotspot on the iPhone and join it from the Mac; the Mac's address
is then usually 172.20.10.2 (check with: ipconfig getifaddr en0).
"""

import argparse
import socket
import struct
import sys

import numpy as np

from sonar_core import RepCounter, RepCounterConfig, SonarConfig, SonarTracker


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", type=int, default=5005)
    ap.add_argument("--min-depth", type=float, default=15.0)
    ap.add_argument("--tones", default="18500,19100,19700")
    ap.add_argument("--record", default="")
    a = ap.parse_args()

    cfg = SonarConfig(tones_hz=tuple(float(f) for f in a.tones.split(",")))
    tracker = SonarTracker(cfg)
    counter = RepCounter(tracker.rate_hz, RepCounterConfig(min_depth_cm=a.min_depth))
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
    try:
        while True:
            pkt, _ = sock.recvfrom(65536)
            seq, flags = struct.unpack("<II", pkt[:8])
            x = np.frombuffer(pkt[8:], dtype="<f4").astype(np.float64)
            if expected is not None and seq != expected:
                lost += (seq - expected) & 0xFFFFFFFF
            expected = (seq + 1) & 0xFFFFFFFF
            if writer:
                writer.write(x.astype(np.float32))
            pos = tracker.process(x)
            phone_moving = bool(flags & 1)
            if phone_moving:
                # Anti-cheat: while the phone itself moves, nothing counts.
                blocked += 1
                counter.state = "up"
                counter.top = counter.y if counter.y is not None else 0.0
                continue
            for r in counter.process(pos):
                mark = "REP" if r.valid else "NO REP (too shallow)"
                print(f"\n  {mark}  depth {r.depth_cm:.1f} cm   total {counter.count}")
            if len(pos):
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
