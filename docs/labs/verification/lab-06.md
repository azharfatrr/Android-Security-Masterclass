# Verification: Lab 06 (The Backup That Took Everything)

Run this checklist on a clean emulator before the lab is marked **✅ Ready** in the labs index. This file is for the proofing run only and is not part of the site navigation.

Note: steps 1 through 6 need no root; only `run-as` is used (works on the debug build). Step 7 (`adb backup`) is device-dependent: some images produce a real archive, others answer `Backup disabled`. Record whichever outcome appears; the finding does not depend on it.

## Environment

| Field | Value |
|---|---|
| Date | 2026-10-17 |
| Emulator | ☑ Android Studio AVD (RootAVD34) ☐ Genymotion ☐ other: |
| Image / API level | Android 14 (API 34), Google Play image, Magisk-rooted |
| Host OS | Kali GNU/Linux Rolling |
| Terminal | ☐ Git Bash ☐ zsh ☐ PowerShell ☑ other: bash (Linux) |
| App build | ☑ trainer APK (`app-vulnerable-debug.apk` from release `apk-v2`, built from `main` @ `78dc5ad`) ☐ built from source (`:app-vulnerable:assembleDebug`) |
| Project repository on this machine? | ☑ yes (run step 8) ☐ no (skip step 8) |
| Lab 00 re-run first? | ☑ yes |

## Steps

| # | Action | Expected | Result |
|---|---|---|---|
| 1 | `adb devices` | emulator listed as `device` | ☑ pass — `emulator-5554\tdevice` |
| 2 | `adb shell dumpsys package com.hasantuncay.mobsec \| grep -i ALLOW_BACKUP` | one line containing `ALLOW_BACKUP`. Record the field shape (`flags=[` or `pkgFlags=`) and the API level | ☑ pass — two lines: `flags=[ DEBUGGABLE HAS_CODE ALLOW_CLEAR_USER_DATA ALLOW_BACKUP ]` and a matching `pkgFlags=[ ... ]` line. API 34. Page said "one line"; wording fixed to "one or two lines" |
| 3 | In app: expand `MASVS-STORAGE`, open `MASWE-0006`, confirm title bar `MASWE-0006 (VULNERABLE)`. Record the subtitle wording | screen opens; subtitle says Secure and the note covers it | ☑ pass — dashboard subtitle `MASWE-0006: Secure Implementation`; title bar `MASWE-0006 (VULNERABLE)`. The module lists four vectors; the lab taps three (2, 3, 1) |
| 4 | Tap `2. ADB Local Backup (adb backup)`, then `ls -la files` and `cat files/maswe0006_local_backup_vault.db` | file `maswe0006_local_backup_vault.db` exists; one line with `PAN=` (16 digits) and `CVV=` (3 digits). Record the exact separators | ☑ pass — 47 B; `SQLITE_SIMULATION: PAN=4532112233445566|CVV: 123`. Separators: `=` after `PAN`, pipe between the card number and `CVV: ` |
| 5 | Tap `3. Device-to-Device Migration`, then `cat files/maswe0006_migration_credentials.json` | JSON with `refreshToken` and `masterKey` (starting `0x`). Record the exact shape | ☑ pass — `{"refreshToken":"dGhpcyBpcyBhIHJlZnJlc2ggdG9rZW4gc2FtcGxl","masterKey":"0x8F432B9A1C5E7D8F9A0B1C2D3E4F5A6B"}` |
| 6 | Tap `1. Auto Backup — No Exclusion Rules`, then `ls -la shared_prefs` and `cat shared_prefs/maswe0006_cloud_backup_session.xml` | `maswe0006_cloud_backup_session.xml` with `auth_token` and `user_email` entries. Note how long the async write takes | ☑ pass — file present at 0.5 s and again at 2 s, so the write lands in well under a second. 217 B; `user_email` = `john.doe@personal.domain.com`, `auth_token` = `eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...`. On a fresh install the folder holds only this module's file |
| 7 | `adb backup -f maswe0006_loot.ab -noapk com.hasantuncay.mobsec`, confirm the device dialog | EITHER an archive (`ls -l`, `head -c 24` shows `ANDROID BACKUP`) OR a refusal (`Backup disabled` / empty file). Record the outcome verbatim | ☑ pass — archive case. Dialog text: `A full backup of all data to a connected desktop computer has been requested. Do you want to allow this to happen?` with a password field and `Do not back up` / `Back up my data`; confirmed with no password. Archive `maswe0006_loot.ab`, 1446 B; `head -c 24` printed `ANDROID BACKUP` then `5`, `1`, `none`. `adb backup` also printed `WARNING: adb backup is deprecated and may be removed in a future release` |
| 8 | (repo only) `bash features/maswe0006/poc/adb_verify.sh` from repo root | `[!] CRITICAL VULNERABILITY CONFIRMED (MASWE-0006 / CWE-200):` with flag line, card line, session keys line, records line, prefs note; exit 0. Also run once before tapping for the empty-state message | ☑ pass — empty state (before any tap): exit 1, prints the flag line and `[✓] No MASWE-0006 data artifacts found yet.` After the three taps: exit 0 with four bullets — flag, card data, session keys, prefs note. No records bullet, because the script prints one only when vector 4's file exists and the lab never taps vector 4. Page sentence about "vectors 1, 2, and 4" fixed |
| 9 | Screenshots 1 and 2 (and 3 if an archive appeared) | ALLOW_BACKUP line + file listing; card data + a second file; archive header if present | ☑ pass — shipped as `docs/labs/images/lab-06/terminal-step-1.png`, `backup-dialog.png`, and `terminal-step-6.png` |
| 10 | A colleague follows the page without questions | no missing preconditions | ☑ pass — page followed start to finish; no external colleague was available, so this is a self-review |

