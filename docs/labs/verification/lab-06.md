# Verification: Lab 06 (The Backup That Took Everything)

Run this checklist on a clean emulator before the lab is marked **✅ Ready** in the labs index. This file is for the proofing run only and is not part of the site navigation.

Note: steps 1 through 6 need no root; only `run-as` is used (works on the debug build). Step 7 (`adb backup`) is device-dependent: some images produce a real archive, others answer `Backup disabled`. Record whichever outcome appears; the finding does not depend on it.

## Environment

| Field | Value |
|---|---|
| Date | |
| Emulator | ☐ Android Studio AVD ☐ Genymotion ☐ other: |
| Image / API level | |
| Host OS | |
| Terminal | ☐ Git Bash ☐ zsh ☐ PowerShell ☐ other: |
| App build | ☐ trainer APK ☐ built from source (`:app-vulnerable:assembleDebug`) |
| Project repository on this machine? | ☐ yes (run step 8) ☐ no (skip step 8) |
| Lab 00 re-run first? | ☐ yes |

## Steps

| # | Action | Expected | Result |
|---|---|---|---|
| 1 | `adb devices` | emulator listed as `device` | ☐ pass ☐ fail: |
| 2 | `adb shell dumpsys package com.hasantuncay.mobsec \| grep -i ALLOW_BACKUP` | one line containing `ALLOW_BACKUP`. Record the field shape (`flags=[` or `pkgFlags=`) and the API level | ☐ pass ☐ fail: |
| 3 | In app: expand `MASVS-STORAGE`, open `MASWE-0006`, confirm title bar `MASWE-0006 (VULNERABLE)`. Record the subtitle wording | screen opens; subtitle says Secure and the note covers it | ☐ pass ☐ fail: |
| 4 | Tap `2. ADB Local Backup (adb backup)`, then `ls -la files` and `cat files/maswe0006_local_backup_vault.db` | file `maswe0006_local_backup_vault.db` exists; one line with `PAN=` (16 digits) and `CVV=` (3 digits). Record the exact separators | ☐ pass ☐ fail: |
| 5 | Tap `3. Device-to-Device Migration`, then `cat files/maswe0006_migration_credentials.json` | JSON with `refreshToken` and `masterKey` (starting `0x`). Record the exact shape | ☐ pass ☐ fail: |
| 6 | Tap `1. Auto Backup — No Exclusion Rules`, then `ls -la shared_prefs` and `cat shared_prefs/maswe0006_cloud_backup_session.xml` | `maswe0006_cloud_backup_session.xml` with `auth_token` and `user_email` entries. Note how long the async write takes | ☐ pass ☐ fail: |
| 7 | `adb backup -f maswe0006_loot.ab -noapk com.hasantuncay.mobsec`, confirm the device dialog | EITHER an archive (`ls -l`, `head -c 24` shows `ANDROID BACKUP`) OR a refusal (`Backup disabled` / empty file). Record the outcome verbatim | ☐ pass ☐ fail: |
| 8 | (repo only) `bash features/maswe0006/poc/adb_verify.sh` from repo root | `[!] CRITICAL VULNERABILITY CONFIRMED (MASWE-0006 / CWE-200):` with flag line, card line, session keys line, records line, prefs note; exit 0. Also run once before tapping for the empty-state message | ☐ pass ☐ fail: |
| 9 | Screenshots 1 and 2 (and 3 if an archive appeared) | ALLOW_BACKUP line + file listing; card data + a second file; archive header if present | ☐ pass ☐ fail: |
| 10 | A colleague follows the page without questions | no missing preconditions | ☐ pass ☐ fail: |

## Observations for the lab page

Record anything that differs from the page, including labels, wording, ordering, terminal output, and timing:

- Step 2: exact dumpsys line and field shape; anything unusual about the flags list.
- Step 3: exact subtitle wording; result card text after the taps (does any card name the files before the learner finds them?).
- Step 4 to 6: exact file contents and labels; async write delay for preferences; whether the prefs XML shows other modules' entries in the same file.
- Step 7: dialog text; outcome; if an archive appeared, what `head -c 24` printed and whether the `tar` trick from hint 3 lists file names or only warnings.
- Step 8: both script outputs and exit behaviors.
- Anything that confused the run:

## Verdict

- ☐ All steps passed on a clean run. Set Lab 06 to **✅ Ready** in `docs/labs/index.md` and date this file.
- ☐ Differences found. Update the lab page, re-run the affected steps, then record the second run.
- ☐ Blocked by the app itself. Mark **⚠️ Known issue** in the index, note the blocker here, and open a repo issue.
