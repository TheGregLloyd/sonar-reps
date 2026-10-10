# Results log

Every hardware test, in the order it was run. Times are London time on Sat 10 Oct 2026. Newest last.

## About 10:32. Hardware check on the MacBook Air: GO

`python probe_live.py --check`, MacBook Air speakers and microphone at 48 kHz, output volume 50%, tone level 0.3.

| Tone | Above noise | Needed |
|---|---|---|
| 18.5 kHz | 61.2 dB | 20 dB |
| 19.1 kHz | 65.1 dB | 20 dB |
| 19.7 kHz | 69.5 dB | 20 dB |

No clipping (mic peak 0.194). All three tones are usable on the laptop.

## 10:39. Book over the laptop, 10 passes: 10 of 10 detected after one fix

`python probe_live.py --record recordings/book.wav --seconds 40`, same volume. A book was held about 30 cm above the keyboard, lowered to about 10 cm and raised again, 10 times.

| Counter | Passes found | Counted at the 15 cm line | Flagged too shallow |
|---|---|---|---|
| As first written (`return_frac` 0.35) | 7 | 6 | 1 |
| After the fix (`return_frac` 0.6) | 10 | 8 | 2 (13.1 and 14.8 cm) |
| After the fix, 10 cm line | 10 | 10 | 0 |

What happened:

- The tracker saw all 10 passes from the start. The plot shows 10 clean peaks.
- The counter merged passes whenever the book did not come most of the way back up, so four passes became one "rep" of 37.6 cm. A rep had to return 65% of its depth before it closed.
- Fix: a rep now closes after returning 40% of its depth. Each down and up is then judged on its own depth, so a partial return shows up as a shallow rep, not a merged one.
- Two passes read just under the 15 cm push-up line. That is about how far the book really moved, so the stored take uses a 10 cm line.

Signal quality over the 40 s take: carriers 70.4, 67.5 and 78.4 dB above the noise floor, no clipping. While the book moves, each tone's velocity matches the combined trace with a correlation of 0.89 to 0.96.

Known limits from this take:

- A single tone on its own drifts by tens of centimetres over 40 s. The median over three tones is what keeps the trace steady, so all three tones are needed.
- Depth is good to a few centimetres, not millimetres, at this volume. The band-limited copy of the same take reads up to 4 cm different on one pass.
- There was no ruler, so depth accuracy is unchecked. Pass 9 reads 34.6 cm, more than the intended 20 cm.

Stored as `takes/book_10.flac` (sonar band only, no room speech) with the plot in `takes/book_10.png`. `python simulate.py` replays it as a regression test.
