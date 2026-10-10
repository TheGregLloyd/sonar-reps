# Sonar Reps: pitch and AI plan

Working notes for the 3 minute video. Every number here is from `RESULTS.md`. Anything not yet built or measured is marked **planned**. Do not say a planned thing is done.

## One line

Put your phone on the floor and train. It counts your push-ups and refuses half reps, using sound you cannot hear. No camera, no wearable, nothing to look at.

## The problem

- Camera rep counters need you to film yourself: framing, lighting, and a video of you in your bedroom or a changing room.
- Motion counters (phone in hand, watch on wrist) count a shake as a rep.
- Both make you manage a screen while you are trying to train.

## What it does today (measured)

- The phone plays three tones at 18.5, 19.1 and 19.7 kHz and tracks the phase of the echo off the chest.
- A trained rep judge decides full rep or half rep. On sets it had not seen: **39 of 40 full push-ups counted, 15 of 15 half reps refused.** Normal pace 10 of 10, fast 10 of 10, deep 5 of 5.
- Picking up, sliding and shaking the phone: nothing counted. The phone's motion sensor blocks counting while the phone moves.
- Live from phone to laptop screen over a hotspot. The laptop sends its verdict back for the phone's own screen (not yet confirmed by eye on the device).
- It worked in a loud room: audible noise up to half of full scale did not change the count.
- The whole pipeline runs 57 times faster than real time in plain Python on one laptop core.

What it does not do, also measured:

- **A hand moved up and down over the phone counts as a rep** (8 of 10).
- **Kneeling push-ups count** (9 of 10). The sonar sees one surface moving, not the knees.
- An empty floor gave one false rep in 30 s, in the first 5 s.
- One full rep in a mixed set read too shallow and was refused.
- With the volume turned down it fails outright, so it now refuses to count and says why.

One person, one phone, one afternoon. The full table is in the README.

## Where the AI is

Say this plainly, because a judge will ask.

**The tracking is physics, not AI.** Echo phase to chest movement is signal processing, and it should stay that way, because it is exact and explainable.

**The verdict is a trained model, and it is in the product.** Every movement is measured on the way down and on the way back up, and a small classifier trained on our own labelled push-ups says full rep or half rep.

| Tested on sets it had not seen | Full and half reps judged right |
|---|---|
| Rep judge | 54 of 55 |
| One fixed depth line, fitted the same way | 53 of 55 |

- Trained on 55 labelled movements, 40 full and 15 half, recorded today.
- Logistic regression on two numbers: the larger of the two strokes, and how steady the echo was. It is a handful of numbers in `judge.json`, so it will run on the phone as it is.
- It wins because the sonar sometimes reads one stroke short. One full rep read 8.6 cm down and 16.2 cm back up: the line refuses it, the model counts it.

How we got there, which is worth telling: the first model had seven inputs and three verdicts (full, half, not a push-up) and scored 21 of 72, far worse than the line. A hand wave gave the same numbers as a push-up, so "not a push-up" could not be learned. We dropped that verdict, measured the way back up, and kept the two inputs that scored best.

Caveats to state if asked: one person; 55 movements; the inputs were chosen on the same test, so 54 of 55 is somewhat optimistic.

**The coach note.** After a set the app shows one line of advice, for example "3 movements did not go deep enough, most of them at the end." It needs no prompt and there is no chat, so it fits the theme. It is rules on the model's verdicts, not a language model. Do not call it an AI coach.

How to say it: "Sound gives us the movement. A small model, trained on 55 of our own labelled push-ups, decides whether each one was a full rep. On sets it had never seen it got 54 of 55 right. You never talk to it: it shows up as a count, or as NO REP."

### After today (planned, roadmap only)

- **On the phone.** The tracker moves into the app, so the phone works alone. Today the phone is the speaker and microphone and a laptop on the same hotspot does the processing. Nothing goes to the internet.
- **Distance, not just movement.** Chirps in the same band, to tell a chest at 30 cm from a hand at 10 cm. This is what the judge needs before it can learn a third verdict, not a push-up.
- **More data.** More people, floors and phones. Every labelled take is already both a training example and a regression test.
- **More movements.** Squats, sit-ups, breathing rate: same tones, same tracker.
- **A coach line.** After the set, one sentence from the per-rep numbers, for example a fade over the last three reps.

## Why this is "Invisible AI"

Three ways, each one true of the build:

