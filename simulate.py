"""Synthetic check of the sonar pipeline before touching any hardware.

Builds a fake microphone signal: strong direct leakage from speaker to mic,
static echoes from floor and walls, a chest echo whose distance follows a
push-up set, plus noise. Then checks that the tracker and rep counter recover
the right reps, including a shallow rep that must not count.

Then replays the real recordings in takes/ as regression tests.

Run:  python simulate.py
"""

import numpy as np

from sonar_core import SPEED_OF_SOUND, RepCounter, SonarConfig, SonarTracker
from takes import run_all


def chest_distance(t, reps, top=0.35):
    """reps: list of (start_s, duration_s, depth_m). Smooth cosine dip each."""
    d = np.full_like(t, top)
    for s, dur, depth in reps:
        m = (t >= s) & (t < s + dur)
        ph = (t[m] - s) / dur
        d[m] = top - depth * 0.5 * (1 - np.cos(2 * np.pi * ph))
    return d


def synth(cfg, reps, total_s, seed=0, snr_db=25.0):
    rng = np.random.default_rng(seed)
    t = np.arange(int(total_s * cfg.fs)) / cfg.fs
    d = chest_distance(t, reps)
    x = np.zeros_like(t)
    for f in cfg.tones_hz:
        w = 2 * np.pi * f
        x += 1.0 * np.sin(w * (t - 0.0002))  # direct leakage, loud
        x += 0.3 * np.sin(w * (t - 2 * 0.9 / SPEED_OF_SOUND))  # wall
        tau = 2 * d / SPEED_OF_SOUND
        amp = 0.08 * (0.2 / d)  # echo gets stronger as the chest gets closer
        x += amp * np.sin(w * (t - tau))
    x /= len(cfg.tones_hz)
    sig_p = np.mean((0.08 / len(cfg.tones_hz)) ** 2)
    x += rng.normal(0, np.sqrt(sig_p / 10 ** (snr_db / 10)), len(x))
    return x


def run_case(name, reps, total_s, expect_valid, expect_shallow, **kw):
    cfg = SonarConfig()
    x = synth(cfg, reps, total_s, **kw)
    tr = SonarTracker(cfg)
    rc = RepCounter(tr.rate_hz)
    block = 1024
    for i in range(0, len(x), block):
        rc.process(tr.process(x[i : i + block]))
    valid = rc.count
    shallow = sum(not r.valid for r in rc.reps)
    ok = valid == expect_valid and shallow == expect_shallow
    depths = [r.depth_cm for r in rc.reps]
    print(f"{'PASS' if ok else 'FAIL'}  {name}: valid {valid}/{expect_valid}, "
          f"shallow {shallow}/{expect_shallow}, depths cm {depths}")
    return ok


if __name__ == "__main__":
    results = []
    # 10 steady reps, 27 cm deep, 1.6 s each.
    reps = [(1.0 + i * 1.8, 1.6, 0.27) for i in range(10)]
    results.append(run_case("steady set", reps, 20.5, 10, 0))
    # Fast reps (0.7 s), the case PressPass's 0.5 s dwell rule dropped.
    reps = [(1.0 + i * 0.75, 0.7, 0.25) for i in range(10)]
    results.append(run_case("fast reps", reps, 10.0, 10, 0))
    # 5 reps, a shallow half rep, rest, 3 more.
    reps = [(1.0 + i * 1.8, 1.6, 0.27) for i in range(5)]
    reps += [(10.0, 1.2, 0.08)]
    reps += [(15.0 + i * 1.8, 1.6, 0.26) for i in range(3)]
    results.append(run_case("shallow rep + rest", reps, 21.0, 8, 1))
    # Noisy room.
    reps = [(1.0 + i * 1.8, 1.6, 0.25) for i in range(8)]
    results.append(run_case("noisy (10 dB SNR)", reps, 16.0, 8, 0, snr_db=10.0, seed=3))
    # Nobody there: must count nothing.
    results.append(run_case("empty floor", [], 10.0, 0, 0, seed=5))
    # Real recordings stored with takes.py must keep their counts.
    results.append(run_all())
    print("ALL PASS" if all(results) else "SOME FAILED")
