# Verification: Lab 02 (Outside the Sandbox)

Run this checklist on a clean emulator before the lab is marked **✅ Ready** in the labs index. This file is for the proofing run only and is not part of the site navigation.

Note: the read steps are plain adb shell commands. No root and no `run-as` should be needed on an AOSP or Google APIs emulator. The `adb root` fallback in hint 1 stays untested unless the shell user is denied.

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
| 2 | `adb shell ls -la /sdcard/Android/data/com.hasantuncay.mobsec/files/` (before tap) | `No such file or directory` on a fresh install. Record the exact message | ☐ pass ☐ fail: |
| 3 | In app: expand `MASVS-STORAGE`, open `MASWE-0002`, confirm title bar `MASWE-0002 (VULNERABLE)`. Record the subtitle wording. Do **not** tap DOCS | screen opens; subtitle mismatch (SECURE) present and covered by the note | ☐ pass ☐ fail: |
| 4 | Tap `1. External Storage Sensitive Data Leak`, then repeat step 2 | folder created, `maswe0002_plaintext.json` listed; note the owner/group columns | ☐ pass ☐ fail: |
| 5 | `adb shell cat /sdcard/Android/data/com.hasantuncay.mobsec/files/maswe0002_plaintext.json` | JSON with `auth_token` (starts `eyJ...`, ends with three dots) and `pan` (16 digits starting `4532`) | ☐ pass ☐ fail: |
| 6 | `adb pull /sdcard/Android/data/com.hasantuncay.mobsec/files/maswe0002_plaintext.json .` then `cat` it | `1 file pulled, 0 skipped.` and the same JSON from the host | ☐ pass ☐ fail: |
| 7 | Tap `3. External Storage + Key on Filesystem`, then `ls -la` again | `maswe0002_key_on_fs.enc` and `maswe0002_secret.key` listed | ☐ pass ☐ fail: |
| 8 | `adb shell od -An -tx1 /sdcard/Android/data/com.hasantuncay.mobsec/files/maswe0002_secret.key` (and once on the `.enc`) | two hex lines of 32 bytes for the key; ciphertext bytes for the `.enc` | ☐ pass ☐ fail: |
| 9 | (repo only) `bash features/maswe0002/poc/adb_verify.sh` from repo root | `[!] CRITICAL VULNERABILITY CONFIRMED (MASWE-0002 / CWE-732):` with the token, pan, and key bytes; exit 0. Run once before tapping anything to see the empty-state message | ☐ pass ☐ fail: |
| 10 | Screenshots 1 and 2 | token and pan readable; key hex shown | ☐ pass ☐ fail: |
| 11 | A colleague follows the page without questions | no missing preconditions; DOCS warning found in time | ☐ pass ☐ fail: |

## Observations for the lab page

Record anything that differs from the page, including labels, wording, ordering, terminal output, and timing:

- Step 2 before-tap output: exact message on this image.
- Step 5: did the JSON print in the exact shape shown (indentation, two fields)? Note the exact key order.
- Was the read really possible without root and without `run-as` on this image? If permission was denied, record the image and the fallback used.
- Step 8: did `od` exist on the device shell? Was the output two lines of 16 bytes?
- Did the dashboard subtitle really read `MASWE-0002: Insecure Storage (SECURE)`?
- DOCS button: present on the row? Did the lab's warning arrive before any accidental tap?
- Result card text after the taps: did it reveal more than the lab assumes (paths, the word plaintext)?
- Step 9 script: printed lines, exit behavior. If the token or key line is missing after both taps, stop and fix the script before shipping.
- Anything that confused the run:

## Verdict

- ☐ All steps passed on a clean run. Set Lab 02 to **✅ Ready** in `docs/labs/index.md` and date this file.
- ☐ Differences found. Update the lab page, re-run the affected steps, then record the second run.
- ☐ Blocked by the app itself. Mark **⚠️ Known issue** in the index, note the blocker here, and open a repo issue.