1. **Invisible sensing.** The tones sit above what most adults hear. There is no camera and nothing to wear.
2. **Invisible interface.** No prompt, no chat, no buttons during a set. You press start once and put the phone down. All you see is a count and the words NO REP.
3. **Invisible footprint.** No image of you ever exists. Stored recordings keep only the band above 17.5 kHz, so they hold no speech.

## How it is used

1. Phone face-up on the floor under your chest, volume at about three quarters.
2. Press Start. Hands off the phone.
3. Do push-ups. Each full rep counts. A half rep flashes NO REP. Moving the phone shows "PHONE MOVED, NOT COUNTING".
4. Press Stop. The set is saved on the phone.

## How it scales

- **Hardware that already exists.** It needs a speaker and a microphone that work near 19 kHz. Tested on two devices so far: a MacBook Air (tones 61 to 70 dB above the noise floor) and an iPhone 16 Pro Max. A two second self-test (`probe_live.py --check`) says go or no-go for a device and can fall back to fewer tones.
- **No cost per user.** No server is needed: 57 times real time in unoptimised Python leaves plenty of room on a phone.
- **Data that compounds.** Every labelled recording is stored once and used twice, to train the rep judge and as a regression test (`takes.py`). Today that is 13 takes.
- **One front end, many movements.** A new exercise is a new labelled set and a new line or small model, not a new sensor.

What limits scale, said honestly: speakers differ between phones; two phones playing the same tones in one room would interfere (planned fix: each picks its own tones); some young people and most pets can hear these tones, so volume stays moderate; full volume makes the iPhone speaker sag and breaks the count.

## Use cases

- **Training alone at home.** A count you can trust without filming yourself.
- **Challenges between friends.** Reps that cannot be faked by shaking a phone or doing half reps. A hand waved over the phone still can fake one today.
- **Fitness tests.** School PE, club and service entry tests, where depth matters and counting is argued over.
- **Where cameras are not welcome.** Gyms, changing rooms, shared flats, schools.
- **Physio and remote coaching.** Did the sets happen, and through what range, with no video of someone's home. Not a medical device.
- **Low vision.** Nothing on screen is needed during a set (spoken count is planned, not built).

## The video, 3 minutes

| Time | Shot | Line |
|---|---|---|
| 0:00 | Phone on the floor, push-ups, count rising | "There is no camera on. This phone is counting with sound you cannot hear." |
| 0:20 | The problem, three quick cuts | Film yourself, or get fooled by a shake. |
| 0:45 | Live: 5 full reps | Count goes 1 to 5. |
| 1:10 | Live: one half rep | NO REP flash. |
| 1:20 | Live: pick the phone up and shake it | "Phone moved, not counting." |
| 1:35 | The trace on the laptop, the pipeline in one picture | Sound gives the movement, a model we trained gives the verdict. |
| 2:00 | The evaluation table | 39 of 40 full, 15 of 15 half refused, shaking blocked. The model against a fixed line: 54 to 53 of 55. |
| 2:20 | Scale and use cases | Hardware everyone has, no cloud, no camera. |
| 2:40 | Limits and next | A hand and kneeling get through. Chirps for distance are next. |

## Questions a judge will ask

- **"Where is the AI?"** A classifier trained on 55 of our own labelled push-ups judges every rep. On sets it had not seen it got 54 of 55 right, one better than a fixed line. It is small on purpose: the bigger one we tried first lost.
- **"Is this just signal processing?"** The tracking is, on purpose. The verdict is a trained model, tested on held-out sets.
- **"Can I cheat it?"** Shaking the phone and half reps: no. Waving a hand over it: yes, today. Kneeling: yes.
- **"Is the technique new?"** No. Tracking movement from the phase of phone tones is published work (LLAP), and Doppler exercise recognition on a stock phone is too (Fu et al. 2018, linked in the README). What we add is counting and judging push-up reps on an iPhone, with an evaluation that includes the failures.
- **"How accurate is the depth?"** Good enough to sort full from half reps, not good enough to quote. A deep rep of roughly 30 cm read 17 to 24 cm.
- **"Does it work on any phone?"** Tested on one iPhone and one MacBook. The self-test is how a new device would be checked.
- **"Is the processing on the phone?"** Not today. The laptop does it over a local hotspot. It is light enough to move onto the phone, and that is the next step.

## Prior work, disclosed

Ideas, not code, from Addy's earlier PressPass project (a camera push-up counter): the rep state machine design and the replay evaluation approach.