## Observations for the lab page

Record anything that differs from the page, including labels, wording, ordering, terminal output, and timing:

- Step 2: `dumpsys` prints both `flags=` and `pkgFlags=` lines with `ALLOW_BACKUP` on this image. The page said "one line"; now says "one or two lines".
- Step 3: the module lists four vectors; the lab taps 2, 3, and 1. A sentence now says so.
- Step 4: exact line `SQLITE_SIMULATION: PAN=4532112233445566|CVV: 123`; the file is plain text as the tip says.
- Step 5: exact JSON shape recorded above.
- Step 6: the preferences write is visible well within a second. `shared_prefs` held only the module file on the fresh install; other labs' artifacts would appear if earlier labs ran without reinstalling, which hint 2 covers.
- Step 7: dialog text recorded above. The archive case worked on this image. The hint 3 `tar` trick lists the app's files (`apps/com.hasantuncay.mobsec/_manifest`, `f/maswe0006_migration_credentials.json`, `f/maswe0006_local_backup_vault.db`, `f/profileInstalled`, `sp/maswe0006_cloud_backup_session.xml`) and exits 2 with a `gzip: stdin: unexpected end of file` warning. The hint now says the nonzero exit is expected.
- Result cards name files the page already names: the cloud card cites `maswe0006_cloud_backup_session.xml` and claims an upload to Google Drive; the ADB card cites `maswe0006_local_backup_vault.db` and shows `adb backup -f backup.ab com.hasantuncay.mobsec`. No card prints a sensitive value, and section B already tells the student to ignore the cards.
- Step 8: the script reads all four module files but prints a bullet only for files that exist. Without the fourth tap there is no records line. The page's step 7 expected text now describes this accurately.
- Anything that confused the run: nothing beyond the wordings fixed above.

## Verdict

- ☑ All steps passed on a clean run. Lab 06 is **✅ Ready** in `docs/labs/index.md` (2026-10-17).
- ☐ Differences found. Update the lab page, re-run the affected steps, then record the second run.
- ☐ Blocked by the app itself. Mark **⚠️ Known issue** in the index, note the blocker here, and open a repo issue.

Run history: the clean run (22:43–22:47) covered every step. The page edits that came out of it (dumpsys line count, vector count, script wording, tar-trick exit note) describe the same captured output; no command changed. Step 7's tar trick and step 8's script were re-read after the edits and behave as recorded.
