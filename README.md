# Sonar Reps

Your phone already has a sonar. Sonar Reps plays near-ultrasonic tones (18.5 to 19.7 kHz) from the iPhone speaker and listens for the echo off your chest. The phase of that echo tracks your movement to the millimetre, so the phone counts push-ups and measures their depth with no camera, no wearable and no special hardware. Built at the QMUL AI Hackathon (Invisible AI), October 2026.

## Why sonar

- **No camera.** Nothing records you, it works in the dark, and there is no framing or lighting to get right.
- **Hard to cheat.** Camera and motion counters are fooled by shaking the phone. Here a real chest has to move a real distance, and the phone's motion sensor blocks counting if the phone itself moves.
- **Any phone.** It uses the speaker and microphone every phone already has.

## How it works

```
speaker: 3 tones (18.5, 19.1, 19.7 kHz)  ->  chest  ->  mic
mic -> mix each tone to 0 Hz (I/Q) -> low-pass, 1 kHz
    -> remove the static path (circle fit, as in LLAP)
    -> phase change -> path change -> chest movement (lambda/4pi per radian)
    -> median over tones -> rep state machine (depth, return, rest)
```

At 19 kHz the wavelength is 1.8 cm, so one full turn of echo phase is 0.9 cm of chest movement. A push-up is about 25 cm, roughly 28 turns.

## Feasibility, checked

- **Standard phones can do it.** A 2018 study recognised squats and other exercises from the Doppler of a 20 kHz tone on a stock Nexus 5X, with 91% accuracy for squats ([Fu et al., Informatics](https://www.mdpi.com/2227-9709/5/2/24)). It did not count reps or test push-ups.
- **iPhone frequency limit.** iPhone 7 and 8 loopback tests drop sharply above 20 kHz, and their authors used 18.5 kHz ([SonicPACT](https://arxiv.org/pdf/2012.04770)). That is why our tones stay below 20 kHz.
- **Millimetre tracking from phase.** LLAP tracked fingers to millimetres with phone speakers and mics ([LLAP code](https://github.com/Samsonsjarkal/LLAP)).
- **Audibility.** 18.5 kHz is inaudible to most adults, but some young people hear a faint whine. Keep the volume moderate.

## Run it

```sh
pip install numpy scipy sounddevice soundfile matplotlib
python simulate.py                       # synthetic tests, no hardware
python probe_live.py --check             # can this laptop do 19 kHz?
python probe_live.py                     # live tracking on the laptop
python phone_receiver.py                 # live tracking from the iPhone
python analyze_wav.py take.wav --plot take.png
python takes.py                          # replay the real recordings in takes/
```

iPhone: add `ios/SonarEngine.swift` and `ios/SonarView.swift` to an app target, add `NSMicrophoneUsageDescription` and `NSLocalNetworkUsageDescription` to Info.plist, run, type the Mac's IP and press Start. If the university Wi-Fi blocks the stream, turn on the iPhone's Personal Hotspot and join it from the Mac.

## Status

- Synthetic tests pass: steady, fast (0.7 s) and noisy sets, a shallow rep flagged as no rep, an empty floor counting zero.
- Laptop test on real hardware: all 10 passes of a book over a MacBook Air were detected. See `RESULTS.md`.
- Not yet tested on an iPhone. Depth reads about 10% low on synthetic data.

## Prior work

Reuses ideas, not code, from my earlier PressPass project (camera push-up counter): the rep state machine design and the replay evaluation approach.
