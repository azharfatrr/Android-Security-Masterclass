# Verification: Lab 04 (Hardcoded Secrets)

Run this checklist on a clean emulator before the lab is marked **✅ Ready** in the labs index. This file is for the proofing run only and is not part of the site navigation.

Note: the lab finds the secret from the app package only. The app stays closed; the emulator just needs to be running and the app installed.

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
| 2 | `adb shell pm path com.hasantuncay.mobsec` | one or more `package:/data/app/...base.apk` lines | ☐ pass ☐ fail: |
| 3 | `adb pull <path> case0004.apk` | `1 file pulled` | ☐ pass ☐ fail: |
| 4 | `unzip -o case0004.apk -d case0004` | `classes.dex` (or `classes*.dex`), `AndroidManifest.xml`, `resources.arsc` present | ☐ pass ☐ fail: |
| 5 | Extraction command from step 4 (`grep -a -h -o -E ...`) then `wc -l` | strings file written, line count is large | ☐ pass ☐ fail: |
| 6 | `grep -i "secret" case0004-strings.txt` | short list containing a capital-letter name and a long value; record the number of lines and any noise | ☐ pass ☐ fail: |
| 7 | Copy the value into notes | full string copied without truncation | ☐ pass ☐ fail: |
| 8 | `grep -a -l "<value>" case0004/classes*.dex` | prints `case0004/classes.dex` (or `classesN.dex`) | ☐ pass ☐ fail: |
| 9 | (repo only) `bash features/maswe0004/poc/adb_verify.sh` from repo root | `[!] CRITICAL VULNERABILITY CONFIRMED (MASWE-0004 / CWE-798)` with matches including the value; also try `... adb_verify.sh case0004.apk` | ☐ pass ☐ fail: |
| 10 | Screenshots 1 and 2 | name and full value readable; value tied to a file inside `case0004/` | ☐ pass ☐ fail: |
| 11 | A colleague follows the page without questions | no missing preconditions, app not needed | ☐ pass ☐ fail: |

## Observations for the lab page

Record anything that differs from the page, including labels, wording, ordering, terminal output, and timing:

- Was `unzip` present in Git Bash, or was the Explorer workaround needed?
- Did the step 4 extraction command run exactly as written (`grep -a -h -o -E`)? Note the `wc -l` number.
- Step 6 output: how many lines, and did noise appear beyond the name and value pair (for example values from other modules such as `SuperSecretKey...`, `FixedSecretKey12`, `maswe0002_secret.key`)?
- Step 8 output shape:
- Step 9 script output: device pull path, printed matches, exit behavior. If the script reported nothing, stop and fix the script before shipping.
- Anything that confused the run:

## Verdict

- ☐ All steps passed on a clean run. Set Lab 04 to **✅ Ready** in `docs/labs/index.md` and date this file.
- ☐ Differences found. Update the lab page, re-run the affected steps, then record the second run.
- ☐ Blocked by the app itself. Mark **⚠️ Known issue** in the index, note the blocker here, and open a repo issue.
