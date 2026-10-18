# 🧪 Hands-on Labs

In a lab you take one MASWE module from `app-vulnerable`, run it on your emulator, and find the weakness yourself. Each lab is self-paced. The explanation sits at the end behind a fold, so you can try first and read afterwards.

## How a lab works

Every lab uses the same seven sections.

| Section | What it is for |
|---|---|
| A · Mission | What you are hunting. It does not give away the location. |
| B · Steps | The actions and commands you run. |
| C · Look & tell | Questions you answer yourself, in your own words. |
| D · Prove it | The check that turns "I saw something" into "I found it". |
| E · Your evidence | The screenshots and short description you hand in. |
| F · Stuck? | Hints, in order, that get you unstuck without the answer. |
| G · Reveal | What you found and why it matters. Open it after section E. |

!!! tip "Read the answer last"
    Capture your evidence before you open the Reveal. Reading the answer first spoils the exercise.

## Before you conduct any lab

Read this once, before Lab 00. Every lab assumes these rules.

1. **Use only your training environment.** Your own emulator and the vulnerable app. Never run these techniques against a real phone, a colleague's device, or any system you do not own or have written permission to test. The labs teach defense. Using them anywhere else is out of scope and may be illegal.
2. **You may break the app.** Crash it, wipe its data, reinstall it. That is part of the exercise.
3. **Find it yourself.** For the finding steps, do not read the project source code, and do not let the app's built-in demo buttons make the finding for you. Attack the installed app the way a real attacker would, with your own commands. Demos and helper scripts are only for confirming a finding you already have. The DOCS buttons in the app open the official OWASP pages for each module; treat them as a spoiler and stay out until your evidence is captured.
4. **Capture evidence as you go.** Take the screenshots before you move past a step. You cannot recreate them from memory later.
5. **Open hints in order, and the Reveal last.** Hints fix the environment. The Reveal explains the finding.
6. **If a step does not match the page, stop and report it.** Note exactly what you saw and tell your trainer. A failing step is a lab bug, not your mistake.

## What you hand in

For every lab:

1. One screenshot of the proof, showing the finding in the app or the terminal.
2. A short description of two or three sentences, in your own words: what is wrong, and why it matters.

Your evidence goes to your trainer or the training channel your organization uses.

## Before your first lab

Complete [Lab 00: Set up your lab machine](setup.md). It takes about 15 minutes and checks that your emulator, `adb`, and the vulnerable app are working.

## Available labs

| Lab | Module | Title | Time | Status |
|---|---|---|---|---|
| [Lab 00](setup.md) | - | Set up your lab machine | 15 min | ✅ Ready |
| [Lab 01](lab-01-insecure-private-storage.md) | MASWE-0001 | The Token That Stayed in Plain Sight | 25 min | ✅ Ready |
| [Lab 02](lab-02-outside-the-sandbox.md) | MASWE-0002 | Outside the Sandbox | 25 min | ✅ Ready |
| [Lab 03](lab-03-spare-key-under-the-mat.md) | MASWE-0003 | The Spare Key Under the Mat | 25 min | 🧪 Awaiting proof run |
| [Lab 04](lab-04-hardcoded-secrets.md) | MASWE-0004 | The Key That Never Left the Office | 25 min | 🧪 Awaiting proof run |
| [Lab 05](lab-05-what-the-logs-remember.md) | MASWE-0005 | What the Logs Remember | 30 min | 🧪 Awaiting proof run |
| [Lab 06](lab-06-the-backup-that-took-everything.md) | MASWE-0006 | The Backup That Took Everything | 30 min | 🧪 Awaiting proof run |
| [Lab 07](lab-07-encryption-in-name-only.md) | MASWE-0007 | Encryption in Name Only | 30 min | 🧪 Awaiting proof run |

Status: 🧪 draft waiting for a clean proof run · ✅ every step confirmed on a clean emulator · ⚠️ known issue, see the lab notes.

The table grows as labs are written and verified.
