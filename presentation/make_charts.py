"""Charts for the presentation, drawn from the stored takes and the trained judge.

  python presentation/make_charts.py

Writes PNGs into presentation/img/. Every number in them is recomputed here.
"""

import json
import sys
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import soundfile as sf

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))
import judge as J  # noqa: E402
from sonar_core import SonarConfig, SonarTracker  # noqa: E402
from takes import LABELS, TAKES  # noqa: E402

OUT = Path(__file__).resolve().parent / "img"
BG, CARD, TEXT, MUTED, ACCENT, RED, AMBER = "#161615", "#201F1D", "#EDECE8", "#9B9993", "#8FA3F5", "#EE6F63", "#D9A445"
plt.rcParams.update({"figure.facecolor": BG, "axes.facecolor": CARD, "savefig.facecolor": BG, "text.color": TEXT,
                     "axes.labelcolor": MUTED, "xtick.color": MUTED, "ytick.color": MUTED, "axes.edgecolor": "#302F2C",
                     "font.size": 13, "axes.spines.top": False, "axes.spines.right": False})
takes = {t["name"]: t for t in json.loads(LABELS.read_text())}
model = J.Judge.load()


def run(name):
    """Trace in cm and the judged movements of one stored take."""
    t = takes[name]
    x, fs = sf.read(TAKES / t["file"], dtype="float64", always_2d=True)
    tr = SonarTracker(SonarConfig(fs=fs, tones_hz=tuple(t["tones_hz"])))
    finder = J.MovementFinder(tr.rate_hz)
    pos, moves = [], []
    for i in range(0, len(x), 1024):
        p = tr.process(x[i:i + 1024, 0])
        pos.append(p)
        moves += finder.process(p, tr.power, tr.steadiness)
    moves += finder.flush()
    pos = np.concatenate(pos) * 100.0
    return np.arange(len(pos)) / tr.rate_hz, pos, moves


def trace(name, title, file, truth=None):
    t, pos, moves = run(name)
    fig, ax = plt.subplots(figsize=(12, 4.2))
    ax.plot(t, pos, color=TEXT, lw=1.8)
    counted = 0
    for k, (r, f) in enumerate(moves):
        full = model.verdict(f) == "full"
        counted += full
        ax.axvspan(r.t_start, r.t_end, color=ACCENT if full else RED, alpha=0.28, lw=0)
        mid = (r.t_start + r.t_end) / 2
        ax.text(mid, pos.max() + 1.2, "REP" if full else "NO REP", ha="center", va="bottom", fontsize=9.5,
                color=ACCENT if full else RED, fontweight="bold")
        if truth and k < len(truth):
            ax.text(mid, pos.max() + 4.0, truth[k], ha="center", va="bottom", fontsize=9.5, color=MUTED)
    if truth:
        ax.text(t[0], pos.max() + 4.0, "done:", ha="left", va="bottom", fontsize=9.5, color=MUTED)
    ax.set_ylim(pos.min() - 2, pos.max() + (8.5 if truth else 5))
    ax.set_xlabel("seconds")
    ax.set_ylabel("chest movement towards the phone (cm)")
    ax.set_title(title.format(counted=counted), loc="left", fontsize=15, fontweight="bold")
    fig.tight_layout()
    fig.savefig(OUT / file, dpi=170)
    plt.close(fig)
    return counted, len(moves)


def strokes(file):
    data = J.load_takes()
    fig, ax = plt.subplots(figsize=(7.4, 7))
    for lab, col, mk in (("full", ACCENT, "o"), ("half", RED, "s")):
        pts = [(f["depth_cm"], f["up_cm"]) for _, fs, ls, _ in data for f, l in zip(fs, ls) if l == lab]
        ax.scatter(*zip(*pts), s=70, color=col, marker=mk, label=f"{lab} rep ({len(pts)})", alpha=0.9, edgecolor=BG)
    ln = model.line_cm()
    ax.plot([ln, ln, 0], [0, ln, ln], color=AMBER, lw=2, ls="--", label=f"trained judge, about {ln:.0f} cm")
    ax.axvline(12, color=MUTED, lw=1.2, ls=":", label="old fixed line, 12 cm on the way down")
    ax.set_xlim(0, 30); ax.set_ylim(0, 30)
    ax.set_xlabel("read on the way down (cm)"); ax.set_ylabel("read on the way back up (cm)")
    ax.set_title("Why the judge looks at both strokes", loc="left", fontsize=15, fontweight="bold")
    ax.legend(frameon=False, loc="lower right", fontsize=11)
    fig.tight_layout(); fig.savefig(OUT / file, dpi=170); plt.close(fig)


