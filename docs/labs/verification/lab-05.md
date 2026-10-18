# Verification: Lab 05 (What the Logs Remember)

Run this checklist on a clean emulator before the lab is marked **✅ Ready** in the labs index. This file is for the proofing run only and is not part of the site navigation.

Note: the log steps need no root or `run-as`. Only step 8 (the file) uses `run-as`, which works on the debug build. The multi-line dump output through `grep -A` is the part most likely to differ between logcat versions; record its exact shape.

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
| 2 | `adb logcat -c` | no output; buffer cleared | ☐ pass ☐ fail: |
| 3 | In app: expand `MASVS-STORAGE`, open `MASWE-0005`, confirm title bar `MASWE-0005 (VULNERABLE)`. Record the subtitle wording | screen opens; subtitle says SECURE and the note covers it | ☐ pass ☐ fail: |
| 4 | Tap `1. Trigger System Console Leak`, then `adb logcat -d -t 400 \| tail -n 80` | one loud multi-line block among emulator noise; note whether the banner is visible within `-t 400` | ☐ pass ☐ fail: |
| 5 | `adb logcat -d -t 400 \| grep -A 25 "CRITICAL APP STATE DUMP"` | the full dump: master key, RSA key prefix, name, TCKN, email, plaintext password. Record the exact lines and whether `-A 25` captures the block whole | ☐ pass ☐ fail: |
| 6 | Record the exact tag (is it `VULN_APP_TAG`?) and the level letter | | ☐ pass ☐ fail: |
| 7 | Tap `2. Trigger Network Leak`, then `adb logcat -d -t 600 \| grep -A 8 "graphql/v2"` | request line plus `Authorization: Bearer eyJ...` and `X-CSRF-Token:` headers; the request itself fails (simulated) and that is expected. Also test the fallback `grep -i okhttp` | ☐ pass ☐ fail: |
| 8 | Tap `3. Trigger Local File Leak`, then `ls -la files` and `adb exec-out run-as com.hasantuncay.mobsec cat files/app_debug.log` | `app_debug.log` exists; line ends with `PAN: ` (16 digits) and `CVV: ` (3 digits). Note how the file grows per tap | ☐ pass ☐ fail: |
| 9 | (repo only) `bash features/maswe0005/poc/adb_verify.sh` from repo root | `[!] CRITICAL VULNERABILITY CONFIRMED (MASWE-0005 / CWE-532):` with the credential line, the bearer line, the SDK line, and the payment line; exit 0. Run once before tapping anything for the empty-state message | ☐ pass ☐ fail: |
| 10 | Screenshots 1 and 2 | dump with password readable; second sink visible | ☐ pass ☐ fail: |
| 11 | A colleague follows the page without questions | no missing preconditions; toast about the attacker app does not confuse | ☐ pass ☐ fail: |

## Observations for the lab page

Record anything that differs from the page, including labels, wording, ordering, terminal output, and timing:

- Step 4: was the block inside the last 400 lines, or did the buffer rotate first?
- Step 5: how did logcat print the multi-line dump? Did continuation lines keep a prefix, and did `grep -A 25` capture the whole block or clip it? Adjust the `-A` count if needed.
- Step 5: exact warning line before the dump (the who-is-watching message): quote it for the page if it adds flavor without spoiling.
- Step 7: exact log tag for the OkHttp lines, and whether the failure line appears when DNS fails on this emulator/network. Note if a resolver timeout delays the output.
- Step 7: are there any extra OkHttp lines (`--> END GET` style) worth mentioning?
- Step 8: file size growth per tap; exact line format (timestamp style).
- The missing attacker app: what toast text appears, and does it repeat per tap? Confirm the lab's "ignore it" note is accurate.
- Result card text after each tap: does any card reveal the tag name (`VULN_APP_TAG`) or the leak contents before the learner searches? Record it.
- Step 9 script: printed lines, exit behavior. If the credential line or the file line is missing after the taps, stop and fix the script before shipping.
- Anything that confused the run:

## Verdict

- ☐ All steps passed on a clean run. Set Lab 05 to **✅ Ready** in `docs/labs/index.md` and date this file.
- ☐ Differences found. Update the lab page, re-run the affected steps, then record the second run.
- ☐ Blocked by the app itself. Mark **⚠️ Known issue** in the index, note the blocker here, and open a repo issue.
