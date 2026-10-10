# Sonar Reps: presentation pack

Everything needed to build the slides. Read "The story in one minute", then use the slide plan. Every number here is measured and is in `RESULTS.md`. Please do not round them up or add claims that are not on this page: the last section lists what we cannot say.

Deadline: submission is 16:00 London time, Sat 10 Oct 2026. The deliverable is a 3 minute video with a live demo. Hackathon theme: "Invisible AI".

## The story in one minute

Put your iPhone on the floor, face-up, and do push-ups over it. The phone plays three tones too high to hear and listens for the echo off your chest. As your chest moves, the echo's phase turns, and that gives the movement in centimetres. A small model that we trained today on our own labelled push-ups decides whether each movement was a full rep or a half rep. Full reps count. Half reps flash NO REP. If you pick the phone up or shake it, it stops counting.

No camera. Nothing to wear. Nothing to look at or tap during a set.

## We trained it: the facts

This is the "AI" part, and it is real. Use these exact figures.

- **Data.** 9 labelled sets recorded this afternoon on an iPhone 16 Pro Max, plus one from this morning. 55 labelled push-up movements: 40 full reps and 15 half reps.
- **Model.** Logistic regression (a small classifier), written in plain numpy. It looks at two numbers for each movement: the longer of its two strokes (way down, way back up) and how steady the echo was.
- **Test.** Each set was judged by a model trained on the other sets only, so it had never seen that set. Result: **54 of 55** full and half reps judged right. A fixed depth line, fitted the same way, gets 53 of 55.
- **Why it wins.** The sonar sometimes reads the way down short and sometimes the way up. One full rep read 8.6 cm down and 16 cm back up. A line on the way down refuses it. The model, which sees both, counts it. Chart: `img/both_strokes.png`.
- **In the product.** The live receiver uses the model by default. Checked by replaying recorded sets through it: fast set 10 of 10, deep set 5 of 5, half reps 0 of 10 counted, mixed set 4 of 5 full counted with all 5 half reps refused.
- **Honest caveats.** One person, one phone, one afternoon. We chose which two numbers to give the model using the same test, so 54 of 55 is a little flattering. We first trained a bigger model with seven numbers and three verdicts, and it was worse than the fixed line (21 of 72), so we simplified it. Saying that out loud is a strength.

One sentence for the slide: "A model trained on 55 of our own labelled push-ups judges every rep, and got 54 of 55 right on sets it had never seen."

## Slide plan

About 9 slides for 3 minutes. Images are in `img/`.

| # | Slide | Image | Say |
|---|---|---|---|
| 1 | **Sonar Reps.** Your phone counts push-ups with sound you cannot hear. | `app_set.png` | No camera is on. The phone is listening to an echo. |
| 2 | **The problem.** | photo or icons | Camera counters need you to film yourself. Motion counters count a shake as a rep. Both make you manage a screen mid-set. |
| 3 | **How it works.** | `pipeline.png` | Three tones at 18.5, 19.1 and 19.7 kHz. One full turn of echo phase is 0.9 cm of chest movement. A push-up is about 28 turns. |
| 4 | **Live demo.** | video, or `app_set.png`, `app_no_rep.png`, `app_phone_moved.png` | Full reps count. A half rep flashes NO REP. Pick the phone up and it stops counting. |
| 5 | **It sees depth.** | `trace_full_and_half.png` | Full, half, full, half. The trace is the chest. The half reps are refused. |
| 6 | **We trained it.** | `both_strokes.png`, `judge_vs_line.png` | 55 labelled push-ups, a small model, tested on sets it never saw: 54 of 55, against 53 for a fixed line. |
| 7 | **Results.** | `evaluation.png` | 39 of 40 full push-ups counted. 15 of 15 half reps refused. Shaking the phone: nothing counted. |
| 8 | **What it cannot do yet.** | bottom of `evaluation.png` | A hand waved over the phone like a chest still counts (8 of 10). Kneeling push-ups count (9 of 10). One false rep on an empty floor. One person tested. |
| 9 | **Invisible AI, and next.** | `app_result.png` | Invisible sensing, invisible interface, invisible footprint. Next: run it all on the phone, add distance so a hand cannot pass for a chest, more people. |

## Why this is "Invisible AI"

Three ways, each true of what we built:

1. **Invisible sensing.** The tones are above what most adults can hear. No camera, no wearable.
2. **Invisible interface.** No prompt, no chat, no buttons during a set. You press Start once and put the phone down. The model's verdict shows up only as a count going up or the words NO REP.
3. **Invisible footprint.** No image of you ever exists. Stored recordings keep only the band above 17.5 kHz, so they hold no speech.

After a set the app shows one line, the "coach note", for example "3 movements did not go deep enough, most of them at the end." It appears without being asked for and there is no chat. Be accurate about it: the verdicts behind it come from the trained model, and the sentence itself is simple rules, not a language model.

## Numbers you can quote

| Fact | Figure |
|---|---|
| Tones | 18.5, 19.1 and 19.7 kHz, from the iPhone's own speaker |
| Movement per turn of echo phase | 0.9 cm |
| Full push-ups counted, sets the model had not seen | 39 of 40 |
| Half reps refused | 15 of 15 |
| Fast set, 0.9 s per rep | 10 of 10 |
| Deep set | 5 of 5 |
| Phone picked up, slid, shaken | 0 counted |
| Model against a fixed line, unseen sets | 54 of 55 against 53 of 55 |
| Training data | 55 labelled movements: 40 full, 15 half |
| Speed | 57 times faster than real time, plain Python, one laptop core |
| Loud room | audible noise up to half of full scale did not change the count |
| Depth check | deep reps of roughly 30 cm (his estimate) read 17 to 24 cm |

## Images

| File | What it shows |
|---|---|
| `img/app_set.png` | The app during a set: count, depth column with the target line, bars per rep, the movement trace |
| `img/app_no_rep.png` | The full-screen NO REP flash |
| `img/app_phone_moved.png` | "Phone moved. Keep it still." and the greyed-out screen |
| `img/app_result.png` | After Stop: reps, coach note, no reps, time, depth per movement |
| `img/app_home.png` | Home: personal best and recent sets |
| `img/app_how_it_works.png` | The three-step guide shown on first launch |
| `img/app_icon.png` | The app icon |
| `img/pipeline.png` | Speaker to count, in six boxes |
| `img/trace_10_full.png` | The chest trace of 10 full push-ups, all counted |
| `img/trace_full_and_half.png` | Alternating full and half reps, with what was done and the verdict |
| `img/trace_10_half.png` | 10 half reps, none counted |
| `img/both_strokes.png` | Every labelled movement: way down against way up, with the model's line |
| `img/judge_vs_line.png` | 54 of 55 against 53 of 55 |
| `img/evaluation.png` | Every test set: what should count and what was counted |

The app screenshots are from the iPhone simulator playing a scripted set, so the numbers in them (26, 24, 27 cm) are sample values, not measurements. The charts are drawn from the real recordings by `make_charts.py`.

Still needed, from Addy: a photo or clip of the phone on the floor under someone doing a push-up, and a screen capture of the laptop demo screen (http://localhost:8765) during a live set.

## How to say the AI part, word for word

"Sound gives us the movement. That part is physics. Then a small model, trained on 55 of our own labelled push-ups, decides whether each one was a full rep. On sets it had never seen it got 54 of 55 right. You never talk to it and you never see it: it shows up as a count, or as NO REP."

If a judge asks "is that really AI?": "It is a small trained classifier, not a neural network, and we chose that on purpose. We tried a bigger one first, tested it properly, and it was worse. With 55 examples the small one is the honest choice."

## Do not say

- "Millimetre accurate" or any depth accuracy figure. Depth is good enough to sort full from half reps and probably reads short.
- "Cannot be cheated." A hand over the phone and kneeling push-ups get through. Shaking and half reps do not.
- "Runs entirely on the phone." Today the phone is the speaker and microphone, and a laptop on the same hotspot does the processing and sends the verdict back.
- "AI coach", "LLM" or "neural network". The coach note is rules on the model's verdicts.
- "Works on any phone." Tested on one iPhone 16 Pro Max and one MacBook Air.
- "Tested with users." One person.
- Any percentage. Give the counts: 39 of 40, 15 of 15, 54 of 55.

## Credit and prior work

The sonar tracking idea is published work (phase tracking on phones: LLAP; exercise recognition from a 20 kHz tone: Fu et al. 2018, linked in the main README). What is ours is counting and judging push-up reps on an iPhone, the trained rep judge, and the evaluation with its failures. The rep state machine design and the replay-testing approach reuse ideas, not code, from Addy's earlier PressPass project.
