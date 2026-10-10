"""Run the sonar pipeline on a recorded take and plot it.

  python analyze_wav.py take.wav [--min-depth 15] [--plot take.png]

Works on recordings from probe_live.py --record or from the iPhone app,
as long as the tones played during the recording match --tones.
"""

import argparse

import numpy as np
import soundfile as sf

from sonar_core import RepCounter, RepCounterConfig, SonarConfig, SonarTracker


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("wav")
    ap.add_argument("--min-depth", type=float, default=15.0)
    ap.add_argument("--tones", default="18500,19100,19700")
    ap.add_argument("--plot", default="")
    a = ap.parse_args()
    x, fs = sf.read(a.wav, dtype="float64", always_2d=True)
    x = x[:, 0]
    cfg = SonarConfig(fs=fs, tones_hz=tuple(float(f) for f in a.tones.split(",")))
    tr = SonarTracker(cfg)
    rc = RepCounter(tr.rate_hz, RepCounterConfig(min_depth_cm=a.min_depth))
    pos = []
    for i in range(0, len(x), 1024):
        p = tr.process(x[i:i + 1024])
        rc.process(p)
        pos.append(p)
    pos = np.concatenate(pos) * 100
    print(f"{rc.count} valid reps, {sum(not r.valid for r in rc.reps)} too shallow")
    for k, r in enumerate(rc.reps, 1):
        print(f"  {k:2d}. {r.t_start:6.2f}s to {r.t_end:6.2f}s  depth {r.depth_cm:5.1f} cm  "
              f"{'valid' if r.valid else 'NO REP: ' + r.reason}")
    if a.plot:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
        t = np.arange(len(pos)) / tr.rate_hz
        fig, ax = plt.subplots(figsize=(10, 3.5))
        ax.plot(t, pos, lw=1.2)
        for r in rc.reps:
            ax.axvspan(r.t_start, r.t_end, color="tab:green" if r.valid else "tab:red", alpha=0.15)
        ax.set_xlabel("time (s)")
        ax.set_ylabel("chest movement towards phone (cm)")
        ax.set_title(f"{rc.count} reps counted by sonar")
        fig.tight_layout()
        fig.savefig(a.plot, dpi=150)
        print(f"plot saved to {a.plot}")


if __name__ == "__main__":
    main()
