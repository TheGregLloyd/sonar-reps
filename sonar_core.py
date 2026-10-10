"""Sonar core: turn a phone's own speaker and microphone into a short-range sonar.

The speaker plays one or more continuous near-ultrasonic tones (18 to 20 kHz).
The microphone hears the direct sound plus echoes. A chest moving towards or
away from the phone changes the length of the echo path, which rotates the
phase of the echo. Tracking that phase gives the chest's movement to within a
few millimetres (the method used by LLAP, MobiCom 2016).

Pipeline, per tone:
    mic samples -> mix down to 0 Hz (I/Q) -> low-pass -> decimate to ~1 kHz
    -> remove the static part (direct path, floor, walls)
    -> phase change between samples -> path change -> displacement

Tones are combined with a median so one tone fading in a multipath null does
not break tracking. Everything is block based, so the same code runs on a live
stream or on a recorded file.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import List, Optional, Sequence

import numpy as np
from scipy.signal import butter, sosfilt, sosfilt_zi

SPEED_OF_SOUND = 343.0  # m/s at about 20 C


@dataclass
class SonarConfig:
    fs: int = 48_000
    tones_hz: Sequence[float] = (18_500.0, 19_100.0, 19_700.0)
    lowpass_hz: float = 250.0  # keeps Doppler up to about 2 m/s
    decim: int = 48  # 48 kHz -> 1 kHz baseband
    # Static-vector estimate: fit a circle to the last fit_window_s of I/Q.
    fit_window_s: float = 0.15
    fit_every: int = 10  # refit every N baseband samples (10 ms)
    fit_max_resid: float = 0.15  # median radial error as a share of radius
    fit_min_sweep_rad: float = np.pi  # samples must cover half a turn
    fit_min_radius: float = 1e-6  # echo must be above this (mic units)


class ToneTracker:
    """Phase tracker for one carrier tone, streaming."""

    def __init__(self, cfg: SonarConfig, f_hz: float):
        self.cfg = cfg
        self.f = f_hz
        self.wavelength = SPEED_OF_SOUND / f_hz
        self.sos = butter(4, cfg.lowpass_hz, fs=cfg.fs, output="sos")
        zi = sosfilt_zi(self.sos)
        self.zi_i = zi * 0.0
        self.zi_q = zi * 0.0
        self.n = 0  # global sample index
        fs_d = cfg.fs / cfg.decim
        self.win = max(40, int(cfg.fit_window_s * fs_d))
        self.buf: List[complex] = []
        self.static: Optional[complex] = None
        self.prev_dyn: Optional[complex] = None
        self.since_fit = 0

    def _fit_circle(self) -> Optional[complex]:
        """Centre of the circle the I/Q samples trace while the chest moves.
        The centre is the static vector (direct sound plus still echoes).
        Accept only when the samples sweep enough of the circle to pin it."""
        z = np.asarray(self.buf[-self.win:])
        x, y = z.real, z.imag
        A = np.column_stack([2 * x, 2 * y, np.ones_like(x)])
        b = x * x + y * y
        try:
            (cx, cy, k), *_ = np.linalg.lstsq(A, b, rcond=None)
        except np.linalg.LinAlgError:
            return None
        r2 = k + cx * cx + cy * cy
        if r2 <= 0:
            return None
        c = complex(cx, cy)
        r = np.sqrt(r2)
        resid = np.abs(np.abs(z - c) - r)
        if np.median(resid) > self.cfg.fit_max_resid * r:
            return None
        ang = np.unwrap(np.angle(z - c))
        if ang.max() - ang.min() < self.cfg.fit_min_sweep_rad:
            return None
        if r < self.cfg.fit_min_radius:
            return None
        return c

    def process(self, x: np.ndarray) -> np.ndarray:
        """Return displacement increments (metres, positive = towards phone)
        at the decimated rate for this block."""
        cfg = self.cfg
        idx = self.n + np.arange(len(x))
        w = 2.0 * np.pi * self.f / cfg.fs
        i = x * np.cos(w * idx)
        q = -x * np.sin(w * idx)
        i, self.zi_i = sosfilt(self.sos, i, zi=self.zi_i)
        q, self.zi_q = sosfilt(self.sos, q, zi=self.zi_q)
        keep = (idx % cfg.decim) == 0
        self.n += len(x)
        z = (i[keep] + 1j * q[keep]) * 2.0

        out: List[float] = []
        scale = self.wavelength / (4.0 * np.pi)  # phase -> reflector movement
        for zk in z:
            replay = 0.0
            self.buf.append(zk)
            if len(self.buf) > 4 * self.win:
                del self.buf[: len(self.buf) - 2 * self.win]
            self.since_fit += 1
            if len(self.buf) >= self.win and self.since_fit >= cfg.fit_every:
                self.since_fit = 0
                c = self._fit_circle()
                if c is not None:
                    if self.static is None:
                        # First lock: replay the buffered window so the start
                        # of the first movement is not lost.
                        self.static = c
                        prev = None
                        for zb in self.buf[-self.win:-1]:
                            d = zb - c
                            if prev is not None:
                                replay += np.angle(d * np.conj(prev)) * scale
                            prev = d
                        self.prev_dyn = prev
                    else:
                        self.static = c
            if self.static is None:
                out.append(0.0)
                continue
            dyn = zk - self.static
            inc = replay
            if self.prev_dyn is not None:
                # Phase rises as the echo path shortens; the path changes by
                # twice the reflector's movement.
                inc += np.angle(dyn * np.conj(self.prev_dyn)) * scale
            out.append(inc)
            self.prev_dyn = dyn
        return np.asarray(out)


class SonarTracker:
    """Combines several tones into one displacement stream."""

    def __init__(self, cfg: SonarConfig = SonarConfig()):
        self.cfg = cfg
        self.trackers = [ToneTracker(cfg, f) for f in cfg.tones_hz]
        self.position_m = 0.0

    @property
    def rate_hz(self) -> float:
        return self.cfg.fs / self.cfg.decim

    def process(self, x: np.ndarray) -> np.ndarray:
        """Feed raw mic samples, get cumulative displacement in metres
        (positive = closer to the phone) at about 1 kHz."""
        incs = np.vstack([t.process(x) for t in self.trackers])
        nz = incs != 0.0
        # Median over tones that saw motion; zero if none did.
        med = np.zeros(incs.shape[1])
        for k in range(incs.shape[1]):
            v = incs[nz[:, k], k]
            if len(v):
                med[k] = np.median(v)
        pos = self.position_m + np.cumsum(med)
        if len(pos):
            self.position_m = pos[-1]
        return pos


@dataclass
class Rep:
    t_start: float
    t_bottom: float
    t_end: float
    depth_cm: float
    valid: bool
    reason: str = ""


@dataclass
class RepCounterConfig:
    min_depth_cm: float = 15.0  # a rep must travel at least this far
    start_down_cm: float = 3.0  # movement that opens a rep
    return_frac: float = 0.35  # must come back within this share of depth
    smooth_hz: float = 4.0
    rest_reset_s: float = 0.8  # re-anchor the top after this long still


@dataclass
class RepCounter:
    """Hysteresis state machine on chest position (closer = larger)."""

    rate_hz: float
    cfg: RepCounterConfig = field(default_factory=RepCounterConfig)
    reps: List[Rep] = field(default_factory=list)

    def __post_init__(self):
        self.alpha = 1.0 - np.exp(-2.0 * np.pi * self.cfg.smooth_hz / self.rate_hz)
        self.y: Optional[float] = None
        self.state = "up"
        self.top = 0.0
        self.bottom = 0.0
        self.t = 0.0
        self.t_start = 0.0
        self.t_bottom = 0.0
        self.still_since = 0.0
        self.last_y = 0.0

    @property
    def count(self) -> int:
        return sum(r.valid for r in self.reps)

    def process(self, pos_m: np.ndarray) -> List[Rep]:
        new: List[Rep] = []
        dt = 1.0 / self.rate_hz
        for p in pos_m * 100.0:  # to cm
            self.t += dt
            if self.y is None:
                self.y = p
                self.top = p
            self.y += self.alpha * (p - self.y)
            y = self.y
            moving = abs(y - self.last_y) > 0.02  # cm per sample (about 20 cm/s)
            self.last_y = y
            if moving:
                self.still_since = self.t
            if self.state == "up":
                if y < self.top:
                    self.top = y
                if (self.t - self.still_since) > self.cfg.rest_reset_s:
                    self.top = y  # absorb drift while resting at the top
                if y - self.top > self.cfg.start_down_cm:
                    self.state = "down"
                    self.t_start = self.t
                    self.bottom = y
                    self.t_bottom = self.t
            else:
                if y > self.bottom:
                    self.bottom = y
                    self.t_bottom = self.t
                depth = self.bottom - self.top
                back = self.bottom - y
                if depth > 0 and back > (1.0 - self.cfg.return_frac) * depth and back > self.cfg.start_down_cm:
                    valid = depth >= self.cfg.min_depth_cm
                    rep = Rep(
                        t_start=self.t_start,
                        t_bottom=self.t_bottom,
                        t_end=self.t,
                        depth_cm=round(depth, 1),
                        valid=valid,
                        reason="" if valid else "too shallow",
                    )
                    self.reps.append(rep)
                    new.append(rep)
                    self.state = "up"
                    self.top = y
        return new


def tone_block(cfg: SonarConfig, n0: int, n: int, amp: float = 0.25) -> np.ndarray:
    """Transmit signal for samples [n0, n0+n). Double precision phase avoids
    the audible artefacts single precision causes."""
    idx = (n0 + np.arange(n)).astype(np.float64)
    out = np.zeros(n)
    for f in cfg.tones_hz:
        out += np.sin(2.0 * np.pi * f * idx / cfg.fs)
    return (amp / len(cfg.tones_hz)) * out
