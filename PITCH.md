# Sonar Reps: pitch and AI plan

Working notes for the 3 minute video. Every number here is from `RESULTS.md`. Anything not yet built or measured is marked **planned**. Do not say a planned thing is done.

## One line

Put your phone on the floor and train. It counts your push-ups and refuses the bad ones, using sound you cannot hear. No camera, no wearable, nothing to look at.

## The problem

- Camera rep counters need you to film yourself: framing, lighting, and a video of you in your bedroom or a changing room.
- Motion counters (phone in hand, watch on wrist) count a shake as a rep.
- Both make you manage a screen while you are trying to train.

## What it does today (measured)

- The phone plays three tones at 18.5, 19.1 and 19.7 kHz and tracks the phase of the echo off the chest.
- Confirmed set of 10 push-ups over an iPhone 16 Pro Max: **10 of 10 counted**, and a 6 cm shuffle into position was refused.
- Two more phone sets: 13 of 13 and 10 of 10 cycles found (true counts not yet confirmed).
- Live from phone to laptop screen: 0 packets lost in a 33 s set; 9 lost (48 ms of sound) in a 146 s session.
- It worked in a loud room: audible noise up to half of full scale did not change the count.
- The phone's motion sensor blocks counting while the phone itself is moved.
- The whole pipeline runs 57 times faster than real time in plain Python on one laptop core.

Not yet measured on the phone: half reps, kneeling push-ups, a hand waved over the phone, an empty floor. These are the labelled sets for the evaluation table.

## Where the AI is

Say this plainly, because a judge will ask: **the tracking is physics, not AI.** Echo phase to chest movement is signal processing, and it should stay that way, because it is exact and explainable.

The AI is the part that turns a movement trace into a verdict, and our own data shows a rule cannot do it:

| Set | Full push-ups read as |
|---|---|
| 10:59 | 9.8 to 16.3 cm |
| 11:22 | 20.6 to 24.9 cm |
| 11:25 | 9.3 to 17.5 cm |

A full rep in one set reads the same as a half rep would in another, so no fixed depth line separates them. Depth alone is the wrong question. The right question is "does this movement look like this person's full push-up?", and that is a learned judgement.

### The rep judge (planned, to build before the freeze)

1. **Find.** The existing state machine proposes every down and up, with a low bar so nothing is missed.
2. **Describe.** Each movement becomes a handful of numbers: depth, duration, time down against time up, peak speed each way, depth against this person's own reps so far in the set, how clean the echo was (so the model knows how far to trust the depth), and how much the phone moved.
3. **Judge.** A small model, trained on labelled sets recorded today, gives one of three verdicts: **full rep**, **half rep**, **not a push-up** (a hand, someone walking past, the phone being handled).
4. **Check.** One mixed set is kept out of training. The evaluation table reports the model and the fixed line side by side on that set.

If the model does not beat the fixed line on the held-out set, we ship the fixed line and say so in the video. A small honest model is a better pitch than a large claimed one.

How to say it: "Sound gives us the movement. A small model, trained on our own labelled sets and running with no cloud, decides what the movement was."

### After today (planned, roadmap only)

- **On the phone.** Tracker and judge move into the app, so the phone works alone. Today the phone is the speaker and microphone and a laptop on the same hotspot does the processing. Nothing goes to the internet.
- **Learned depth.** Correct the reading using echo quality, checked against a ruler. Today the depth scale varies by a factor of two between sets.
- **More movements.** Squats, sit-ups, breathing rate: same tones, same tracker, a new small model each.
- **A coach line.** After the set, one sentence from the per-rep numbers. The 11:25 set already shows why: its last three reps read 15.8, 13.2 and 9.3 cm, a visible fade.

## Why this is "Invisible AI"

Three ways, each one true of the build:

1. **Invisible sensing.** The tones sit above what most adults hear. There is no camera and nothing to wear.
2. **Invisible interface.** No prompt, no chat, no buttons during a set. You press start once and put the phone down. The AI shows up only as a count and the words NO REP.
3. **Invisible footprint.** No image of you ever exists. Stored recordings keep only the band above 17.5 kHz, so they hold no speech.

## How it is used

1. Phone face-up on the floor under your chest, volume at about three quarters.
2. Press Start. Hands off the phone.
3. Do push-ups. Each full rep counts. A half rep flashes NO REP. Moving the phone shows "PHONE MOVED, NOT COUNTING".
4. Press Stop. The set is saved on the phone.

## How it scales

- **Hardware that already exists.** It needs a speaker and a microphone that work near 19 kHz. Tested on two devices so far: a MacBook Air (tones 61 to 70 dB above the noise floor) and an iPhone 16 Pro Max. A two second self-test (`probe_live.py --check`) says go or no-go for a device and can fall back to fewer tones.
- **No cost per user.** No server is needed: 57 times real time in unoptimised Python leaves plenty of room on a phone.
- **Data that compounds.** Every labelled recording is stored once and used twice, as a training example and as a regression test (`takes.py`). More people, floors and clothing make the judge better without touching the tracker.
- **Personal without setup.** The judge compares each rep with your own earlier reps in the set, so it adapts in the first few.
- **One front end, many models.** A new exercise is a new labelled set and a new small model, not a new sensor.

What limits scale, said honestly: speakers differ between phones; two phones playing the same tones in one room would interfere (planned fix: each picks its own tones); some young people and most pets can hear these tones, so volume stays moderate; full volume makes the iPhone speaker sag and breaks the count.

## Use cases

- **Training alone at home.** A count you can trust without filming yourself.
- **Challenges between friends.** Reps that cannot be faked by shaking a phone or doing half reps.
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
| 1:35 | The trace on the laptop, the pipeline in one picture | Sound gives the movement, a small model gives the verdict. |
| 2:00 | The evaluation table | Counted against true, cheats blocked, model against fixed line. |
| 2:20 | Scale and use cases | Hardware everyone has, no cloud, no camera. |
| 2:40 | Limits and next | What is not solved yet, in our own words. |

## Questions a judge will ask

- **"Is this just signal processing?"** The tracking is, on purpose. The judging is a trained model, and here is the table showing why a rule fails and how the model does on a set it never saw.
- **"Is the technique new?"** No. Tracking movement from the phase of phone tones is published work (LLAP), and Doppler exercise recognition on a stock phone is too (Fu et al. 2018, linked in the README). What we add is counting and judging push-up reps on an iPhone, with cheat rejection and an evaluation.
- **"How accurate is the depth?"** Good enough to count, not good enough to quote: a few centimetres, and the scale varies between sets. That is exactly the problem the model is for.
- **"Does it work on any phone?"** Tested on one iPhone and one MacBook. The self-test is how a new device would be checked.
- **"Is the AI on the phone?"** Not today. Today the laptop does the processing over a local hotspot. It is light enough to move onto the phone, and that is the next step.

## Prior work, disclosed

Ideas, not code, from Addy's earlier PressPass project (a camera push-up counter): the rep state machine design and the replay evaluation approach.
