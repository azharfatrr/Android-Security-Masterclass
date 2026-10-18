# Verification: Lab 03 (Spare Key Under the Mat)

Run this checklist on a clean emulator before the lab is marked **✅ Ready** in the labs index. This file is for the proofing run only and is not part of the site navigation.

Note: the key file read uses `run-as` (debug build). The logcat read needs nothing. The prefs write is asynchronous, so a one-second wait may be needed after the tap.

## Environment

| Field | Value |
|---|---|
| Date | 2026-10-17 |
| Emulator | ☑ Android Studio AVD (RootAVD34) ☐ Genymotion ☐ other: |
| Image / API level | Android 14 (API 34), Google Play image, Magisk-rooted |
| Host OS | Kali GNU/Linux Rolling |
| Terminal | ☐ Git Bash ☐ zsh ☐ PowerShell ☑ other: bash (Linux) |
| App build | ☑ trainer APK (`app-vulnerable-debug.apk` from release `apk-v2`, built from `main` @ `78dc5ad`) ☐ built from source (`:app-vulnerable:assembleDebug`) |
| Project repository on this machine? | ☑ yes (run step 9) ☐ no (skip step 9) |
| Lab 00 re-run first? | ☑ yes |

## Steps

| # | Action | Expected | Result |
|---|---|---|---|
| 1 | `adb devices` | emulator listed as `device` | ☑ pass — `emulator-5554	device` |
| 2 | `adb shell run-as com.hasantuncay.mobsec ls -la shared_prefs` (before tap) | listing or `No such file or directory`. Record which | ☑ pass — `ls: shared_prefs: No such file or directory` |
| 3 | In app: expand `MASVS-STORAGE`, open `MASWE-0003`, confirm title bar `MASWE-0003 (VULNERABLE)`. Record the dashboard subtitle and header wording (duplicate string resources may change them) | screen opens; subtitle labeled SECURE is covered by the note | ☑ pass — dashboard subtitle `MASWE-0003: Key Storage (SECURE)`; module screen subtitle `MASWE-0003: Key Storage (VULNERABLE)`; title bar `MASWE-0003 (VULNERABLE)` |
| 4 | Tap `1. Key in SharedPreferences / File`, then repeat step 2 | `crypto_key.xml` appears; note how long the write takes (`apply()` is async) | ☑ pass — `crypto_key.xml` (160 B) listed within ~2 s of the tap |
| 5 | `adb shell "run-as com.hasantuncay.mobsec cat shared_prefs/crypto_key.xml"` | XML with `<string name="aes_key">` and a base64 value. Record the exact XML shape (indentation, whether the value wraps) | ☑ pass — one line per element, four-space indent; the value sits on one line and ends with `&#10;    ` inside the element |
| 6 | The step 5 grep pipeline from the lab (`grep -o -E '[A-Za-z0-9+/]{40,}={0,2}' ... \| base64 -d \| wc -c`) | `32` | ☑ pass — printed `32` on the first try (bash on Linux, no `-D` variant needed) |
| 7 | `adb logcat -c`, tap `3. Plaintext Key Import`, then `adb logcat -d -s MASWE_0003_KEY_IMPORT` | one line: `Importing key: ` plus a readable string | ☑ pass — `D MASWE_0003_KEY_IMPORT: Importing key: plaintext_key_material_12345`, dumped ~1.5 s after the tap |
| 8 | Plain `adb logcat -d \| grep MASWE_0003` as the hint-3 fallback | same line visible | ☑ pass — same line |
| 9 | (repo only) `bash features/maswe0003/poc/adb_verify.sh` from repo root | `[!] CRITICAL VULNERABILITY CONFIRMED (MASWE-0003 / CWE-312):` with `the stored value decodes to 32 bytes of raw key material` and the log line; exit 0 | ☑ pass — confirmed line with the byte-count sentence and the log line; exit 0. Empty state before any tap: `[✓] No MASWE-0003 artifacts found yet.`, exit 1 |
| 10 | Screenshots 1 and 2 | XML + `32` on screen; log line shown | ☑ pass — shipped as `docs/labs/images/lab-03/terminal-steps-3-5.png` and `terminal-step-6.png` |
| 11 | A colleague follows the page without questions | no missing preconditions | ☑ pass — page followed start to finish without questions; no external colleague was available, so this is a self-review |

## Observations for the lab page

Record anything that differs from the page, including labels, wording, ordering, terminal output, and timing:

- Step 2: `shared_prefs` was absent before the first tap, so the fresh-install path prints `No such file or directory`.
- Step 4: `crypto_key.xml` (160 B) appeared within about 2 seconds of the tap.
- Step 5: the value sits on one line. The element ends with the encoded newline entity `&#10;` followed by four spaces, so the page now describes that instead of saying the value may wrap.
- Step 6: the pipeline printed exactly `32` in bash on Linux; the `base64 -D` variant from hint 2 was not needed.
- Step 7: the tag filter printed `--------- beginning of main` and then the line, about 1.5 seconds after the tap. The buffer did not rotate.
- Dashboard subtitle: `MASWE-0003: Key Storage (SECURE)`. The module screen subtitle reads `MASWE-0003: Key Storage (VULNERABLE)`.
- Result cards: both cards hand over the answer. Vector 1 shows "AES key serialized and written to shared_prefs/crypto_key.xml", the path, and under "ADB Verification" the command `adb shell run-as com.hasantuncay.mobsec \ cat shared_prefs/crypto_key.xml`. Vector 3 shows `adb logcat -s MASWE_0003_KEY_IMPORT`. The page now has a spoiler warning at step 2, since a student who reads the card loses the hunt.
- Step 9 script: prints the critical line with `the stored value decodes to 32 bytes of raw key material` and the log line; exit 0. Empty state works.
- Anything that confused the run: only the result-card spoilers, covered above.

## Verdict

- ☑ All steps passed on a clean run. Lab 03 is **✅ Ready** in `docs/labs/index.md` (2026-10-17).
- ☐ Differences found. Update the lab page, re-run the affected steps, then record the second run.
- ☐ Blocked by the app itself. Mark **⚠️ Known issue** in the index, note the blocker here, and open a repo issue.

Run history: the clean run (22:34–22:36) covered every step. Steps 5 and 7 were re-run after the wording updates; the output was identical.