def bars(rows, title, file, note=""):
    fig, ax = plt.subplots(figsize=(11, 0.62 * len(rows) + 1.6))
    y = np.arange(len(rows))[::-1]
    ax.barh(y + 0.19, [r[1] for r in rows], 0.36, color=MUTED, label="should count")
    ax.barh(y - 0.19, [r[2] for r in rows], 0.36, color=[ACCENT if r[1] == r[2] else RED for r in rows], label="counted")
    for yy, r in zip(y, rows):
        ax.text(max(r[1], r[2]) + 0.25, yy, f"{r[2]} counted, {r[1]} should", va="center", fontsize=11, color=TEXT)
    ax.set_yticks(y); ax.set_yticklabels([r[0] for r in rows], color=TEXT)
    ax.set_xlim(0, 15); ax.set_xticks([])
    ax.spines["bottom"].set_visible(False)
    ax.set_title(title, loc="left", fontsize=15, fontweight="bold")
    if note:
        fig.text(0.01, 0.01, note, fontsize=10, color=MUTED)
    fig.tight_layout(rect=(0, 0.03, 1, 1)); fig.savefig(OUT / file, dpi=170); plt.close(fig)


def versus(file, model_right, line_right, total):
    fig, ax = plt.subplots(figsize=(7.4, 4.2))
    ax.bar(["fixed depth line", "trained judge"], [line_right, model_right], color=[MUTED, ACCENT], width=0.55)
    for i, v in enumerate((line_right, model_right)):
        ax.text(i, v + 0.4, f"{v} of {total}", ha="center", fontsize=16, fontweight="bold")
    ax.set_ylim(0, total + 6); ax.set_yticks([])
    ax.spines["left"].set_visible(False)
    ax.set_title("Full and half reps judged right,\non sets the judge had never seen", loc="left", fontsize=15, fontweight="bold")
    fig.tight_layout(); fig.savefig(OUT / file, dpi=170); plt.close(fig)


def pipeline(file):
    steps = [("Speaker", "3 tones\n18.5 to 19.7 kHz"), ("Chest", "echo comes back"), ("Microphone", "48 kHz"),
             ("Phase of the echo", "one turn =\n0.9 cm of movement"), ("Trained judge", "full rep\nor half rep"), ("Count", "or NO REP")]
    fig, ax = plt.subplots(figsize=(14, 2.6))
    ax.set_xlim(0, len(steps)); ax.set_ylim(0, 1); ax.axis("off")
    for i, (a, b) in enumerate(steps):
        hot = a == "Trained judge"
        ax.add_patch(plt.Rectangle((i + 0.06, 0.12), 0.8, 0.76, color=ACCENT if hot else CARD, ec="#302F2C", lw=1.2))
        ax.text(i + 0.46, 0.63, a, ha="center", va="center", fontsize=13, fontweight="bold", color=BG if hot else TEXT)
        ax.text(i + 0.46, 0.34, b, ha="center", va="center", fontsize=10.5, color=BG if hot else MUTED)
        if i < len(steps) - 1:
            ax.annotate("", xy=(i + 1.06, 0.5), xytext=(i + 0.86, 0.5), arrowprops=dict(arrowstyle="->", color=MUTED, lw=1.5))
    fig.tight_layout(); fig.savefig(OUT / file, dpi=170); plt.close(fig)


def unseen_counts():
    """What the judge counts in each take when that take was left out of its training."""
    data = J.load_takes()

    def pushups(d):
        return [f for f, l in zip(d[1], d[2]) if l != "none"], [l for l in d[2] if l != "none"]

    out = {}
    for k, (take, feats, labels, _) in enumerate(data):
        j = J.Judge.fit([f for i, d in enumerate(data) if i != k for f in pushups(d)[0]],
                        [l for i, d in enumerate(data) if i != k for l in pushups(d)[1]])
        out[take["name"]] = sum(j.verdict(f) == "full" for f in feats)
    return out


if __name__ == "__main__":
    full = trace("set_full", "10 full push-ups: {counted} counted", "trace_10_full.png")
    mixed = trace("set_mixed", "Full, half, full, half...: {counted} counted, the half reps refused", "trace_full_and_half.png",
                  truth=["full", "half"] * 5)
    half = trace("set_half", "10 half reps: {counted} counted", "trace_10_half.png")
    strokes("both_strokes.png")
    pipeline("pipeline.png")
    info = json.loads(J.MODEL.read_text())
    m, total = (int(v) for v in info["unseen_right"].split(" of "))
    versus("judge_vs_line.png", m, int(info["depth_line_right"].split(" of ")[0]), total)
    kneel = sum(model.verdict(f) == "full" for _, f in run("set_kneeling")[2])
    c = unseen_counts()
    rows = [("10 full push-ups, normal pace", 10, c["set_full"]), ("10 full push-ups, fast", 10, c["set_full_fast"]),
            ("5 deep push-ups", 5, c["set_deep"]), ("10 full push-ups, morning set", 10, c["phone_pushups_3"]),
            ("5 full + 5 half, alternating", 5, c["set_mixed"]), ("10 half reps", 0, c["set_half"]),
            ("Phone picked up and shaken", 0, c["set_phone_handled"]), ("Empty floor, 30 s", 0, c["set_empty_floor"]),
            ("Hand waved over the phone 10 times", 0, c["set_hand_wave"]), ("10 kneeling push-ups", 0, kneel)]
    bars(rows, "What counts and what does not", "evaluation.png",
         "Each set judged by a model that was not trained on it. One person, one iPhone, one afternoon.")
    print("unseen-take counts:", c, "kneeling", kneel)
