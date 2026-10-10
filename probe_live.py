"""Live sonar on a Mac (or any laptop): speaker plays the tones, mic listens.

Two modes:

  python probe_live.py --check
      Plays the tones for 3 seconds and reports how loud each one arrives at
      the microphone compared with the noise next to it. This answers "can
      this hardware do 19 kHz?" in one go. Aim for 20 dB or more per tone.

  python probe_live.py [--record take.wav] [--min-depth 15] [--seconds 40]
      Live tracking. Move your hand or a book up and down 10 to 30 cm above
      the keyboard, or put the laptop on the floor and do push-ups over it.
      Prints position (cm, positive = closer) and the rep count. Stops on
      Ctrl+C, or by itself after --seconds.

Install:  pip install numpy scipy sounddevice soundfile
"""

import argparse
import queue
import sys
import time

import numpy as np
import sounddevice as sd

from live_display import Display
from sonar_core import RepCounter, RepCounterConfig, SonarConfig, SonarTracker, tone_block


def check(cfg: SonarConfig, amp: float, seconds: float = 3.0):
    n = int(seconds * cfg.fs)
    tx = tone_block(cfg, 0, n, amp)
    ramp = int(0.01 * cfg.fs)
    tx[:ramp] *= np.linspace(0, 1, ramp)
    tx[-ramp:] *= np.linspace(1, 0, ramp)
    rx = sd.playrec(tx.astype(np.float32), samplerate=cfg.fs, channels=1, blocking=True)[:, 0]
    rx = rx[int(0.5 * cfg.fs):]  # skip start-up
    spec = np.abs(np.fft.rfft(rx * np.hanning(len(rx)))) ** 2
    freqs = np.fft.rfftfreq(len(rx), 1 / cfg.fs)
    print(f"mic peak level {np.max(np.abs(rx)):.3f} (1.0 = clipping)")
    ok = True
    for f in cfg.tones_hz:
        sig = spec[np.abs(freqs - f) < 5].max()
        band = (np.abs(freqs - f) > 50) & (np.abs(freqs - f) < 400)
        noise = np.median(spec[band])
        snr = 10 * np.log10(sig / noise)
        flag = "OK" if snr >= 20 else "WEAK"
        ok &= snr >= 20
        print(f"  {f/1000:.1f} kHz: {snr:5.1f} dB above noise  {flag}")
    print("Hardware can do it." if ok else "Some tones are weak: raise volume or drop those tones.")


def live(cfg: SonarConfig, amp: float, record: str, min_depth: float, seconds: float = 0.0,
         display_port: int = 0):
    q: "queue.Queue[np.ndarray]" = queue.Queue()
    n_out = [0]
    ramp_len = int(0.05 * cfg.fs)

    def cb(indata, outdata, frames, t, status):
        if status:
            print(status, file=sys.stderr)
        blk = tone_block(cfg, n_out[0], frames, amp)
        if n_out[0] < ramp_len:  # fade in, no click
            g = np.clip((n_out[0] + np.arange(frames)) / ramp_len, 0, 1)
            blk *= g
        outdata[:, 0] = blk
        n_out[0] += frames
        q.put(indata[:, 0].copy())

    tracker = SonarTracker(cfg)
    counter = RepCounter(tracker.rate_hz, RepCounterConfig(min_depth_cm=min_depth))
    display = None
    if display_port:
        display = Display(min_depth, "Mac", port=display_port)
        display.start()
    writer = None
    if record:
        import soundfile as sf
        writer = sf.SoundFile(record, "w", samplerate=cfg.fs, channels=1, subtype="FLOAT")
    print("Tracking. Ctrl+C to stop. Warm-up: wave once to lock on.")
    last_print = 0.0
    n_in = 0
    with sd.Stream(samplerate=cfg.fs, blocksize=1024, channels=1, dtype="float32", callback=cb):
        try:
            while True:
                x = q.get()
                n_in += len(x)
                if writer:
                    writer.write(x)
                pos = tracker.process(x.astype(np.float64))
                if display and display.take_reset():
                    counter = RepCounter(tracker.rate_hz, RepCounterConfig(min_depth_cm=min_depth))
                for r in counter.process(pos):
                    mark = "REP" if r.valid else "NO REP (too shallow)"
                    print(f"\n  {mark}  depth {r.depth_cm:.1f} cm   total {counter.count}")
                    if display:
                        display.rep(r, counter.count)
                if display:
                    display.state(counter)
                now = time.time()
                if now - last_print > 0.1 and len(pos):
                    last_print = now
                    depth = (counter.y - counter.top) if counter.y is not None else 0.0
                    bar = int(np.clip(depth * 2, 0, 60))
                    sys.stdout.write(f"\r  depth {depth:5.1f} cm  |{'#'*bar:<60}|  reps {counter.count}  ")
                    sys.stdout.flush()
                if seconds and n_in >= seconds * cfg.fs:
                    break
        except KeyboardInterrupt:
            pass
    if writer:
        writer.close()
        print(f"\nSaved {record}")
    print(f"\nFinal: {counter.count} valid reps, "
          f"{sum(not r.valid for r in counter.reps)} too shallow")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--amp", type=float, default=0.3, help="tone level 0 to 1")
    ap.add_argument("--record", default="")
    ap.add_argument("--min-depth", type=float, default=15.0)
    ap.add_argument("--seconds", type=float, default=0.0, help="stop after this long (0 = until Ctrl+C)")
    ap.add_argument("--tones", default="18500,19100,19700")
    ap.add_argument("--display", type=int, nargs="?", const=8000, default=0, metavar="PORT",
                    help="serve the live demo screen (default port 8000)")
    a = ap.parse_args()
    cfg = SonarConfig(tones_hz=tuple(float(f) for f in a.tones.split(",")))
    if a.check:
        check(cfg, a.amp)
    else:
        live(cfg, a.amp, a.record, a.min_depth, a.seconds, a.display)
