# Sonar Reps: notes for Claude Code

Hackathon project for Addy (call him Captain Addy). QMUL AI Hackathon, theme "Invisible AI". **Submission deadline: 4:00pm London time today (Sat 10 Oct 2026). Feature freeze 13:30.** The deliverable is a 3-minute video with a live demo.

## What this is

An iPhone counts push-ups by sonar, with no camera: it plays tones at 18.5, 19.1 and 19.7 kHz and tracks the phase of the echo off the chest. Read `README.md` and `sonar_core.py` first. `python simulate.py` must stay ALL PASS.

## House rules

- Never use em dashes anywhere: code comments, commit messages, README, UI text.
- Commit small and often, on `main`, with Addy's own git identity on this Mac (check `git config user.email`; it should be adityamitter15@gmail.com).
- Disclose prior work: ideas (not code) come from his PressPass project in `~/Developer/pushup-time`. Do not copy code from it.
- Stay below 20 kHz: iPhone speakers roll off sharply above it.

## Steps, in order

1. **Set up**
   - `python3 -m venv .venv && source .venv/bin/activate && pip install numpy scipy sounddevice soundfile matplotlib`
   - Run `python simulate.py`.
2. **GitHub**
   - Create a private repo `adityamitter15/sonar-reps` (`gh repo create adityamitter15/sonar-reps --private --source . --push`).
   - Or ask Addy to create it, then `git remote add origin https://github.com/adityamitter15/sonar-reps.git && git push -u origin main`.
3. **Go or no-go hardware check**
   - Run `python probe_live.py --check`. macOS will ask for microphone permission for the terminal.
   - Every tone needs 20 dB or more.
   - If one is weak, retry with fewer tones, for example `--tones 18500,19100`. Report the numbers to Addy.
4. **Live laptop test**
   - Run `python probe_live.py --record recordings/book.wav`.
   - Addy moves a book up and down 10 to 30 cm above the keyboard, 10 times.
   - Check the count. Then run `python analyze_wav.py recordings/book.wav --plot recordings/book.png` and look at the plot.
5. **Tune on real data**
   - If counts are wrong, tune `RepCounterConfig` (`min_depth_cm`, `start_down_cm`, `return_frac`) and `SonarConfig` fit settings.
   - Add each real recording as a regression test.
6. **iPhone app**
   - Create a new SwiftUI iOS app (or use XcodeGen) containing `ios/SonarEngine.swift` and `ios/SonarView.swift`, with `SonarView` as the root view.
   - Add to Info.plist: `NSMicrophoneUsageDescription` and `NSLocalNetworkUsageDescription`.
   - Sign with Addy's personal team and run on his iPhone.
   - University Wi-Fi blocks device-to-device UDP, so join the Mac to the iPhone's Personal Hotspot. The Mac's IP is then `ipconfig getifaddr en0`, usually 172.20.10.x.
   - Run `python phone_receiver.py --record recordings/phone1.wav` with the phone face-up on the floor and do push-ups over it.
7. **Fallback if streaming fails**
   - Use "Share last take" in the app to AirDrop the WAV to the Mac, then run `analyze_wav.py` on it.
8. **Demo screen**
   - Build a big, clean live display: depth gauge, rep count, red "NO REP" flash for shallow reps, and a "phone moved, not counting" warning.
   - Feed it from `phone_receiver.py`, for example with a small local WebSocket and one HTML page.
9. **Evaluation table**
   - Record labelled sets: 10 real reps, half reps, kneeling, shaking the phone, and an empty floor.
   - Report counted against true reps for each, plus how many cheats were blocked.
   - Put the table in the README.

Stop and ask Addy before anything irreversible, or if the hardware check fails.
