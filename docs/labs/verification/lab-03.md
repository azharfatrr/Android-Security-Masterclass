# Verification: Lab 03 (Spare Key Under the Mat)

Run this checklist on a clean emulator before the lab is marked **✅ Ready** in the labs index. This file is for the proofing run only and is not part of the site navigation.

Note: the key file read uses `run-as` (debug build). The logcat read needs nothing. The prefs write is asynchronous, so a one-second wait may be needed after the tap.

## Environment

| Field | Value |
|---|---|
| Date | |
| Emulator | ☐ Android Studio AVD ☐ Genymotion ☐ other: |
| Image / API level | |
| Host OS | |
| Terminal | ☐ Git Bash ☐ zsh ☐ PowerShell ☐ other: |
| App build | ☐ trainer APK ☐ built from source (`:app-vulnerable:assembleDebug`) |
| Project repository on this machine? | ☐ yes (run step 9) ☐ no (skip step 9) |
| Lab 00 re-run first? | ☐ yes |

## Steps

| # | Action | Expected | Result |
|---|---|---|---|
| 1 | `adb devices` | emulator listed as `device` | ☐ pass ☐ fail: |
| 2 | `adb shell run-as com.hasantuncay.mobsec ls -la shared_prefs` (before tap) | listing or `No such file or directory`. Record which | ☐ pass ☐ fail: |
| 3 | In app: expand `MASVS-STORAGE`, open `MASWE-0003`, confirm title bar `MASWE-0003 (VULNERABLE)`. Record the dashboard subtitle and header wording (duplicate string resources may change them) | screen opens; subtitle labeled SECURE is covered by the note | ☐ pass ☐ fail: |
| 4 | Tap `1. Key in SharedPreferences / File`, then repeat step 2 | `crypto_key.xml` appears; note how long the write takes (`apply()` is async) | ☐ pass ☐ fail: |
| 5 | `adb shell "run-as com.hasantuncay.mobsec cat shared_prefs/crypto_key.xml"` | XML with `<string name="aes_key">` and a base64 value. Record the exact XML shape (indentation, whether the value wraps) | ☐ pass ☐ fail: |
| 6 | The step 5 grep pipeline from the lab (`grep -o -E '[A-Za-z0-9+/]{40,}={0,2}' ... \| base64 -d \| wc -c`) | `32` | ☐ pass ☐ fail: |
| 7 | `adb logcat -c`, tap `3. Plaintext Key Import`, then `adb logcat -d -s MASWE_0003_KEY_IMPORT` | one line: `Importing key: ` plus a readable string | ☐ pass ☐ fail: |
| 8 | Plain `adb logcat -d \| grep MASWE_0003` as the hint-3 fallback | same line visible | ☐ pass ☐ fail: |
| 9 | (repo only) `bash features/maswe0003/poc/adb_verify.sh` from repo root | `[!] CRITICAL VULNERABILITY CONFIRMED (MASWE-0003 / CWE-312):` with `the stored value decodes to 32 bytes of raw key material` and the log line; exit 0 | ☐ pass ☐ fail: |
| 10 | Screenshots 1 and 2 | XML + `32` on screen; log line shown | ☐ pass ☐ fail: |
| 11 | A colleague follows the page without questions | no missing preconditions | ☐ pass ☐ fail: |

## Observations for the lab page

Record anything that differs from the page, including labels, wording, ordering, terminal output, and timing:

- Step 2: was `shared_prefs` absent before the first tap?
- Step 4: how long after the tap did `crypto_key.xml` appear?
- Step 5: exact XML shape. Did the base64 value sit on one line, wrap, or include a trailing newline inside the element? This affects the expected-output text.
- Step 6: did the pipeline print exactly `32` on this terminal? If `base64 -d` failed, note the shell and the `-D` variant.
- Step 7: did `-s MASWE_0003_KEY_IMPORT` print the line, or was the buffer already empty? Note the wait between tap and dump.
- Dashboard subtitle and header text: `Key Storage (SECURE)` or `Secure Implementation`? The duplicate string resources mean it may vary; record what rendered.
- Did any result card reveal more than the lab assumes (the vector 1 card may show an adb command of its own)?
- Step 9 script: printed lines, exit behavior. If the key line or byte count is missing (both XML shapes are tested in stub runs), stop and fix before shipping.
- Anything that confused the run:

## Verdict

- ☐ All steps passed on a clean run. Set Lab 03 to **✅ Ready** in `docs/labs/index.md` and date this file.
- ☐ Differences found. Update the lab page, re-run the affected steps, then record the second run.
- ☐ Blocked by the app itself. Mark **⚠️ Known issue** in the index, note the blocker here, and open a repo issue.
